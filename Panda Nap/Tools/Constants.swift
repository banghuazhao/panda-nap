//
//  Constants.swift
//  Crazy Pyramid
//
//  Created by Banghua Zhao on 12/19/19.
//  Copyright © 2019 Banghua Zhao. All rights reserved.
//

import UIKit

struct Constants {
    static let isIPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone

    static let adMobAppID = "ca-app-pub-4766086782456413~5622382915"
    
    static let countdownDaysAppID = "1525084657"
    static let moneyTrackerAppID = "1534244892"
    static let financeGoAppID = "1519476344"
    static let financialRatiosGoAppID = "1481582303"
    static let finanicalRatiosGoMacOSAppID = "1486184864"
    static let BMIDiaryAppID = "1521281509"
    static let fourGreatClassicalNovelsAppID = "1526758926"
    static let novelsHubAppID = "1528820845"

    static let bannerAdUnitID = Bundle.main.object(forInfoDictionaryKey: "bannerViewAdUnitID") as? String ?? ""
    static let interstitialAdID = Bundle.main.object(forInfoDictionaryKey: "interstitialAdID") as? String ?? ""
    
    static let totalLevel = 10

    struct UserDefaultsKeys {
        static let OPEN_COUNT = "OPEN_COUNT"
        static let BEST_LEVEL = "BEST_LEVEL"
    }

    static var isIphoneFaceID: Bool {
        if let topInset = UIApplication.shared.delegate?.window??.safeAreaInsets.top, topInset <= 24 {
            return false
        } else {
            return true
        }
    }
}
