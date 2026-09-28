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
    private let hint = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let hintBackdrop = SKShapeNode(rectOf: CGSize(width: 300, height: 42), cornerRadius: 21)
    private var moreAppsButton: SKShapeNode?
    private var settingsButton: SKShapeNode?

    override func didMove(to view: SKView) {
        SKTAudio.sharedInstance().playBackgroundMusic("oboarding.mp3")

        addChild(moveableNode)

        hintBackdrop.fillColor = SKColor(red: 0.10, green: 0.25, blue: 0.16, alpha: 0.91)
        hintBackdrop.strokeColor = SKColor(red: 0.72, green: 0.88, blue: 0.48, alpha: 0.92)
        hintBackdrop.lineWidth = 2
        hintBackdrop.zPosition = 99
        addChild(hintBackdrop)
        hint.text = "Swipe to explore levels".localized()
        hint.fontSize = 16
        hint.fontColor = .white
        hint.verticalAlignmentMode = .center
        hint.zPosition = 100
        addChild(hint)

        let button = SKShapeNode(rectOf: CGSize(width: 112, height: 44), cornerRadius: 22)
        button.fillColor = SKColor(red: 0.10, green: 0.31, blue: 0.19, alpha: 0.95)
        button.strokeColor = SKColor(red: 0.72, green: 0.88, blue: 0.48, alpha: 1)
        button.lineWidth = 2
        button.zPosition = 101
        let buttonLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        buttonLabel.text = "More Apps".localized()
        buttonLabel.fontSize = 15
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        button.addChild(buttonLabel)
        addChild(button)
        moreAppsButton = button

        let settings = SKShapeNode(rectOf: CGSize(width: 112, height: 44), cornerRadius: 22)
        settings.fillColor = SKColor(red: 0.10, green: 0.31, blue: 0.19, alpha: 0.95)
        settings.strokeColor = SKColor(red: 0.72, green: 0.88, blue: 0.48, alpha: 1)
        settings.lineWidth = 2
        settings.zPosition = 101
        let settingsLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        settingsLabel.text = "Settings".localized()
        settingsLabel.fontSize = 15
        settingsLabel.fontColor = .white
        settingsLabel.verticalAlignmentMode = .center
        settings.addChild(settingsLabel)
        addChild(settings)
        settingsButton = settings
        layoutUI()

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

    func layoutUI() {
        guard let view, let moreAppsButton, let settingsButton else { return }
        let origin = convertPoint(fromView: .zero)
        let pointScale = abs(convertPoint(fromView: CGPoint(x: 1, y: 0)).x - origin.x)
        let safe = view.safeAreaInsets
        let top = convertPoint(fromView: CGPoint(x: 0, y: safe.top + 31)).y
        let left = convertPoint(fromView: CGPoint(x: safe.left + 16, y: 0)).x
        let right = convertPoint(fromView: CGPoint(x: view.bounds.width - safe.right - 16, y: 0)).x
        let bottom = convertPoint(fromView: CGPoint(x: 0, y: view.bounds.height - safe.bottom - 32)).y
        hintBackdrop.setScale(pointScale)
        hintBackdrop.position = CGPoint(x: frame.midX, y: bottom)
        hint.fontSize = 16 * pointScale
        hint.position = hintBackdrop.position
        moreAppsButton.setScale(pointScale)
        moreAppsButton.position = CGPoint(x: right - 56 * pointScale, y: top)
        settingsButton.setScale(pointScale)
        settingsButton.position = CGPoint(x: left + 56 * pointScale, y: top)
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
        if moreAppsButton?.calculateAccumulatedFrame().contains(touchLocation) == true {
            view?.window?.rootViewController?.present(MoreAppsViewController(), animated: true)
            return
        }
        if settingsButton?.calculateAccumulatedFrame().contains(touchLocation) == true {
            (view?.window?.rootViewController as? GameViewController)?.showSettings(for: self)
            return
        }

        let touchInMap = convert(touchLocation, to: moveableNode)
        guard let index = levelPoints.firstIndex(where: {
            hypot(touchInMap.x - $0.x, touchInMap.y - $0.y) < 80
        }) else { return }
        let level = index + 1
        if level > bestLevel {
            hint.removeAllActions()
            hint.text = "Finish earlier levels to unlock".localized()
            hint.run(.sequence([.wait(forDuration: 1.8), .run { [weak self] in
                self?.hint.text = "Swipe to explore levels".localized()
            }]))
            return
        }
        if let scene = GameScene.level(levelNum: level) {
            view?.presentScene(scene, transition: .fade(withDuration: 0.3))
        }
    }
}
