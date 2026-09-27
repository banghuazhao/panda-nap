//
//  MenuScene.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/26/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import GameplayKit
import SpriteKit
import UIKit

class MenuScene: SKScene {
    let moveableNode = SKNode()
    private var levelPoints = [CGPoint]()
    private var panGesture: UIPanGestureRecognizer?
    private var touchStartLocation: CGPoint?

    override func didMove(to view: SKView) {
        SKTAudio.sharedInstance().playBackgroundMusic("oboarding.mp3")

        print("MenuScene")

        addChild(moveableNode)

        let hint = SKLabelNode(fontNamed: "Helvetica-Bold")
        hint.text = "Swipe to explore levels".localized()
        hint.fontSize = 24
        hint.fontColor = .white
        hint.position = CGPoint(x: frame.midX, y: frame.maxY - 44)
        hint.zPosition = 100
        addChild(hint)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)
        panGesture = pan

        let levelTree = SKSpriteNode(imageNamed: "level_tree")
        levelTree.anchorPoint = CGPoint(x: 0.5, y: 0)
        levelTree.zPosition = 2
        levelTree.position = CGPoint(x: 0, y: -size.height * 2.0)
        moveableNode.addChild(levelTree)

        var levelNodePoints = [CGPoint]()

        for i in 1 ... Constants.totalLevel {
            let x: CGFloat = i % 2 == 1 ? 200 : -160
            let y: CGFloat = -size.height * 2.0 + CGFloat(1100 + i * 200)
            levelNodePoints.append(CGPoint(x: x, y: y))
        }

        // previous level
        if bestLevel > 1 {
            for i in 1 ... bestLevel - 1 {
                let level = SKSpriteNode(imageNamed: "fruit_orange")
                level.position = levelNodePoints[i - 1]
                if i % 2 == 0 {
                    level.xScale = level.xScale * -1
                }
                level.name = "level_\(i)"
                moveableNode.addChild(level)
                let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
                labelNode.text = "\(i)"
                labelNode.fontColor = SKColor.white
                if i % 2 == 0 {
                    labelNode.xScale = labelNode.xScale * -1
                }
                labelNode.fontSize = 80
                labelNode.position = CGPoint(x: 30, y: -30)
                level.addChild(labelNode)
            }
        }

        // current level
        let levelCurrent = SKSpriteNode(imageNamed: "fruit_yellow")
        levelCurrent.position = levelNodePoints[bestLevel - 1]
        if bestLevel % 2 == 0 {
            levelCurrent.xScale = levelCurrent.xScale * -1
            if !UIAccessibility.isReduceMotionEnabled { levelCurrent.run(
                SKAction.repeatForever(
                    SKAction.sequence(
                        [SKAction.group(
                            [SKAction.scaleY(to: 1.05, duration: 0.5),
                             SKAction.scaleX(to: -1.05, duration: 0.5)]),
                        SKAction.group(
                            [SKAction.scaleY(to: 0.95, duration: 0.5),
                             SKAction.scaleX(to: -0.95, duration: 0.5)])]
                    )
                )
            ) }
        } else {
            if !UIAccessibility.isReduceMotionEnabled { levelCurrent.run(
                SKAction.repeatForever(
                    SKAction.sequence(
                        [SKAction.scale(to: 1.05, duration: 0.5),
                         SKAction.scale(to: 0.95, duration: 0.5)])
                )
            ) }
        }

        levelCurrent.name = "level_\(bestLevel)"
        moveableNode.addChild(levelCurrent)
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.text = "\(bestLevel)"
        labelNode.fontColor = SKColor.white
        labelNode.fontSize = 80
        if bestLevel % 2 == 0 {
            labelNode.xScale = labelNode.xScale * -1
        }
        labelNode.position = CGPoint(x: 30, y: -30)
        levelCurrent.addChild(labelNode)

        // new levels
        if bestLevel < Constants.totalLevel {
            for i in bestLevel + 1 ... Constants.totalLevel {
                let level = SKSpriteNode(imageNamed: "fruit_green")
                level.position = levelNodePoints[i - 1]
                if i % 2 == 0 {
                    level.xScale = level.xScale * -1
                }
                level.name = "level_\(i)"
                level.alpha = 0.55
                moveableNode.addChild(level)
                let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
                labelNode.text = "\(i)"
                labelNode.fontColor = SKColor.white
                labelNode.fontSize = 80
                if i % 2 == 0 {
                    labelNode.xScale = labelNode.xScale * -1
                }
                labelNode.position = CGPoint(x: 30, y: -30)
                level.addChild(labelNode)
            }
        }

        levelPoints = levelNodePoints
        moveableNode.position.y = frame.midY - levelNodePoints[bestLevel - 1].y
    }

    override func willMove(from view: SKView) {
        if let panGesture { view.removeGestureRecognizer(panGesture) }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !levelPoints.isEmpty, let view = self.view else { return }
        let translation = gesture.translation(in: view)
        let scale = size.height / view.bounds.height
        let minY = frame.midY - levelPoints[Constants.totalLevel - 1].y
        let maxY = frame.midY - levelPoints[0].y
        moveableNode.position.y = min(max(moveableNode.position.y + translation.y * scale, minY), maxY)
        gesture.setTranslation(.zero, in: view)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartLocation = touches.first?.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        defer { touchStartLocation = nil }
        guard let start = touchStartLocation,
              hypot(touchLocation.x - start.x, touchLocation.y - start.y) < 20 else { return }
        let nodesAtPoint = nodes(at: touchLocation)

        for node in nodesAtPoint {
            if let nodeName = node.name, nodeName.contains("level") {
                guard let level = Int(nodeName.split(separator: "_")[1]), level <= bestLevel else { return }
                if let scene = GameScene.level(levelNum: level) {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    // Present the scene
                    view?.presentScene(scene, transition: .doorway(withDuration: 1.0))
                }
            }
        }
    }
}
