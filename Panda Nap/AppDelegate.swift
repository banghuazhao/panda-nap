//
//  AppDelegate.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/21/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import UIKit

var bestLevel = 1

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        #if targetEnvironment(macCatalyst)
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1280, height: 720)
            }
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                windowScene.sizeRestrictions?.minimumSize = CGSize(width: 1280, height: 720)
            }
        #endif

        let defaults = UserDefaults.standard
        let savedBestLevel = defaults.object(forKey: Constants.UserDefaultsKeys.bestLevel) as? Int
        let savedCompletedLevel = defaults.integer(forKey: Constants.UserDefaultsKeys.completedLevel)
        let progress = LevelProgress(unlockedLevel: savedBestLevel ?? 1,
                                     completedLevel: savedCompletedLevel,
                                     totalLevels: Constants.totalLevel)
        bestLevel = progress.unlockedLevel
        // Keep saves from a newer release intact when running a version with
        // fewer levels. Runtime access still uses the clamped snapshot above.
        if (savedBestLevel ?? 1) <= Constants.totalLevel {
            if savedBestLevel != progress.unlockedLevel {
                defaults.set(progress.unlockedLevel, forKey: Constants.UserDefaultsKeys.bestLevel)
            }
            if savedCompletedLevel != progress.completedLevels {
                defaults.set(progress.completedLevels, forKey: Constants.UserDefaultsKeys.completedLevel)
            }
        }

        StoreReviewHelper.incrementOpenCount()
        StoreReviewHelper.checkAndAskForReview()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Pause work that should not continue while the app is inactive.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save transient state here if background restoration is added.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Restore any paused work here if needed.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume foreground work when needed.
    }
}
