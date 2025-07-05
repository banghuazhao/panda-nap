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
    isUserInteractionEnabled = false
    
    run(SKAction.sequence([
      SKAction.playSoundFileNamed("pop.mp3", waitForCompletion: false),
      SKAction.removeFromParent()
      ]))
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

