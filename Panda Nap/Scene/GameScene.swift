import SpriteKit
import UIKit
#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
#endif

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Panda: UInt32 = 0b1
    static let Block: UInt32 = 0b10
    static let Bed: UInt32 = 0b100
    static let Edge: UInt32 = 0b1000
}

protocol EventListenerNode {
    func didMoveToScene()
}

protocol InteractiveNode {
    func interact()
}

private var consecutiveLosses = 0

class GameScene: SKScene {
    enum Command { case retry, levels, settings, next }
    enum LossReason { case tipped, boundary }
    #if !targetEnvironment(macCatalyst)
    private var interstitialAd: InterstitialAd?
    private var privacyObserver: NSObjectProtocol?
    #endif

    private let hud = SKNode()
    private var levelsButton: SKShapeNode?
    private var retryButton: SKShapeNode?
    private var settingsButton: SKShapeNode?
    private var levelBadge: SKShapeNode?
    private var levelNameBadge: SKShapeNode?
    private var removalsBadge: SKShapeNode?
    private var bestBadge: SKShapeNode?
    private var targetBadge: SKShapeNode?
    private var hintNode: SKShapeNode?
    private var tutorialTarget: SKNode?
    private var tutorialHalo: SKShapeNode?
    private var resultCard: MessageNode?
    private var resultActionHandled = false
    private var won = false
    private var isTransitioning = false
    private(set) var removalCount = 0
    private(set) var lastLossReason: LossReason?
    private var accessibilityObstacleNumbers: [ObjectIdentifier: Int] = [:]
    private var resultAccessibilitySummary = ""
    private var pointScale: CGFloat = 1
    private var motionObserver: NSObjectProtocol?

    var bedNode: BedNode!
    var pandaNode: PandaNode!
    var playable = true
    var currentLevel = 0

    var acceptsGameplayInput: Bool {
        playable && !isPaused && !isTransitioning && view?.scene === self
            && view?.window?.rootViewController?.presentedViewController == nil
    }

    func canPerformCommand(_ command: Command) -> Bool {
        guard !isPaused, !isTransitioning, view?.scene === self,
              view?.window?.rootViewController?.presentedViewController == nil else { return false }
        if resultCard != nil {
            guard !resultActionHandled else { return false }
            switch command {
            case .retry, .levels: return true
            case .next: return won && currentLevel < Constants.totalLevel
            case .settings: return false
            }
        }
        return playable && command != .next
    }

    /// Touch and keyboard input share the same state and transition guards.
    func performCommand(_ command: Command) {
        guard canPerformCommand(command) else { return }
        let fromResult = resultCard != nil
        if fromResult { resultActionHandled = true }
        lightHaptic()
        switch command {
        case .retry:
            if fromResult { retryLevel() } else { newGame() }
        case .levels: showLevels()
        case .next: advanceToNextLevel()
        case .settings:
            (view?.window?.rootViewController as? GameViewController)?.showSettings(for: self)
        }
    }

    override func didMove(to view: SKView) {
        let maxAspectRatio: CGFloat = 2.2
        let maxAspectRatioHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - maxAspectRatioHeight) / 2
        let playableRect = CGRect(x: size.width * 0.2, y: playableMargin,
                                  width: size.width * 0.6,
                                  height: size.height - playableMargin * 2)

        physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        physicsBody?.categoryBitMask = PhysicsCategory.Edge
        physicsWorld.contactDelegate = self

        enumerateChildNodes(withName: "//*", using: { node, _ in
            (node as? EventListenerNode)?.didMoveToScene()
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
        hud.zPosition = 130
        addChild(hud)
        installHUD()
        layoutHUD()
        installTutorial()
        motionObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.refreshMotionPreferences() }
        installAccessibility()
        SceneAccessibility.announceScene(on: view, scene: self)

        #if !targetEnvironment(macCatalyst)
        privacyObserver = NotificationCenter.default.addObserver(
            forName: .adPrivacyDidChange, object: nil, queue: .main
        ) { [weak self] _ in self?.interstitialAd = nil }
        if consecutiveLosses == 1, let request = AdPrivacyManager.shared.adRequest() {
            let privacyRevision = AdPrivacyManager.shared.revision
            InterstitialAd.load(with: Constants.interstitialAdID, request: request) { [weak self] ad, error in
                if let error { print("Failed to load interstitial: \(error.localizedDescription)") }
                guard AdPrivacyManager.shared.revision == privacyRevision,
                      AdPrivacyManager.shared.canRequestAds else { return }
                self?.interstitialAd = ad
                ad?.fullScreenContentDelegate = self
            }
        }
        #endif
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        if let motionObserver { NotificationCenter.default.removeObserver(motionObserver) }
        motionObserver = nil
        SceneAccessibility.clear(from: view, scene: self)
        #if !targetEnvironment(macCatalyst)
        if let privacyObserver { NotificationCenter.default.removeObserver(privacyObserver) }
        privacyObserver = nil
        interstitialAd = nil
        #endif
    }

    private func installHUD() {
        levelsButton = pill("Levels".localized(), name: "levels", width: 108, height: 48,
                            fill: SKColor(red: 0.30, green: 0.61, blue: 0.17, alpha: 0.97))
        retryButton = pill("Retry".localized(), name: "retry", width: 100, height: 48,
                           fill: SKColor(red: 0.11, green: 0.31, blue: 0.21, alpha: 0.94))
        settingsButton = pill("Settings".localized(), name: "settings", width: 108, height: 48,
                              fill: SKColor(red: 0.11, green: 0.31, blue: 0.21, alpha: 0.94))
        levelBadge = pill(String(format: "Level %d".localized(), currentLevel), name: "levelBadge",
                          width: 108, height: 35,
                          fill: SKColor(red: 0.10, green: 0.25, blue: 0.16, alpha: 0.88))
        let recordFill = SKColor(red: 0.10, green: 0.25, blue: 0.16, alpha: 0.88)
        removalsBadge = pill("", name: "removals", width: 100, height: 35, fill: recordFill)
        bestBadge = pill("", name: "best", width: 100, height: 35, fill: recordFill)
        [levelsButton, retryButton, settingsButton, levelBadge, removalsBadge, bestBadge]
            .compactMap { $0 }.forEach(hud.addChild)
        if let name = LevelCatalog.name(for: currentLevel) {
            let badge = pill(name, name: "levelName", width: 108, height: 52, fill: recordFill)
            if let label = badge.children.first as? SKLabelNode {
                label.numberOfLines = 2
                label.preferredMaxLayoutWidth = 92
                label.lineBreakMode = .byWordWrapping
            }
            hud.addChild(badge)
            levelNameBadge = badge
        }
        if let target = LevelChallenge.targetRemovals(for: currentLevel) {
            targetBadge = pill(String(format: "Target: %d".localized(), target), name: "target",
                               width: 100, height: 35, fill: recordFill)
            if let targetBadge { hud.addChild(targetBadge) }
        }
        updateRemovalHUD()

        if currentLevel == 1 && !GameSettings.tutorialCompleted {
            hintNode = pill("Tap blocks to guide the panda".localized(), name: "hint",
                            width: 260, height: 38,
                            fill: SKColor(red: 0.09, green: 0.24, blue: 0.15, alpha: 0.88))
            if let hintNode {
                hud.addChild(hintNode)
            }
        }
    }

    private func pill(_ title: String, name: String, width: CGFloat, height: CGFloat,
                      fill: SKColor) -> SKShapeNode {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        node.name = name
        node.fillColor = fill
        node.strokeColor = SKColor(red: 0.72, green: 0.88, blue: 0.48, alpha: 0.92)
        node.lineWidth = 2

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = title
        label.fontSize = ["hint", "removals", "best", "target", "levelName"].contains(name) ? 14 : (name == "levelBadge" ? 16 : 18)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        node.addChild(label)
        return node
    }

    /// Position controls in view points, then convert into SpriteKit coordinates.
    func layoutHUD() {
        guard let view, let levelsButton, let retryButton, let settingsButton,
              let levelBadge else { return }
        let origin = convertPoint(fromView: .zero)
        pointScale = abs(convertPoint(fromView: CGPoint(x: 1, y: 0)).x - origin.x)
        let safe = view.safeAreaInsets
        let top = convertPoint(fromView: CGPoint(x: 0, y: safe.top + 34)).y
        let left = convertPoint(fromView: CGPoint(x: safe.left + 16, y: 0)).x
        let right = convertPoint(fromView: CGPoint(x: view.bounds.width - safe.right - 16, y: 0)).x

        levelsButton.setScale(pointScale)
        levelsButton.position = CGPoint(x: left + 54 * pointScale, y: top)
        retryButton.setScale(pointScale)
        retryButton.position = CGPoint(x: right - 50 * pointScale, y: top)
        settingsButton.setScale(pointScale)
        settingsButton.position = CGPoint(x: frame.midX, y: top)
        levelBadge.setScale(pointScale)
        levelBadge.position = CGPoint(x: levelsButton.position.x, y: top - 54 * pointScale)
        levelNameBadge?.setScale(pointScale)
        levelNameBadge?.position = CGPoint(x: levelsButton.position.x, y: top - 103 * pointScale)
        removalsBadge?.setScale(pointScale)
        removalsBadge?.position = CGPoint(x: right - 50 * pointScale, y: top - 54 * pointScale)
        bestBadge?.setScale(pointScale)
        bestBadge?.position = CGPoint(x: right - 50 * pointScale, y: top - 95 * pointScale)
        targetBadge?.setScale(pointScale)
        targetBadge?.position = CGPoint(x: right - 50 * pointScale, y: top - 136 * pointScale)

        layoutTutorial()
    }

    private func installTutorial() {
        guard hintNode != nil else { return }
        enumerateChildNodes(withName: "//*", using: { [weak self] node, stop in
            if node is BlockNode {
                self?.tutorialTarget = node
                stop.pointee = true
            }
        })
        guard let target = tutorialTarget else { return }
        let halo = SKShapeNode(rectOf: CGSize(width: target.frame.width + 20,
                                               height: target.frame.height + 20), cornerRadius: 12)
        halo.fillColor = .clear
        halo.strokeColor = SKColor(red: 1, green: 0.91, blue: 0.40, alpha: 1)
        halo.lineWidth = 5
        halo.zPosition = 1.5
        addChild(halo)
        tutorialHalo = halo
        refreshMotionPreferences()
        layoutTutorial()
    }

    /// Existing gameplay and removal actions keep their timing; only decoration changes.
    func refreshMotionPreferences() {
        let reduceMotion = GameSettings.reduceMotionEnabled
        if let tutorialHalo {
            tutorialHalo.removeAction(forKey: "tutorialPulse")
            tutorialHalo.alpha = 1
            if !reduceMotion {
                tutorialHalo.run(.repeatForever(.sequence([.fadeAlpha(to: 0.35, duration: 0.7),
                                                          .fadeAlpha(to: 1, duration: 0.7)])),
                                 withKey: "tutorialPulse")
            }
        }
        if reduceMotion {
            children.filter { $0.name == "feedbackParticle" }.forEach { $0.removeFromParent() }
            if let resultCard {
                resultCard.removeAllActions()
                resultCard.setScale(1)
                resultCard.alpha = 1
            }
        }
    }

    private func layoutTutorial() {
        guard let target = tutorialTarget, let hintNode, let tutorialHalo else { return }
        let targetPoint = target.convert(CGPoint.zero, to: self)
        tutorialHalo.position = targetPoint
        hintNode.setScale(pointScale)
        let inset = 140 * pointScale
        let hintX = min(max(targetPoint.x, frame.minX + inset), frame.maxX - inset)
        let preferredY = targetPoint.y + 67 * pointScale
        let hintY = preferredY < frame.maxY - 85 * pointScale
            ? preferredY : targetPoint.y - 67 * pointScale
        hintNode.position = CGPoint(x: hintX, y: hintY)
    }

    override func didSimulatePhysics() {
        if playable && !isTransitioning && abs(pandaNode.zRotation) > CGFloat(45).degreesToRadians() {
            lose(reason: .tipped)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        if let resultCard {
            guard let choice = resultCard.choice(at: location, in: self) else { return }
            switch choice {
            case .next: performCommand(.next)
            case .retry: performCommand(.retry)
            case .levels: performCommand(.levels)
            }
            return
        }
        if levelsButton?.calculateAccumulatedFrame().contains(location) == true {
            performCommand(.levels)
        } else if retryButton?.calculateAccumulatedFrame().contains(location) == true {
            performCommand(.retry)
        } else if settingsButton?.calculateAccumulatedFrame().contains(location) == true {
            performCommand(.settings)
        }
    }

    private func showLevels() {
        guard !isTransitioning, let view, view.scene === self,
              let menu = SKScene(fileNamed: "MenuScene") as? MenuScene else { return }
        isTransitioning = true
        consecutiveLosses = 0
        menu.scaleMode = .aspectFill
        view.presentScene(menu, transition: .fade(withDuration: 0.25))
    }

    func blockRemoved(at point: CGPoint, stone: Bool) {
        guard acceptsGameplayInput else { return }
        if removalCount < Int.max { removalCount += 1 }
        updateRemovalHUD()
        installAccessibility()
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
        if currentLevel == 1 { GameSettings.tutorialCompleted = true }
        hintNode?.removeAllActions()
        hintNode?.run(.sequence([.fadeOut(withDuration: 0.12), .removeFromParent()]))
        hintNode = nil
        tutorialHalo?.removeAllActions()
        tutorialHalo?.run(.sequence([.fadeOut(withDuration: 0.12), .removeFromParent()]))
        tutorialHalo = nil
        tutorialTarget = nil
        burst(at: point, color: stone ? .lightGray : SKColor(red: 0.58, green: 0.35, blue: 0.16, alpha: 1),
              count: stone ? 10 : 7, distance: 46)
        lightHaptic()
    }

    private func updateRemovalHUD() {
        (removalsBadge?.children.first as? SKLabelNode)?.text = String(
            format: "Removed: %d".localized(), removalCount)
        (bestBadge?.children.first as? SKLabelNode)?.text = LevelRecordStore.bestRemovals(for: currentLevel)
            .map { String(format: "Best: %d".localized(), $0) } ?? "No best yet".localized()
    }

    private func installAccessibility() {
        guard let view else { return }
        var items: [SceneAccessibility.Item] = []

        func commandItem(_ node: SKNode, title: String, command: Command) -> SceneAccessibility.Item {
            SceneAccessibility.Item(node: node, label: title,
                isEnabled: { [weak self] in self?.canPerformCommand(command) == true },
                activate: { [weak self] in
                    guard let self, self.canPerformCommand(command) else { return false }
                    self.performCommand(command)
                    return true
                })
        }

        if let resultCard {
            if let title = resultCard.accessibilityTitleNode {
                items.append(SceneAccessibility.Item(node: title, label: resultAccessibilitySummary,
                                                       traits: .staticText))
            }
            for (choice, node, title) in resultCard.accessibilityChoices {
                let command: Command
                switch choice {
                case .retry: command = .retry
                case .levels: command = .levels
                case .next: command = .next
                }
                items.append(commandItem(node, title: title, command: command))
            }
            SceneAccessibility.install(on: view, scene: self, items: items)
            return
        }

        if let levelsButton { items.append(commandItem(levelsButton, title: "Levels".localized(), command: .levels)) }
        if let settingsButton { items.append(commandItem(settingsButton, title: "Settings".localized(), command: .settings)) }
        if let retryButton { items.append(commandItem(retryButton, title: "Retry".localized(), command: .retry)) }
        if let levelBadge {
            items.append(SceneAccessibility.Item(node: levelBadge,
                label: LevelCatalog.title(for: currentLevel),
                value: { [weak self] in
                    guard let self else { return nil }
                    var values = [String(format: "Removed: %d".localized(), self.removalCount)]
                    if let best = LevelRecordStore.bestRemovals(for: self.currentLevel) {
                        values.append(String(format: "Best: %d".localized(), best))
                    } else { values.append("No best yet".localized()) }
                    if let target = LevelChallenge.targetRemovals(for: self.currentLevel) {
                        values.append(String(format: "Target: %d".localized(), target))
                    }
                    return values.joined(separator: ", ")
                }, traits: .staticText))
        }
        if let pandaNode {
            items.append(SceneAccessibility.Item(node: pandaNode, label: "Panda".localized(),
                value: { [weak self, weak pandaNode] in
                    guard let self, let pandaNode else { return nil }
                    return self.accessibilityPosition(of: pandaNode)
                }, traits: .staticText))
        }
        if let bedNode { items.append(SceneAccessibility.Item(node: bedNode, label: "Bed".localized(), traits: .staticText)) }

        var obstacles: [SKNode] = []
        enumerateChildNodes(withName: "//*") { node, _ in
            if node is InteractiveNode && node.isUserInteractionEnabled { obstacles.append(node) }
        }
        obstacles.sort {
            let first = accessibilityScenePosition(of: $0)
            let second = accessibilityScenePosition(of: $1)
            return first.y != second.y ? first.y > second.y : first.x < second.x
        }
        for obstacle in obstacles {
            let id = ObjectIdentifier(obstacle)
            if accessibilityObstacleNumbers[id] == nil {
                accessibilityObstacleNumbers[id] = accessibilityObstacleNumbers.count + 1
            }
            let title = obstacle is StoneNode ? "Stone structure".localized()
                : String(format: "Wooden block %d".localized(), accessibilityObstacleNumbers[id] ?? 1)
            items.append(SceneAccessibility.Item(node: obstacle, label: title,
                value: { [weak self, weak obstacle] in
                    guard let self, let obstacle else { return nil }
                    return self.accessibilityPosition(of: obstacle)
                }, hint: "Double-tap to remove".localized(),
                isEnabled: { [weak self, weak obstacle] in
                    self?.acceptsGameplayInput == true && obstacle?.isUserInteractionEnabled == true
                }, activate: { [weak self, weak obstacle] in
                    guard let self, self.acceptsGameplayInput, let obstacle,
                          obstacle.isUserInteractionEnabled, let interactive = obstacle as? InteractiveNode else { return false }
                    let count = self.removalCount
                    interactive.interact()
                    return self.removalCount > count
                }))
        }
        SceneAccessibility.install(on: view, scene: self, items: items)
    }

    private func accessibilityScenePosition(of node: SKNode) -> CGPoint {
        let bounds = node.calculateAccumulatedFrame()
        let point = CGPoint(x: bounds.midX, y: bounds.midY)
        return node.parent?.convert(point, to: self) ?? node.position
    }

    private func accessibilityPosition(of node: SKNode) -> String {
        let x = accessibilityScenePosition(of: node).x
        let center = bedNode?.position.x ?? frame.midX
        if x < center - 80 { return "Left of the bed".localized() }
        if x > center + 80 { return "Right of the bed".localized() }
        return "Above the bed".localized()
    }

    private func burst(at point: CGPoint, color: SKColor, count: Int, distance: CGFloat) {
        guard !GameSettings.reduceMotionEnabled else { return }
        for index in 0..<count {
            let fragment = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5) * pointScale)
            fragment.fillColor = color
            fragment.strokeColor = .clear
            fragment.position = point
            fragment.zPosition = 115
            fragment.name = "feedbackParticle"
            addChild(fragment)

            let angle = CGFloat(index) * (.pi * 2 / CGFloat(count)) + CGFloat.random(in: -0.25...0.25)
            let travel = CGFloat.random(in: 0.5...1) * distance * pointScale
            let move = SKAction.moveBy(x: cos(angle) * travel, y: sin(angle) * travel, duration: 0.34)
            move.timingMode = .easeOut
            fragment.run(.sequence([.group([move, .fadeOut(withDuration: 0.34),
                                            .scale(to: 0.2, duration: 0.34)]), .removeFromParent()]))
        }
    }

    private func lightHaptic() {
        #if !targetEnvironment(macCatalyst)
        if GameSettings.hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        #endif
    }

    private func resultHaptic(success: Bool) {
        #if !targetEnvironment(macCatalyst)
        if GameSettings.hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(success ? .success : .error)
        }
        #endif
    }

    private func showResult(_ title: String, detail: String, won: Bool, statistics: String? = nil) {
        let backdrop = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.36), size: size)
        backdrop.position = CGPoint(x: frame.midX, y: frame.midY)
        backdrop.zPosition = 190
        addChild(backdrop)
        let message = MessageNode(message: title, detail: detail, won: won,
                                  finalLevel: won && currentLevel == Constants.totalLevel,
                                  pointScale: pointScale, statistics: statistics)
        message.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(message)
        resultCard = message
        resultAccessibilitySummary = [title, detail, statistics].compactMap { $0 }.joined(separator: ". ")
        message.appear(reduceMotion: GameSettings.reduceMotionEnabled)
        installAccessibility()
        if UIAccessibility.isVoiceOverRunning {
            // The result card fades in; announce after it has visible geometry.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self, weak message] in
                guard let self, let message, self.view?.scene === self,
                      self.resultCard === message, !self.resultActionHandled, !self.isPaused,
                      self.view?.window?.rootViewController?.presentedViewController == nil else { return }
                UIAccessibility.post(notification: .screenChanged, argument: nil)
            }
        }
    }

    func newGame() {
        presentLevel(currentLevel)
    }

    private func presentLevel(_ level: Int) {
        guard !isTransitioning, let view, view.scene === self,
              let nextScene = GameScene.level(levelNum: level) else { return }
        isTransitioning = true
        view.presentScene(nextScene, transition: .fade(withDuration: 0.25))
    }

    private func advanceToNextLevel() {
        guard won else { return }
        guard currentLevel < Constants.totalLevel else { showLevels(); return }
        presentLevel(currentLevel + 1)
    }

    private func retryLevel() {
        #if !targetEnvironment(macCatalyst)
        if !won && consecutiveLosses >= 2 {
            consecutiveLosses = 0
            if let ad = interstitialAd,
               let controller = view?.window?.rootViewController,
               AdPrivacyManager.shared.canRequestAds {
                ad.present(from: controller)
                return
            }
        }
        #endif
        newGame()
    }

    func lose(reason: LossReason = .boundary) {
        guard playable, !isTransitioning else { return }
        playable = false
        lastLossReason = reason
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        SKTAudio.sharedInstance().playSoundEffect("lose.mp3")
        pandaNode.scare()
        burst(at: pandaNode.position, color: SKColor(red: 0.91, green: 0.57, blue: 0.25, alpha: 1),
              count: 12, distance: 65)
        resultHaptic(success: false)
        let title = reason == .tipped ? "Panda tipped too far" : "Panda reached the boundary"
        let detail = reason == .tipped ? "Keep Panda steady and try another order."
            : "Guide Panda toward the bed and away from the edges."
        showResult(title.localized(), detail: detail.localized(), won: false)

        consecutiveLosses += 1
    }

    func win() {
        guard playable, !isTransitioning else { return }
        playable = false
        won = true
        let newBest = LevelRecordStore.recordWin(level: currentLevel, removals: removalCount)
        updateRemovalHUD()
        let completed = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.completedLevel)
        if currentLevel > completed {
            UserDefaults.standard.set(currentLevel, forKey: Constants.UserDefaultsKeys.completedLevel)
        }
        if currentLevel < Constants.totalLevel && currentLevel + 1 > bestLevel {
            bestLevel = currentLevel + 1
            UserDefaults.standard.set(bestLevel, forKey: Constants.UserDefaultsKeys.bestLevel)
        }
        consecutiveLosses = 0
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        SKTAudio.sharedInstance().playSoundEffect("victory.mp3")
        pandaNode.nap(scenePoint: bedNode.position)
        burst(at: bedNode.position, color: SKColor(red: 0.94, green: 0.78, blue: 0.27, alpha: 1),
              count: 24, distance: 105)
        resultHaptic(success: true)
        let finished = currentLevel == Constants.totalLevel
        var statistics = String(format: "%d removals • Best: %d".localized(), removalCount,
                                LevelRecordStore.bestRemovals(for: currentLevel) ?? removalCount)
        if let target = LevelChallenge.targetRemovals(for: currentLevel), removalCount <= target {
            statistics += "\n" + "Challenge medal earned!".localized()
        }
        showResult(finished ? "Nap Champion".localized()
                            : (newBest ? "New personal best!" : "Nice job!").localized(),
                   detail: finished ? "Sweet dreams, Panda!".localized()
                                    : "Choose what to do next".localized(),
                   won: true, statistics: statistics)
    }

    class func level(levelNum: Int) -> GameScene? {
        guard (1...Constants.totalLevel).contains(levelNum),
              let scene = GameScene(fileNamed: "Level\(levelNum)") else { return nil }
        scene.currentLevel = levelNum
        if levelNum > bestLevel {
            bestLevel = levelNum
            UserDefaults.standard.set(bestLevel, forKey: Constants.UserDefaultsKeys.bestLevel)
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
        guard playable, !isTransitioning else { return }
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == (PhysicsCategory.Panda | PhysicsCategory.Bed) {
            win()
        } else if collision == (PhysicsCategory.Panda | PhysicsCategory.Edge) {
            lose(reason: .boundary)
        }
    }
}
