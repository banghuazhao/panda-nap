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

        if let previousBestLevel = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.bestLevel) as? Int {
            bestLevel = min(max(previousBestLevel, 1), Constants.totalLevel)
            print("bestLevel: \(bestLevel)")
        } else {
            UserDefaults.standard.set(1, forKey: Constants.UserDefaultsKeys.bestLevel)
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
