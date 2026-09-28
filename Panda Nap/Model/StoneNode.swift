//
//  StoneNode.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 7/13/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import SpriteKit

class StoneNode: SKSpriteNode, EventListenerNode, InteractiveNode {
  func didMoveToScene() {
    guard let scene = scene else {
      return
    }
    
    if parent == scene {
      scene.addChild(StoneNode.makeCompoundNode(in: scene))
    }
  }
  
  func interact() {
    guard let game = scene as? GameScene, game.playable, isUserInteractionEnabled else { return }
    isUserInteractionEnabled = false
    let center = children.isEmpty ? CGPoint.zero : CGPoint(
      x: children.map(\.position.x).reduce(0, +) / CGFloat(children.count),
      y: children.map(\.position.y).reduce(0, +) / CGFloat(children.count))
    game.blockRemoved(at: convert(center, to: game), stone: true)
    physicsBody = nil
    SKTAudio.sharedInstance().playSoundEffect("pop.mp3")
    let vanish = SKAction.group([.scale(to: 0.72, duration: 0.2), .fadeOut(withDuration: 0.2)])
    vanish.timingMode = .easeIn
    run(.sequence([vanish, .removeFromParent()]))
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    interact()
  }
  
  static func makeCompoundNode(in scene: SKScene) -> SKNode {
    let compound = StoneNode()
    
    for stone in scene.children
      .filter({ node in node is StoneNode}) {
        stone.removeFromParent()
        compound.addChild(stone)
    }
    
    let bodies = compound.children.map { node in
      SKPhysicsBody(rectangleOf: node.frame.size, center: node.position)
    }
    
    compound.physicsBody = SKPhysicsBody(bodies: bodies)
    compound.physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Panda | PhysicsCategory.Block
    compound.physicsBody!.categoryBitMask = PhysicsCategory.Block
    compound.isUserInteractionEnabled = true
    compound.zPosition = 1
    
    return compound
  }
}
