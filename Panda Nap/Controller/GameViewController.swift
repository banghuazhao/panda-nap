//
//  GameViewController.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/21/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as? SKView {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "MenuScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }
            
//            view.ignoresSiblingOrder = false
//            view.showsPhysics = true
//            view.showsFPS = true
//            view.showsNodeCount = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let scene = (view as? SKView)?.scene else { return }
        (scene as? GameScene)?.layoutHUD()
        (scene as? MenuScene)?.layoutUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if targetEnvironment(macCatalyst)
        becomeFirstResponder()
        #endif
        #if !targetEnvironment(macCatalyst)
        AdPrivacyManager.shared.start(from: self)
        #endif
    }

    func showSettings(for scene: SKScene) {
        guard presentedViewController == nil else { return }
        scene.isPaused = true
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        let settings = GameSettingsViewController(style: .insetGrouped)
        settings.currentLevel = (scene as? GameScene)?.currentLevel
        settings.allLevelsComplete = LevelProgress(
            unlockedLevel: bestLevel,
            completedLevel: UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.completedLevel),
            totalLevels: Constants.totalLevel).allComplete
        settings.onClose = { [weak scene] in
            scene?.isPaused = false
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
        let navigation = UINavigationController(rootViewController: settings)
        navigation.modalPresentationStyle = .formSheet
        navigation.preferredContentSize = CGSize(width: 400, height: 390)
        navigation.isModalInPresentation = true
        present(navigation, animated: true)
    }

    #if targetEnvironment(macCatalyst)
    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        guard presentedViewController == nil, let scene = (view as? SKView)?.scene else { return [] }
        let commands: [(String, String, GameScene.Command)] = [
            ("r", "Retry Level", .retry), ("l", "Show Levels", .levels),
            ("s", "Settings", .settings), ("n", "Next Level", .next)
        ]
        return commands.compactMap { input, title, command in
            if let game = scene as? GameScene {
                guard game.canPerformCommand(command) else { return nil }
            } else {
                guard scene is MenuScene, !scene.isPaused, input == "s" else { return nil }
            }
            let key = UIKeyCommand(input: input, modifierFlags: [], action: #selector(handleGameCommand(_:)))
            key.discoverabilityTitle = title.localized()
            return key
        }
    }

    @objc private func handleGameCommand(_ key: UIKeyCommand) {
        guard presentedViewController == nil, let scene = (view as? SKView)?.scene else { return }
        let command: GameScene.Command
        switch key.input?.lowercased() {
        case "r": command = .retry
        case "l": command = .levels
        case "s": command = .settings
        case "n": command = .next
        default: return
        }
        if let game = scene as? GameScene {
            guard game.canPerformCommand(command) else { return }
            game.performCommand(command)
        } else if scene is MenuScene, !scene.isPaused, key.input?.lowercased() == "s" {
            showSettings(for: scene)
        }
    }
    #endif

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

private final class GameSettingsViewController: UITableViewController {
    var onClose: (() -> Void)?
    var currentLevel: Int?
    var allLevelsComplete = false

    private var helpPages: [GameHelpViewController.Content] {
        var pages: [GameHelpViewController.Content] = [.instructions]
        if let currentLevel, let hint = LevelHint.text(for: currentLevel) {
            pages.append(.hint(level: currentLevel, text: hint))
        }
        if allLevelsComplete { pages.append(.reward) }
        return pages
    }
    #if !targetEnvironment(macCatalyst)
    private var privacyObserver: NSObjectProtocol?
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done".localized(), style: .done, target: self, action: #selector(close))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 58
        #if !targetEnvironment(macCatalyst)
        privacyObserver = NotificationCenter.default.addObserver(
            forName: .adPrivacyDidChange, object: nil, queue: .main
        ) { [weak self] _ in self?.tableView.reloadData() }
        #endif
    }

    #if !targetEnvironment(macCatalyst)
    deinit {
        if let privacyObserver { NotificationCenter.default.removeObserver(privacyObserver) }
    }
    #endif

    override func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 { return helpPages.count }
        guard section == 1 else {
            #if targetEnvironment(macCatalyst)
            return 2
            #else
            return 3
            #endif
        }
        #if !targetEnvironment(macCatalyst)
        return 2
        #else
        return 1
        #endif
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Audio & Feedback".localized()
        case 1: return "Privacy".localized()
        default: return "Help".localized()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
        if indexPath.section == 2 {
            let pages = helpPages
            guard pages.indices.contains(indexPath.row) else { return cell }
            cell.textLabel?.text = pages[indexPath.row].title
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        if indexPath.section == 1 {
            cell.textLabel?.text = (indexPath.row == 0 ? "Privacy Policy" : "Privacy settings").localized()
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        let titles = ["Music".localized(), "Sound Effects".localized(), "Haptics".localized()]
        let values = [GameSettings.musicEnabled, GameSettings.effectsEnabled, GameSettings.hapticsEnabled]
        cell.textLabel?.text = titles[indexPath.row]
        cell.selectionStyle = .none
        let toggle = UISwitch()
        toggle.tag = indexPath.row
        toggle.isOn = values[indexPath.row]
        toggle.accessibilityLabel = titles[indexPath.row]
        toggle.addTarget(self, action: #selector(settingChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            let pages = helpPages
            guard pages.indices.contains(indexPath.row) else { return }
            let help = GameHelpViewController()
            help.content = pages[indexPath.row]
            navigationController?.pushViewController(help, animated: true)
            return
        }
        guard indexPath.section == 1 else { return }
        if indexPath.row == 0 {
            guard let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/privacy/") else { return }
            UIApplication.shared.open(url)
            return
        }
        #if !targetEnvironment(macCatalyst)
        if AdPrivacyManager.shared.canPresentPrivacyOptions {
            AdPrivacyManager.shared.presentPrivacyOptions(from: self)
        } else {
            let optedOut = AdPrivacyManager.shared.advertisingOptedOut
            let trackingDenied = AdPrivacyManager.shared.trackingPermissionDenied
            let regionalAdsBlocked = AdPrivacyManager.shared.adsBlockedByRegionalPrivacy
            let alert = UIAlertController(
                title: (optedOut || regionalAdsBlocked ? "Ads are off" : trackingDenied ? "Tracking is off" : "Ad choices").localized(),
                message: (optedOut
                    ? "Panda Nap is not requesting ads. Tracking permission can be changed in iOS Settings."
                    : regionalAdsBlocked
                        ? "Ads are off while tracking is denied in your region. Choose Stop ads to keep them off if that setting changes."
                    : trackingDenied
                        ? "Tracking remains off. You can stop all ad requests here without changing iOS Settings."
                        : "You can stop all ad requests here, including data shared for advertising.").localized(),
                preferredStyle: .alert
            )
            if !optedOut {
                alert.addAction(UIAlertAction(title: "Stop ads".localized(), style: .destructive) { _ in
                    AdPrivacyManager.shared.stopAds()
                })
            }
            alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
            present(alert, animated: true)
        }
        #endif
    }

    @objc private func settingChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 0:
            GameSettings.musicEnabled = sender.isOn
            SKTAudio.sharedInstance().pauseBackgroundMusic()
        case 1: GameSettings.effectsEnabled = sender.isOn
        default: GameSettings.hapticsEnabled = sender.isOn
        }
    }

    @objc private func close() {
        dismiss(animated: true) { [onClose] in onClose?() }
    }
}

private final class GameHelpViewController: UIViewController {
    enum Content {
        case instructions
        case hint(level: Int, text: String)
        case reward

        var title: String {
            switch self {
            case .instructions: return "How to Play".localized()
            case .hint(let level, _): return String(format: "Hint for Level %d".localized(), level)
            case .reward: return "Nap Champion".localized()
            }
        }
    }

    var content: Content = .instructions

    override func viewDidLoad() {
        super.viewDidLoad()
        title = content.title
        view.backgroundColor = .systemBackground

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let instructions = UIStackView()
        instructions.axis = .vertical
        instructions.spacing = 24
        instructions.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(instructions)

        var sections: [(String, String)]
        switch content {
        case .instructions:
            sections = [
                ("Reach the bed".localized(), "Help the sleepy panda land safely on her bed.".localized()),
                ("Remove obstacles".localized(), "Tap obstacles to remove them. Choose the order carefully.".localized()),
                ("Keep the panda steady".localized(), "The level ends if the panda falls to the ground or tilts too far.".localized()),
                ("Try another approach".localized(), "Use Retry to restart the level, or Levels to choose an unlocked level.".localized())
            ]
            #if targetEnvironment(macCatalyst)
            sections.append(("Keyboard controls".localized(),
                             "On Mac, press R to retry, L for levels, S for settings, and N for the next level after a win.".localized()))
            #endif
        case .hint(_, let text):
            sections = [("A gentle nudge".localized(), text),
                        ("Try another approach".localized(), "Use Retry to restart the level, or Levels to choose an unlocked level.".localized())]
        case .reward:
            if let image = UIImage(named: "panda_sleep") {
                let artwork = UIImageView(image: image)
                artwork.contentMode = .scaleAspectFit
                artwork.isAccessibilityElement = false
                artwork.heightAnchor.constraint(equalToConstant: 160).isActive = true
                instructions.addArrangedSubview(artwork)
            }
            sections = [("Sweet dreams, Panda!".localized(),
                         String(format: "You guided Panda through all %d levels.".localized(), Constants.totalLevel)),
                        ("Nap Champion".localized(), "Your bedtime postcard is always here. Replay a favorite level whenever you like.".localized())]
        }
        for (heading, detail) in sections {
            let section = UIStackView()
            section.axis = .vertical
            section.spacing = 8

            let headingLabel = UILabel()
            headingLabel.text = heading
            headingLabel.font = .preferredFont(forTextStyle: .headline)
            headingLabel.adjustsFontForContentSizeCategory = true
            headingLabel.numberOfLines = 0
            headingLabel.accessibilityTraits.insert(.header)

            let detailLabel = UILabel()
            detailLabel.text = detail
            detailLabel.font = .preferredFont(forTextStyle: .body)
            detailLabel.adjustsFontForContentSizeCategory = true
            detailLabel.numberOfLines = 0
            detailLabel.textColor = .secondaryLabel

            section.addArrangedSubview(headingLabel)
            section.addArrangedSubview(detailLabel)
            instructions.addArrangedSubview(section)
        }

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            instructions.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            instructions.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            instructions.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            instructions.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            instructions.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }
}
