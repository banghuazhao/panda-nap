//
//  AppDelegate.swift
//  Panda Nap
//
//  Created by Banghua Zhao on 6/21/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif
import UIKit

var bestLevel = 1

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        #if !targetEnvironment(macCatalyst)
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        #else
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1280, height: 720)
            }
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                windowScene.sizeRestrictions?.minimumSize = CGSize(width: 1280, height: 720)
            }
        #endif

        if let previousBestLevel = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.BEST_LEVEL) as? Int {
            bestLevel = previousBestLevel
            print("bestLevel: \(bestLevel)")
        } else {
            UserDefaults.standard.set(1, forKey: Constants.UserDefaultsKeys.BEST_LEVEL)
        }

        StoreReviewHelper.incrementOpenCount()
        StoreReviewHelper.checkAndAskForReview()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        #if !targetEnvironment(macCatalyst)
            requestATTPermission()
        #endif
    }
}
