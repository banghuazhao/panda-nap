//
//  MessageNode.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/21/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import SpriteKit
class MessageNode: SKLabelNode {
    convenience init(message: String) {
        self.init(fontNamed: "AvenirNext-Regular")
        text = message
        fontSize = 256.0
        fontColor = SKColor.gray
        zPosition = 100
        let front = SKLabelNode(fontNamed: "AvenirNext-Regular")
        front.text = message
        front.fontSize = 256.0
        front.fontColor = SKColor.white
        front.position = CGPoint(x: -2, y: -2)
        addChild(front)

        physicsBody = SKPhysicsBody(circleOfRadius: 10)
        physicsBody!.collisionBitMask = PhysicsCategory.Edge
        physicsBody!.categoryBitMask = PhysicsCategory.Label
        physicsBody!.restitution = 0.7
    }
}
