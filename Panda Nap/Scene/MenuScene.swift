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
    private var touchWasPanned = false
    private var isOpeningLevel = false
    private var progress = LevelProgress(unlockedLevel: 1, completedLevel: 0,
                                         totalLevels: Constants.totalLevel)
    private let hint = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let hintBackdrop = SKShapeNode(rectOf: CGSize(width: 300, height: 42), cornerRadius: 21)
    private var moreAppsButton: SKShapeNode?
    private var settingsButton: SKShapeNode?
    private var continueButton: SKShapeNode?
    private let progressLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let progressBackdrop = SKShapeNode(rectOf: CGSize(width: 184, height: 28), cornerRadius: 14)

    override func didMove(to view: SKView) {
        SKTAudio.sharedInstance().playBackgroundMusic("oboarding.mp3")

        addChild(moveableNode)

        hintBackdrop.fillColor = SKColor(red: 0.10, green: 0.25, blue: 0.16, alpha: 0.91)
        hintBackdrop.strokeColor = SKColor(red: 0.72, green: 0.88, blue: 0.48, alpha: 0.92)
        hintBackdrop.lineWidth = 2
        hintBackdrop.zPosition = 99
        addChild(hintBackdrop)
        progress = LevelProgress(
            unlockedLevel: bestLevel,
            completedLevel: UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.completedLevel),
            totalLevels: Constants.totalLevel)
        let allComplete = progress.allComplete
        hint.text = (allComplete ? "Replay any level"
                                 : "Swipe to explore levels").localized()
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

        let continueControl = SKShapeNode(rectOf: CGSize(width: 208, height: 44), cornerRadius: 22)
        continueControl.fillColor = SKColor(red: 0.30, green: 0.61, blue: 0.17, alpha: 0.97)
        continueControl.strokeColor = SKColor(red: 0.85, green: 0.96, blue: 0.65, alpha: 1)
        continueControl.lineWidth = 2
        continueControl.zPosition = 101
        let continueLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        continueLabel.text = allComplete ? "Replay Levels".localized()
            : String(format: "Continue: Level %d".localized(), progress.unlockedLevel)
        continueLabel.fontSize = 17
        continueLabel.fontColor = .white
        continueLabel.verticalAlignmentMode = .center
        continueControl.addChild(continueLabel)
        addChild(continueControl)
        continueButton = continueControl

        progressBackdrop.fillColor = hintBackdrop.fillColor
        progressBackdrop.strokeColor = .clear
        progressBackdrop.zPosition = 99
        addChild(progressBackdrop)
        progressLabel.text = String(format: "%d / %d completed".localized(),
                                    progress.completedLevels, progress.totalLevels)
        progressLabel.fontSize = 14
        progressLabel.fontColor = .white
        progressLabel.verticalAlignmentMode = .center
        progressLabel.zPosition = 100
        addChild(progressLabel)
        layoutUI()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)
        panGesture = pan
        installLevelMap(allComplete: allComplete)
    }

    private func installLevelMap(allComplete: Bool) {
        let levelTree = SKSpriteNode(imageNamed: "level_tree")
        levelTree.anchorPoint = CGPoint(x: 0.5, y: 0)
        levelTree.zPosition = 2
        levelTree.position = CGPoint(x: 0, y: -size.height * 2.0)
        moveableNode.addChild(levelTree)

        var levelNodePoints = [CGPoint]()

        for levelNumber in 1 ... Constants.totalLevel {
            let branchX: CGFloat = levelNumber % 2 == 1 ? 200 : -160
            let branchY: CGFloat = -size.height * 2.0 + CGFloat(1100 + levelNumber * 200)
            levelNodePoints.append(CGPoint(x: branchX, y: branchY))
        }

        // previous level
        if progress.unlockedLevel > 1 {
            for levelNumber in 1 ... progress.unlockedLevel - 1 {
                let level = SKSpriteNode(imageNamed: "fruit_orange")
                level.position = levelNodePoints[levelNumber - 1]
                if levelNumber % 2 == 0 {
                    level.xScale *= -1
                }
                level.name = "level_\(levelNumber)"
                moveableNode.addChild(level)
                let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
                labelNode.text = "\(levelNumber)"
                labelNode.fontColor = SKColor.white
                if levelNumber % 2 == 0 {
                    labelNode.xScale *= -1
                }
                labelNode.fontSize = 80
                labelNode.position = CGPoint(x: 30, y: -30)
                level.addChild(labelNode)
                addStatusMarker(to: level, completed: true)
            }
        }

        // current level
        let levelCurrent = SKSpriteNode(imageNamed: allComplete ? "fruit_orange" : "fruit_yellow")
        levelCurrent.position = levelNodePoints[progress.unlockedLevel - 1]
        if progress.unlockedLevel % 2 == 0 {
            levelCurrent.xScale *= -1
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

        levelCurrent.name = "level_\(progress.unlockedLevel)"
        moveableNode.addChild(levelCurrent)
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.text = "\(progress.unlockedLevel)"
        labelNode.fontColor = SKColor.white
        labelNode.fontSize = 80
        if progress.unlockedLevel % 2 == 0 {
            labelNode.xScale *= -1
        }
        labelNode.position = CGPoint(x: 30, y: -30)
        levelCurrent.addChild(labelNode)
        if allComplete { addStatusMarker(to: levelCurrent, completed: true) }

        // new levels
        if progress.unlockedLevel < Constants.totalLevel {
            for levelNumber in progress.unlockedLevel + 1 ... Constants.totalLevel {
                let level = SKSpriteNode(imageNamed: "fruit_green")
                level.position = levelNodePoints[levelNumber - 1]
                if levelNumber % 2 == 0 {
                    level.xScale *= -1
                }
                level.name = "level_\(levelNumber)"
                level.alpha = 0.55
                moveableNode.addChild(level)
                let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
                labelNode.text = "\(levelNumber)"
                labelNode.fontColor = SKColor.white
                labelNode.fontSize = 80
                if levelNumber % 2 == 0 {
                    labelNode.xScale *= -1
                }
                labelNode.position = CGPoint(x: 30, y: -30)
                level.addChild(labelNode)
                addStatusMarker(to: level, completed: false)
            }
        }

        levelPoints = levelNodePoints
        moveableNode.position.y = frame.midY - levelNodePoints[progress.unlockedLevel - 1].y
    }

    override func willMove(from view: SKView) {
        if let panGesture { view.removeGestureRecognizer(panGesture) }
    }

    private func addStatusMarker(to level: SKSpriteNode, completed: Bool) {
        let marker = SKShapeNode(circleOfRadius: 34)
        marker.position = CGPoint(x: 88, y: 40)
        // Even-numbered fruit is mirrored; keep its status symbol upright.
        marker.xScale = level.xScale < 0 ? -1 : 1
        marker.fillColor = SKColor(red: 0.10, green: 0.25, blue: 0.16, alpha: 1)
        marker.strokeColor = .white
        marker.lineWidth = 3
        marker.zPosition = 5
        let symbolName = completed ? "checkmark" : "lock.fill"
        let configuration = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
        if let image = UIImage(systemName: symbolName, withConfiguration: configuration)?
            .withTintColor(.white, renderingMode: .alwaysOriginal) {
            let symbol = SKSpriteNode(texture: SKTexture(image: image))
            marker.addChild(symbol)
        }
        level.addChild(marker)
    }

    func layoutUI() {
        guard let view, let moreAppsButton, let settingsButton, let continueButton else { return }
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
        let centerX = (left + right) / 2
        continueButton.setScale(pointScale)
        continueButton.position = CGPoint(x: centerX, y: top)
        progressBackdrop.setScale(pointScale)
        progressBackdrop.position = CGPoint(x: centerX, y: top - 39 * pointScale)
        progressLabel.fontSize = 14 * pointScale
        progressLabel.position = progressBackdrop.position
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !levelPoints.isEmpty, let view = self.view else { return }
        if gesture.state == .began || gesture.state == .changed {
            touchWasPanned = true
            moveableNode.removeAction(forKey: "focusLevel")
        }
        let translation = gesture.translation(in: view)
        let scale = size.height / view.bounds.height
        let minY = frame.midY - levelPoints[Constants.totalLevel - 1].y
        let maxY = frame.midY - levelPoints[0].y
        moveableNode.position.y = min(max(moveableNode.position.y + translation.y * scale, minY), maxY)
        gesture.setTranslation(.zero, in: view)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartLocation = touches.first?.location(in: self)
        touchWasPanned = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartLocation = nil
        touchWasPanned = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isOpeningLevel, let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        defer { touchStartLocation = nil }
        guard !touchWasPanned, let start = touchStartLocation else { return }
        let startInView = convertPoint(toView: start)
        let endInView = convertPoint(toView: touchLocation)
        guard hypot(endInView.x - startInView.x, endInView.y - startInView.y) < 10 else { return }
        if moreAppsButton?.calculateAccumulatedFrame().contains(touchLocation) == true {
            guard moreAppsButton?.calculateAccumulatedFrame().contains(start) == true,
                  view?.window?.rootViewController?.presentedViewController == nil else { return }
            view?.window?.rootViewController?.present(MoreAppsViewController(), animated: true)
            return
        }
        if settingsButton?.calculateAccumulatedFrame().contains(touchLocation) == true {
            guard settingsButton?.calculateAccumulatedFrame().contains(start) == true else { return }
            (view?.window?.rootViewController as? GameViewController)?.showSettings(for: self)
            return
        }
        if continueButton?.calculateAccumulatedFrame().contains(touchLocation) == true {
            guard continueButton?.calculateAccumulatedFrame().contains(start) == true else { return }
            if progress.allComplete {
                focusOnFirstLevel()
            } else {
                openLevel(progress.unlockedLevel)
            }
            return
        }
        // Informational overlays must not select a fruit behind their text.
        if progressBackdrop.contains(touchLocation) || hintBackdrop.contains(touchLocation) { return }

        let touchInMap = convert(touchLocation, to: moveableNode)
        guard let index = levelPoints.indices.first(where: { index in
            // Include the fruit's number and status badge in its touch target.
            moveableNode.childNode(withName: "level_\(index + 1)")?
                .calculateAccumulatedFrame().contains(touchInMap) == true
        }) else { return }
        let level = index + 1
        if level > progress.unlockedLevel {
            hint.removeAllActions()
            hint.text = "Finish earlier levels to unlock".localized()
            hint.run(.sequence([.wait(forDuration: 1.8), .run { [weak self] in
                self?.hint.text = "Swipe to explore levels".localized()
            }]))
            return
        }
        openLevel(level)
    }

    private func openLevel(_ level: Int) {
        guard !isOpeningLevel, (1...progress.unlockedLevel).contains(level),
              let view, let scene = GameScene.level(levelNum: level) else { return }
        isOpeningLevel = true
        view.presentScene(scene, transition: .fade(withDuration: 0.3))
    }

    private func focusOnFirstLevel() {
        guard let firstLevel = levelPoints.first else { return }
        let targetY = frame.midY - firstLevel.y
        moveableNode.removeAction(forKey: "focusLevel")
        if UIAccessibility.isReduceMotionEnabled {
            moveableNode.position.y = targetY
        } else {
            let move = SKAction.moveTo(y: targetY, duration: 0.25)
            move.timingMode = .easeInEaseOut
            moveableNode.run(move, withKey: "focusLevel")
        }
        hint.removeAllActions()
        hint.text = "Replay any level".localized()
    }
}
