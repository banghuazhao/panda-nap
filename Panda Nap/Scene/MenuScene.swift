//
//  MenuScene.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/26/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import GameplayKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif
import Localize_Swift
import SpriteKit

import SwiftySKScrollView

class MenuScene: SKScene {
    var scrollView: SwiftySKScrollView!
    let moveableNode = SKNode()

    override func didMove(to view: SKView) {
        SKTAudio.sharedInstance().playBackgroundMusic("oboarding.mp3")

        print("MenuScene")

        addChild(moveableNode)

        scrollView = SwiftySKScrollView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height), moveableNode: moveableNode, direction: .vertical)
        scrollView.contentSize = CGSize(width: scrollView!.frame.width, height: scrollView!.frame.height * 2.0) // makes it 3 times the height
        view.addSubview(scrollView)

        let levelTree = SKSpriteNode(imageNamed: "level_tree")
        levelTree.anchorPoint = CGPoint(x: 0.5, y: 0)
        levelTree.zPosition = 2
        levelTree.position = CGPoint(x: 0, y: -scrollView!.frame.height * 2.0)
        moveableNode.addChild(levelTree)

        var levelNodePoints = [CGPoint]()

        for i in 1 ... Constants.totalLevel {
            let x: CGFloat = i % 2 == 1 ? 200 : -160
            let y: CGFloat = -scrollView!.frame.height * 2.0 + CGFloat(1100 + i * 200)
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
            levelCurrent.run(
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
            )
        } else {
            levelCurrent.run(
                SKAction.repeatForever(
                    SKAction.sequence(
                        [SKAction.scale(to: 1.05, duration: 0.5),
                         SKAction.scale(to: 0.95, duration: 0.5)])
                )
            )
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

        scrollView.contentOffset.y = scrollView!.frame.height * 1.0 - CGFloat((bestLevel - 1) * 200) + 200

        print("scrollView.contentOffset.y: \(scrollView.contentOffset.y)")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let nodesAtPoint = nodes(at: touchLocation)

        for node in nodesAtPoint {
            if let nodeName = node.name, nodeName.contains("level") {
                guard let level = Int(nodeName.split(separator: "_")[1]), level <= bestLevel else { return }
                if let scene = GameScene.level(levelNum: level) {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    // Present the scene
                    scrollView.removeFromSuperview()
                    scrollView = nil // nil out reference to deallocate properly
                    view?.presentScene(scene, transition: .doorway(withDuration: 1.0))
                }
            }
        }
    }
}
