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
        guard let game = scene as? GameScene, game.acceptsGameplayInput, isUserInteractionEnabled else { return }
        isUserInteractionEnabled = false
        game.blockRemoved(at: convert(.zero, to: game), stone: false)
        physicsBody = nil
        SKTAudio.sharedInstance().playSoundEffect("pop.mp3")
        let pop = SKAction.group([.scale(to: 1.12, duration: 0.08), .fadeAlpha(to: 0.8, duration: 0.08)])
        pop.timingMode = .easeOut
        let vanish = SKAction.group([.scale(to: 0.15, duration: 0.18), .fadeOut(withDuration: 0.18)])
        vanish.timingMode = .easeIn
        run(.sequence([pop, vanish, .removeFromParent()]))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        interact()
    }
}
