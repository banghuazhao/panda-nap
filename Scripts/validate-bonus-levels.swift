// Native macOS physics validation; does not open an app or simulator.
// Run from the repository root:
// swiftc -parse-as-library Scripts/validate-bonus-levels.swift -o /tmp/panda-bonus-check -framework SpriteKit -framework Metal
// /tmp/panda-bonus-check
// The standalone executable intentionally uses decoded base nodes without
// textures or game classes; runtime bodies and removal behavior are installed
// below. Missing image/custom-class archive warnings do not affect physics.
import Foundation
import Metal
import SpriteKit

private struct Manifest: Decodable {
    let seconds_after_last_removal_to_check: Double
    let levels: [String: Puzzle]
}

private struct Puzzle: Decodable {
    struct AuthoredNode: Decodable {
        let name: String
        let template: String
    }
    struct Removal: Decodable {
        let at_seconds: Double
        let node: String
    }
    let nodes: [AuthoredNode]
    let removals: [Removal]
}

private enum Category {
    static let panda: UInt32 = 1
    static let block: UInt32 = 2
    static let bed: UInt32 = 4
    static let edge: UInt32 = 8
}

private final class ContactRecorder: NSObject, SKPhysicsContactDelegate {
    var result: String?
    var simulationTime = 0.0
    var resultTime = 0.0

    func didBegin(_ contact: SKPhysicsContact) {
        guard result == nil else { return }
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == Category.panda | Category.bed {
            result = "won"
        } else if collision == Category.panda | Category.edge {
            result = "lost: edge contact"
        }
        if result != nil { resultTime = simulationTime }
    }
}

private struct ValidationError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

private func loadScene(_ path: String) throws -> SKScene {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    let archive = try NSKeyedUnarchiver(forReadingFrom: data)
    archive.requiresSecureCoding = false
    defer { archive.finishDecoding() }
    guard let scene = archive.decodeObject(forKey: "root") as? SKScene else {
        throw ValidationError("\(path): archive root is not an SKScene")
    }
    return scene
}

private func validate(level: Int, puzzle: Puzzle, device: MTLDevice,
                      settlingSeconds: Double, step: Double) throws {
    let scene = try loadScene("Panda Nap/Scene/Level\(level).sks")
    scene.isPaused = false
    scene.scaleMode = .aspectFill
    guard let panda = scene.childNode(withName: "panda") as? SKSpriteNode,
          let bed = scene.childNode(withName: "bed") as? SKSpriteNode else {
        throw ValidationError("Level \(level): panda or bed is missing")
    }

    // These replacements match GameScene, PandaNode and BedNode at runtime.
    let margin = (scene.size.height - scene.size.width / 2.2) / 2
    let playableRect = CGRect(x: scene.size.width * 0.2, y: margin,
                              width: scene.size.width * 0.6,
                              height: scene.size.height - margin * 2)
    scene.physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
    scene.physicsBody?.categoryBitMask = Category.edge
    panda.physicsBody = SKPhysicsBody(
        rectangleOf: CGSize(width: panda.size.width * 0.6, height: panda.size.height * 0.8),
        center: CGPoint(x: 30, y: -24))
    panda.physicsBody?.categoryBitMask = Category.panda
    panda.physicsBody?.collisionBitMask = Category.block | Category.edge
    panda.physicsBody?.contactTestBitMask = Category.bed | Category.edge
    bed.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 30))
    bed.physicsBody?.isDynamic = false
    bed.physicsBody?.categoryBitMask = Category.bed
    bed.physicsBody?.collisionBitMask = 0

    // Keep authored wood bodies unchanged. Existing StoneNode gathers all
    // authored stone sprites into one compound with these exact frame shapes.
    let stones = puzzle.nodes.filter { $0.template.hasPrefix("stone_") }
    var stoneCompound: SKSpriteNode?
    if !stones.isEmpty {
        let compound = SKSpriteNode()
        compound.name = "validation_stone_compound"
        for authored in stones {
            guard let stone = scene.childNode(withName: authored.name) else {
                throw ValidationError("Level \(level): missing stone \(authored.name)")
            }
            stone.removeFromParent()
            compound.addChild(stone)
        }
        compound.physicsBody = SKPhysicsBody(bodies: compound.children.map {
            SKPhysicsBody(rectangleOf: $0.frame.size, center: $0.position)
        })
        compound.physicsBody?.collisionBitMask = Category.edge | Category.panda | Category.block
        compound.physicsBody?.categoryBitMask = Category.block
        scene.addChild(compound)
        stoneCompound = compound
    }

    let contacts = ContactRecorder()
    scene.physicsWorld.contactDelegate = contacts
    let renderer = SKRenderer(device: device)
    renderer.scene = scene
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm, width: 64, height: 48, mipmapped: false)
    textureDescriptor.usage = .renderTarget
    guard let renderTarget = device.makeTexture(descriptor: textureDescriptor),
          let commandQueue = device.makeCommandQueue() else {
        throw ValidationError("Unable to make offscreen Metal render target")
    }
    let renderPass = MTLRenderPassDescriptor()
    renderPass.colorAttachments[0].texture = renderTarget
    renderPass.colorAttachments[0].loadAction = .clear
    renderPass.colorAttachments[0].storeAction = .dontCare
    let initialPosition = panda.position
    let tracing = CommandLine.arguments.contains("--trace")
    if tracing {
        print("Level \(level) gravity \(scene.physicsWorld.gravity), speed \(scene.physicsWorld.speed), scene speed \(scene.speed)")
        for child in scene.children {
            print("node \(child.name ?? "nil") size \((child as? SKSpriteNode)?.size ?? .zero), scale \(child.xScale),\(child.yScale), position \(child.position), paused \(child.isPaused), dynamic \(child.physicsBody?.isDynamic ?? false), masks \(child.physicsBody?.categoryBitMask ?? 0)/\(child.physicsBody?.collisionBitMask ?? 0)")
        }
    }
    let removals = puzzle.removals.sorted { $0.at_seconds < $1.at_seconds }
    var nextRemoval = 0
    let duration = (removals.last?.at_seconds ?? 0) + settlingSeconds
    let clockStart = ProcessInfo.processInfo.systemUptime
    var maximumRotation: CGFloat = 0
    var maximumDisplacement: CGFloat = 0
    for frame in 0...Int(ceil(duration / step)) {
        let time = Double(frame) * step
        contacts.simulationTime = time
        while nextRemoval < removals.count && removals[nextRemoval].at_seconds <= time + 0.000001 {
            let removal = removals[nextRemoval]
            guard let node = scene.childNode(withName: "//\(removal.node)") else {
                throw ValidationError("Level \(level): removal target \(removal.node) is missing")
            }
            let target: SKNode
            if let compound = stoneCompound, node.parent === compound {
                target = compound
            } else {
                target = node
            }
            if tracing { print("remove \(removal.node) at \(time), actual \(node.position), body \(target.physicsBody != nil)") }
            target.physicsBody = nil
            if target === stoneCompound {
                target.run(.sequence([
                    .group([.scale(to: 0.72, duration: 0.2), .fadeOut(withDuration: 0.2)]),
                    .removeFromParent()
                ]))
            } else {
                target.run(.sequence([
                    .group([.scale(to: 1.12, duration: 0.08), .fadeAlpha(to: 0.8, duration: 0.08)]),
                    .group([.scale(to: 0.15, duration: 0.18), .fadeOut(withDuration: 0.18)]),
                    .removeFromParent()
                ]))
            }
            nextRemoval += 1
        }
        renderer.update(atTime: clockStart + time)
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw ValidationError("Unable to make Metal command buffer")
        }
        renderer.render(withViewport: CGRect(x: 0, y: 0, width: 64, height: 48),
                        commandBuffer: commandBuffer, renderPassDescriptor: renderPass)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        if let error = commandBuffer.error {
            throw ValidationError("Offscreen Metal rendering failed: \(error.localizedDescription)")
        }
        if tracing && frame % Int(0.5 / step) == 0 {
            print("time \(String(format: "%.2f", time)) panda \(panda.position), velocity \(panda.physicsBody?.velocity ?? .zero), resting \(panda.physicsBody?.isResting ?? false), nodes \(scene.children.count)")
        }
        maximumRotation = max(maximumRotation, abs(panda.zRotation))
        maximumDisplacement = max(maximumDisplacement,
                                  hypot(panda.position.x - initialPosition.x,
                                        panda.position.y - initialPosition.y))
        if contacts.result == nil && abs(panda.zRotation) > .pi / 4 {
            contacts.result = "lost: panda tilted more than 45 degrees"
            contacts.resultTime = time
        }
        if contacts.result != nil { break }
    }
    guard maximumDisplacement > 10 else {
        throw ValidationError("Level \(level): physics did not advance (maximum movement \(maximumDisplacement))")
    }
    let summary = "Level \(level), \(Int((1 / step).rounded())) Hz: \(contacts.result ?? "no result")"
        + " at \(String(format: "%.2f", contacts.resultTime)) s;"
        + " panda \(panda.position), max tilt \(String(format: "%.2f", maximumRotation * 180 / .pi))°"
    print(summary)
    guard contacts.result == "won" else { throw ValidationError(summary) }
    guard nextRemoval == removals.count else {
        throw ValidationError("Level \(level): won before all solution removals were exercised")
    }
    renderer.scene = nil
}

@main
private struct BonusLevelChecks {
    static func main() throws {
        setbuf(stdout, nil)
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw ValidationError("Metal is unavailable. Run this validation with access to the native GPU.")
        }
        let manifest = try JSONDecoder().decode(
            Manifest.self,
            from: Data(contentsOf: URL(fileURLWithPath: "tools/bonus_level_solutions.json")))
        for step in [1.0 / 60, 1.0 / 120] {
            for level in [14, 15, 16] {
                guard let puzzle = manifest.levels[String(level)] else {
                    throw ValidationError("Level \(level) has no solution manifest")
                }
                try validate(level: level, puzzle: puzzle, device: device,
                             settlingSeconds: manifest.seconds_after_last_removal_to_check,
                             step: step)
            }
        }
        print("Passed actual SpriteKit physics for all three bonus solutions at 60 and 120 Hz.")
    }
}
