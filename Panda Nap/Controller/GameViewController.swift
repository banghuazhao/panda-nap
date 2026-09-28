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
        navigation.preferredContentSize = CGSize(width: 400, height: 330)
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

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done".localized(), style: .done, target: self, action: #selector(close))
        tableView.rowHeight = 58
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 3 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Audio & Feedback".localized()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
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
