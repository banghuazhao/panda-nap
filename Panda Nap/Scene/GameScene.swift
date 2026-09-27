//
//  GameScene.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/21/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import GameplayKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif
import SpriteKit

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Panda: UInt32 = 0b1 // 1
    static let Block: UInt32 = 0b10 // 2
    static let Bed: UInt32 = 0b100 // 4
    static let Edge: UInt32 = 0b1000
    static let Label: UInt32 = 0b10000 // 16
}

protocol EventListenerNode {
    func didMoveToScene()
}

protocol InteractiveNode {
    func interact()
}

var loseTime = 0

class GameScene: SKScene {
    #if !targetEnvironment(macCatalyst)
    private var interstitialAd: InterstitialAd?
    #endif
    let menuNode = SKSpriteNode(imageNamed: "menu").then { node in
        node.name = "menu"
        node.zPosition = 100
        node.setScale(0.6)
    }

    let moreAppsNode = SKSpriteNode(imageNamed: "menu_template").then { node in
        node.name = "moreApps"
        node.zPosition = 100
        node.setScale(0.6)
    }

    var bedNode: BedNode!
    var pandaNode: PandaNode!

    var playable = true

    var currentLevel: Int = 0

    override func didMove(to view: SKView) {
        // 2.165
        // 2.164
        let maxAspectRatio: CGFloat = 2.2
        let maxAspectRatioHeight = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height
            - maxAspectRatioHeight) / 2
        let playableRect = CGRect(x: size.width * 0.2, y: playableMargin,
                                  width: size.width * 0.6,
                                  height: size.height - playableMargin * 2)

        physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        physicsWorld.contactDelegate = self
        physicsBody!.categoryBitMask = PhysicsCategory.Edge

        enumerateChildNodes(withName: "//*", using: { node, _ in if let eventListenerNode = node as? EventListenerNode {
            eventListenerNode.didMoveToScene()
        }
        })

        guard let bed = childNode(withName: "bed") as? BedNode,
              let panda = childNode(withName: "panda") as? PandaNode else {
            playable = false
            assertionFailure("Level scene is missing its bed or panda node")
            return
        }
        bedNode = bed
        pandaNode = panda

        SKTAudio.sharedInstance().playBackgroundMusic("background.mp3")

        addChild(menuNode)
        menuNode.position = CGPoint(x: 200, y: size.height * 0.5 + 100)

        addChild(moreAppsNode)
        moreAppsNode.position = CGPoint(x: 200, y: size.height * 0.5 - 100)
        let moreAppsLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
            node.text = "More Apps".localized()
            node.fontColor = SKColor.black
            node.fontSize = 54
            node.zPosition = 100
            node.horizontalAlignmentMode = .center
            node.verticalAlignmentMode = .center
        }

        moreAppsLabel.position = CGPoint(
            x: 0, y: 0)
        moreAppsNode.addChild(moreAppsLabel)

        #if !targetEnvironment(macCatalyst)
        if loseTime == 1 {
            InterstitialAd.load(with: Constants.interstitialAdID, request: Request()) { [weak self] ad, error in
                if let error { print("Failed to load interstitial: \(error.localizedDescription)") }
                self?.interstitialAd = ad
                ad?.fullScreenContentDelegate = self
            }
        }
        #endif
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }

    override func didSimulatePhysics() {
        if playable {
            if abs(pandaNode.zRotation) > CGFloat(45).degreesToRadians() {
                lose()
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let nodesAtPoint = nodes(at: touchLocation)
        for node in nodesAtPoint {
            if node.name == "menu" {
                if let scene = SKScene(fileNamed: "MenuScene") as? MenuScene {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill

                    // Present the scene
                    let reveal = SKTransition.flipHorizontal(withDuration: 1.0)
                    view?.presentScene(scene, transition: reveal)
                }
            } else if node.name == "moreApps" {
                let moreAppsViewController = MoreAppsViewController()
                if let rootViewController = view?.window?.rootViewController { rootViewController.present(moreAppsViewController, animated: true)
                }
            }
        }
    }

    func inGameMessage(text: String) {
        let message = MessageNode(message: text)
        message.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(message)
    }

    func newGame() {
        if let nextScene = GameScene.level(levelNum: currentLevel) {
            view?.presentScene(nextScene)
        }
    }

    func lose() {
        playable = false
        // 1
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        SKTAudio.sharedInstance().playSoundEffect("lose.mp3")
        // 2
        inGameMessage(text: "Try again...".localized())
        pandaNode.scare()

        print("loseTime: \(loseTime)")
        if loseTime < 1 {
            loseTime += 1
            run(SKAction.afterDelay(3, runBlock: newGame))
        } else {
            #if !targetEnvironment(macCatalyst)
                run(SKAction.afterDelay(2, runBlock: { [weak self] in
                    guard let self else { return }
                    if let ad = self.interstitialAd,
                       let controller = self.view?.window?.rootViewController {
                        ad.present(from: controller)
                    } else {
                        self.newGame()
                    }
                }))
            #else
                let moreAppsViewController = MoreAppsViewController()
                if let rootViewController = view?.window?.rootViewController { rootViewController.present(moreAppsViewController, animated: true)
                }
            #endif
            loseTime = 0
        }
    }

    func win() {
        if currentLevel < Constants.totalLevel {
            currentLevel += 1
        } else {
            currentLevel = 1
        }
        playable = false
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        SKTAudio.sharedInstance().playSoundEffect("victory.mp3")
        inGameMessage(text: "Nice job!".localized())
        run(SKAction.afterDelay(3, runBlock: newGame))
        pandaNode.nap(scenePoint: bedNode.position)
    }

    class func level(levelNum: Int) -> GameScene? {
        guard let scene = GameScene(fileNamed: "Level\(levelNum)") else { return nil }
        scene.currentLevel = levelNum
        if levelNum > bestLevel {
            bestLevel = levelNum
            UserDefaults.standard.set(bestLevel, forKey: Constants.UserDefaultsKeys.BEST_LEVEL)
        }
        scene.scaleMode = .aspectFill
        return scene
    }
}

#if !targetEnvironment(macCatalyst)
extension GameScene: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialAd = nil
        newGame()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitialAd = nil
        newGame()
    }
}
#endif

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if !playable {
            return
        }
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == PhysicsCategory.Panda | PhysicsCategory.Bed {
            print("SUCCESS")
            win()
        } else if collision == PhysicsCategory.Panda | PhysicsCategory.Edge { print("FAIL")
            lose()
        }
    }
}
