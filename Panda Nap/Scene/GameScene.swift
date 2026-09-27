import SpriteKit
import UIKit
#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
#endif

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Panda: UInt32 = 0b1
    static let Block: UInt32 = 0b10
    static let Bed: UInt32 = 0b100
    static let Edge: UInt32 = 0b1000
}

protocol EventListenerNode {
    func didMoveToScene()
}

protocol InteractiveNode {
    func interact()
}

private var consecutiveLosses = 0

class GameScene: SKScene {
    #if !targetEnvironment(macCatalyst)
    private var interstitialAd: InterstitialAd?
    #endif

    private let hud = SKNode()
    private var levelsButton: SKShapeNode?
    private var retryButton: SKShapeNode?
    private var levelBadge: SKShapeNode?
    private var hintNode: SKShapeNode?
    private var pointScale: CGFloat = 1

    var bedNode: BedNode!
    var pandaNode: PandaNode!
    var playable = true
    var currentLevel = 0

    override func didMove(to view: SKView) {
        let maxAspectRatio: CGFloat = 2.2
        let maxAspectRatioHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - maxAspectRatioHeight) / 2
        let playableRect = CGRect(x: size.width * 0.2, y: playableMargin,
                                  width: size.width * 0.6,
                                  height: size.height - playableMargin * 2)

        physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        physicsBody?.categoryBitMask = PhysicsCategory.Edge
        physicsWorld.contactDelegate = self

        enumerateChildNodes(withName: "//*", using: { node, _ in
            (node as? EventListenerNode)?.didMoveToScene()
        })

        guard let bed = childNode(withName: "bed") as? BedNode,
              let panda = childNode(withName: "panda") as? PandaNode else {
            playable = false
            assertionFailure("Level scene is missing its bed or panda node")
            return
        }
        bedNode = bed
        pandaNode = panda

        SKTAudio.sharedInstance().playBackgroundMusic("background.mp3")
        hud.zPosition = 130
        addChild(hud)
        installHUD()
        layoutHUD()

        #if !targetEnvironment(macCatalyst)
        if consecutiveLosses == 1 {
            InterstitialAd.load(with: Constants.interstitialAdID, request: Request()) { [weak self] ad, error in
                if let error { print("Failed to load interstitial: \(error.localizedDescription)") }
                self?.interstitialAd = ad
                ad?.fullScreenContentDelegate = self
            }
        }
        #endif
    }

    private func installHUD() {
        levelsButton = pill("Levels".localized(), name: "levels", width: 108, height: 48,
                            fill: SKColor(red: 0.30, green: 0.61, blue: 0.17, alpha: 0.97))
        retryButton = pill("Retry".localized(), name: "retry", width: 100, height: 48,
                           fill: SKColor(red: 0.11, green: 0.31, blue: 0.21, alpha: 0.94))
        levelBadge = pill(String(format: "Level %d".localized(), currentLevel), name: "levelBadge",
                          width: 108, height: 35,
                          fill: SKColor(red: 0.10, green: 0.25, blue: 0.16, alpha: 0.88))
        [levelsButton, retryButton, levelBadge].compactMap { $0 }.forEach(hud.addChild)

        if currentLevel == 1 {
            hintNode = pill("Tap blocks to guide the panda".localized(), name: "hint",
                            width: 260, height: 38,
                            fill: SKColor(red: 0.09, green: 0.24, blue: 0.15, alpha: 0.88))
            if let hintNode {
                hud.addChild(hintNode)
                hintNode.run(.sequence([.wait(forDuration: 4), .fadeOut(withDuration: 0.3), .removeFromParent()]))
            }
        }
    }

    private func pill(_ title: String, name: String, width: CGFloat, height: CGFloat,
                      fill: SKColor) -> SKShapeNode {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        node.name = name
        node.fillColor = fill
        node.strokeColor = SKColor(red: 0.72, green: 0.88, blue: 0.48, alpha: 0.92)
        node.lineWidth = 2

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = title
        label.fontSize = name == "hint" ? 14 : (name == "levelBadge" ? 16 : 18)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        node.addChild(label)
        return node
    }

    /// Position controls in view points, then convert into SpriteKit coordinates.
    func layoutHUD() {
        guard let view, let levelsButton, let retryButton, let levelBadge else { return }
        let origin = convertPoint(fromView: .zero)
        pointScale = abs(convertPoint(fromView: CGPoint(x: 1, y: 0)).x - origin.x)
        let safe = view.safeAreaInsets
        let top = convertPoint(fromView: CGPoint(x: 0, y: safe.top + 34)).y
        let left = convertPoint(fromView: CGPoint(x: safe.left + 16, y: 0)).x
        let right = convertPoint(fromView: CGPoint(x: view.bounds.width - safe.right - 16, y: 0)).x

        levelsButton.setScale(pointScale)
        levelsButton.position = CGPoint(x: left + 54 * pointScale, y: top)
        retryButton.setScale(pointScale)
        retryButton.position = CGPoint(x: right - 50 * pointScale, y: top)
        levelBadge.setScale(pointScale)
        levelBadge.position = CGPoint(x: levelsButton.position.x, y: top - 54 * pointScale)

        if let hintNode, hintNode.parent != nil {
            hintNode.setScale(pointScale)
            let bottom = convertPoint(fromView: CGPoint(x: 0, y: view.bounds.height - safe.bottom - 34)).y
            hintNode.position = CGPoint(x: left + 130 * pointScale, y: bottom)
        }
    }

    override func didSimulatePhysics() {
        if playable && abs(pandaNode.zRotation) > CGFloat(45).degreesToRadians() {
            lose()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        if levelsButton?.calculateAccumulatedFrame().contains(location) == true {
            lightHaptic()
            consecutiveLosses = 0
            if let menu = SKScene(fileNamed: "MenuScene") as? MenuScene {
                menu.scaleMode = .aspectFill
                view?.presentScene(menu, transition: .fade(withDuration: 0.25))
            }
        } else if retryButton?.calculateAccumulatedFrame().contains(location) == true {
            lightHaptic()
            newGame()
        }
    }

    func blockRemoved(at point: CGPoint, stone: Bool) {
        guard playable else { return }
        hintNode?.removeAllActions()
        hintNode?.run(.sequence([.fadeOut(withDuration: 0.12), .removeFromParent()]))
        hintNode = nil
        burst(at: point, color: stone ? .lightGray : SKColor(red: 0.58, green: 0.35, blue: 0.16, alpha: 1),
              count: stone ? 10 : 7, distance: 46)
        lightHaptic()
    }

    private func burst(at point: CGPoint, color: SKColor, count: Int, distance: CGFloat) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        for index in 0..<count {
            let fragment = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5) * pointScale)
            fragment.fillColor = color
            fragment.strokeColor = .clear
            fragment.position = point
            fragment.zPosition = 115
            addChild(fragment)

            let angle = CGFloat(index) * (.pi * 2 / CGFloat(count)) + CGFloat.random(in: -0.25...0.25)
            let travel = CGFloat.random(in: 0.5...1) * distance * pointScale
            let move = SKAction.moveBy(x: cos(angle) * travel, y: sin(angle) * travel, duration: 0.34)
            move.timingMode = .easeOut
            fragment.run(.sequence([.group([move, .fadeOut(withDuration: 0.34),
                                            .scale(to: 0.2, duration: 0.34)]), .removeFromParent()]))
        }
    }

    private func lightHaptic() {
        #if !targetEnvironment(macCatalyst)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func resultHaptic(success: Bool) {
        #if !targetEnvironment(macCatalyst)
        UINotificationFeedbackGenerator().notificationOccurred(success ? .success : .error)
        #endif
    }

    private func showResult(_ title: String, detail: String) {
        let message = MessageNode(message: title, detail: detail, pointScale: pointScale)
        message.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(message)
        message.appear(reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }

    func newGame() {
        if let nextScene = GameScene.level(levelNum: currentLevel) {
            view?.presentScene(nextScene, transition: .fade(withDuration: 0.25))
        }
    }

    func lose() {
        guard playable else { return }
        playable = false
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        SKTAudio.sharedInstance().playSoundEffect("lose.mp3")
        pandaNode.scare()
        burst(at: pandaNode.position, color: SKColor(red: 0.91, green: 0.57, blue: 0.25, alpha: 1),
              count: 12, distance: 65)
        resultHaptic(success: false)
        showResult("Try again...".localized(), detail: "Retrying level".localized())

        consecutiveLosses += 1
        if consecutiveLosses < 2 {
            run(SKAction.afterDelay(2.6, runBlock: newGame))
        } else {
            consecutiveLosses = 0
            #if !targetEnvironment(macCatalyst)
            run(SKAction.afterDelay(2.3, runBlock: { [weak self] in
                guard let self else { return }
                if let ad = self.interstitialAd,
                   let controller = self.view?.window?.rootViewController {
                    ad.present(from: controller)
                } else {
                    self.newGame()
                }
            }))
            #else
            run(SKAction.afterDelay(2.6, runBlock: newGame))
            #endif
        }
    }

    func win() {
        guard playable else { return }
        playable = false
        consecutiveLosses = 0
        currentLevel = currentLevel < Constants.totalLevel ? currentLevel + 1 : 1
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        SKTAudio.sharedInstance().playSoundEffect("victory.mp3")
        pandaNode.nap(scenePoint: bedNode.position)
        burst(at: bedNode.position, color: SKColor(red: 0.94, green: 0.78, blue: 0.27, alpha: 1),
              count: 24, distance: 105)
        resultHaptic(success: true)
        showResult("Nice job!".localized(), detail: "Next level coming up".localized())
        run(SKAction.afterDelay(3, runBlock: newGame))
    }

    class func level(levelNum: Int) -> GameScene? {
        guard let scene = GameScene(fileNamed: "Level\(levelNum)") else { return nil }
        scene.currentLevel = levelNum
        if levelNum > bestLevel {
            bestLevel = levelNum
            UserDefaults.standard.set(bestLevel, forKey: Constants.UserDefaultsKeys.BEST_LEVEL)
        }
        scene.scaleMode = .aspectFill
        return scene
    }
}

#if !targetEnvironment(macCatalyst)
extension GameScene: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialAd = nil
        newGame()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitialAd = nil
        newGame()
    }
}
#endif

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        guard playable else { return }
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == (PhysicsCategory.Panda | PhysicsCategory.Bed) {
            win()
        } else if collision == (PhysicsCategory.Panda | PhysicsCategory.Edge) {
            lose()
        }
    }
}
