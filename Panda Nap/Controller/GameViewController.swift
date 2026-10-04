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
        #if !targetEnvironment(macCatalyst)
        AdPrivacyManager.shared.start(from: self)
        #endif
    }

    func showSettings(for scene: SKScene) {
        guard presentedViewController == nil else { return }
        scene.isPaused = true
        SKTAudio.sharedInstance().pauseBackgroundMusic()
        let settings = GameSettingsViewController(style: .insetGrouped)
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
    #if !targetEnvironment(macCatalyst)
    private var privacyObserver: NSObjectProtocol?
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done".localized(), style: .done, target: self, action: #selector(close))
        tableView.rowHeight = 58
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
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        section == 0 ? "Audio & Feedback".localized() : "Privacy".localized()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
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
