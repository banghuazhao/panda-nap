//
//  PandaNode.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/21/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import SpriteKit
import UIKit

class PandaNode: SKSpriteNode, EventListenerNode {
    func didMoveToScene() {
        print("panda added to scene")
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 0.6, height: size.height * 0.8), center: CGPoint(x: 30, y: -24))
        physicsBody!.categoryBitMask = PhysicsCategory.Panda
        physicsBody!.collisionBitMask = PhysicsCategory.Block | PhysicsCategory.Edge
        physicsBody!.contactTestBitMask = PhysicsCategory.Bed | PhysicsCategory.Edge
    }

    func scare() {
        // 1
        for child in children {
            child.removeFromParent()
        }
        texture = nil
        color = SKColor.clear
        // 2
        let pandaScare = SKSpriteNode(imageNamed: "panda_scare")
        // 3
        pandaScare.move(toParent: self)
        pandaScare.position = CGPoint(x: 0, y: 0)
    }

    func nap(scenePoint: CGPoint) {
        physicsBody = nil
        for child in children {
            child.removeFromParent()
        }
        texture = nil
        color = SKColor.clear
        let pandaNap = SKSpriteNode(imageNamed: "panda_sleep")
        pandaNap.move(toParent: self)
        pandaNap.position = CGPoint(x: 0, y: 0)

        var napPosition = scenePoint
        napPosition.y += 80
        let move = SKAction.move(to: napPosition, duration: 0.66)
        move.timingMode = .easeOut
        let rotate = SKAction.rotate(toAngle: 0, duration: 0.5)
        rotate.timingMode = .easeOut
        if GameSettings.reduceMotionEnabled {
            run(.group([move, rotate]))
        } else {
            let squash = SKAction.group([.scaleX(to: 1.08, duration: 0.12),
                                         .scaleY(to: 0.91, duration: 0.12)])
            let settle = SKAction.sequence([squash,
                                            .scale(to: 1, duration: 0.2)])
            settle.timingMode = .easeOut
            run(.sequence([.group([move, rotate]), settle]))
        }
    }
}
