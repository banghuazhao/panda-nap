//
//  BlockNode.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/21/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import SpriteKit
class BlockNode: SKSpriteNode, EventListenerNode,
    InteractiveNode {
    func didMoveToScene() {
        isUserInteractionEnabled = true
        zPosition = 2
    }

    func interact() {
        isUserInteractionEnabled = false
        run(SKAction.sequence([
            SKAction.playSoundFileNamed("pop.mp3", waitForCompletion: false),
            SKAction.scale(to: 0.8, duration: 0.1),
            SKAction.removeFromParent(),
        ]))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        print("destroy block")
        interact()
        physicsBody!.categoryBitMask = PhysicsCategory.Block
        physicsBody!.collisionBitMask = PhysicsCategory.Panda | PhysicsCategory.Block | PhysicsCategory.Edge
    }
}
