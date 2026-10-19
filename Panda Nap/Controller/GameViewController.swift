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
        settings.onMotionChanged = { [weak scene] in
            (scene as? GameScene)?.refreshMotionPreferences()
            (scene as? MenuScene)?.refreshMotionPreferences()
        }
        settings.onClose = { [weak scene] in
            (scene as? GameScene)?.refreshMotionPreferences()
            (scene as? MenuScene)?.refreshMotionPreferences()
            scene?.isPaused = false
            SKTAudio.sharedInstance().resumeBackgroundMusic()
        }
        let navigation = UINavigationController(rootViewController: settings)
        navigation.modalPresentationStyle = .formSheet
        navigation.preferredContentSize = CGSize(width: 400, height: 390)
        navigation.isModalInPresentation = true
        present(navigation, animated: true)
    }

    func showRecords(for scene: MenuScene) {
        guard presentedViewController == nil, !scene.isPaused,
              (view as? SKView)?.scene === scene else { return }
        let records = LevelRecordsViewController(progress: progressSnapshot())
        let navigation = UINavigationController(rootViewController: records)
        navigation.modalPresentationStyle = .formSheet
        navigation.preferredContentSize = CGSize(width: 440, height: 500)
        navigation.isModalInPresentation = true
        var actionHandled = false

        let finish: (Int?) -> Void = { [weak self, weak scene, weak navigation] level in
            guard !actionHandled, let self, let scene, let navigation,
                  self.presentedViewController === navigation else { return }
            let selectedLevel = level.flatMap {
                (1...self.progressSnapshot().unlockedLevel).contains($0) ? $0 : nil
            }
            actionHandled = true
            self.dismiss(animated: true) { [weak self, weak scene] in
                guard let self, let scene, (self.view as? SKView)?.scene === scene else { return }
                scene.isPaused = false
                if let selectedLevel, (1...self.progressSnapshot().unlockedLevel).contains(selectedLevel),
                   scene.openLevel(selectedLevel) {
                    return
                }
                SKTAudio.sharedInstance().resumeBackgroundMusic()
            }
        }
        records.onClose = { finish(nil) }
        records.onSelectLevel = { finish($0) }
        scene.isPaused = true
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        present(navigation, animated: true)
    }

    private func progressSnapshot() -> LevelProgress {
        let defaults = UserDefaults.standard
        return LevelProgress(
            unlockedLevel: defaults.object(forKey: Constants.UserDefaultsKeys.bestLevel) as? Int ?? bestLevel,
            completedLevel: defaults.integer(forKey: Constants.UserDefaultsKeys.completedLevel),
            totalLevels: Constants.totalLevel)
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
    var onMotionChanged: (() -> Void)?
    var currentLevel: Int?
    var allLevelsComplete = false

    private var calmerAnimationsRow: Int {
        #if targetEnvironment(macCatalyst)
        return 4
        #else
        return 5
        #endif
    }

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
            return calmerAnimationsRow + 1
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
        let isMotionSetting = indexPath.section == 0 && indexPath.row == calmerAnimationsRow
        let cell = UITableViewCell(style: isMotionSetting ? .subtitle : .default, reuseIdentifier: nil)
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
        if indexPath.row == 1 || indexPath.row == 3 {
            let channel: AudioLevels.Channel = indexPath.row == 1 ? .music : .effects
            let volumeCell = AudioVolumeCell(style: .default, reuseIdentifier: nil)
            let title = channel == .music ? "Music Volume".localized() : "Sound Effects Volume".localized()
            volumeCell.configure(title: title, volume: AudioLevels.volume(for: channel)) { volume in
                switch channel {
                case .music: GameSettings.musicVolume = volume
                case .effects: GameSettings.effectsVolume = volume
                }
            }
            return volumeCell
        }
        if isMotionSetting {
            let title = "Calmer Animations".localized()
            let detail = "Reduce decorative motion. The device Reduce Motion setting is always respected.".localized()
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = detail
            cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
            cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            let toggle = UISwitch()
            toggle.tag = 3
            toggle.isOn = GameSettings.calmerAnimationsEnabled
            toggle.accessibilityLabel = title
            toggle.accessibilityHint = detail
            toggle.addTarget(self, action: #selector(settingChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            return cell
        }
        let toggleIndex = indexPath.row / 2
        let titles = ["Music".localized(), "Sound Effects".localized(), "Haptics".localized()]
        let values = [GameSettings.musicEnabled, GameSettings.effectsEnabled, GameSettings.hapticsEnabled]
        cell.textLabel?.text = titles[toggleIndex]
        cell.selectionStyle = .none
        let toggle = UISwitch()
        toggle.tag = toggleIndex
        toggle.isOn = values[toggleIndex]
        toggle.accessibilityLabel = titles[toggleIndex]
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
        case 0: GameSettings.musicEnabled = sender.isOn
        case 1: GameSettings.effectsEnabled = sender.isOn
        case 3:
            GameSettings.calmerAnimationsEnabled = sender.isOn
            onMotionChanged?()
        default: GameSettings.hapticsEnabled = sender.isOn
        }
    }

    @objc private func close() {
        dismiss(animated: true) { [onClose] in onClose?() }
    }
}

private final class AudioVolumeCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private var onVolumeChanged: ((Float) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        installControls()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installControls()
    }

    func configure(title: String, volume: Float, onChange: @escaping (Float) -> Void) {
        titleLabel.text = title
        slider.accessibilityLabel = title
        slider.value = volume
        onVolumeChanged = onChange
        updateValue()
    }

    private func installControls() {
        selectionStyle = .none
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.isAccessibilityElement = false
        valueLabel.font = .preferredFont(forTextStyle: .subheadline)
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = .secondaryLabel
        valueLabel.isAccessibilityElement = false
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
        let heading = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        heading.alignment = .center
        heading.spacing = 12
        let controls = UIStackView(arrangedSubviews: [heading, slider])
        controls.axis = .vertical
        controls.spacing = 8
        controls.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(controls)
        NSLayoutConstraint.activate([
            controls.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            controls.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            controls.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            controls.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    @objc private func volumeChanged() {
        updateValue()
        onVolumeChanged?(slider.value)
    }

    private func updateValue() {
        let percentage = NumberFormatter.localizedString(from: NSNumber(value: slider.value), number: .percent)
        valueLabel.text = percentage
        slider.accessibilityValue = percentage
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

    private var hasEarnedPostcard: Bool {
        LevelProgress(
            unlockedLevel: UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.bestLevel) as? Int ?? bestLevel,
            completedLevel: UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.completedLevel),
            totalLevels: Constants.totalLevel).allComplete
    }

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
            if hasEarnedPostcard {
                let share = UIBarButtonItem(barButtonSystemItem: .action, target: self,
                                           action: #selector(sharePostcard))
                share.accessibilityLabel = "Share Postcard".localized()
                share.accessibilityHint = "Share your Nap Champion postcard.".localized()
                navigationItem.rightBarButtonItem = share
            }
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

    @objc private func sharePostcard() {
        guard case .reward = content, hasEarnedPostcard,
              presentedViewController == nil,
              navigationController?.presentedViewController == nil,
              navigationController?.topViewController === self,
              view.window != nil else { return }
        let sheet = UIActivityViewController(activityItems: [CompletionPostcard.image()], applicationActivities: nil)
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.safeAreaInsets.top,
                                        width: 1, height: 1)
        }
        present(sheet, animated: true)
    }
}
