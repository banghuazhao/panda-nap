//
//  StoreReviewHelper.swift
//  Financial Ratios Go
//
//  Created by Banghua Zhao on 12/2/19.
//  Copyright © 2019 Banghua Zhao. All rights reserved.
//

import Foundation
import StoreKit

struct StoreReviewHelper {
        
    static func incrementOpenCount() { // called from appdelegate didfinishLaunchingWithOptions:
        guard var openCount = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.openCount) as? Int else {
            UserDefaults.standard.set(1, forKey: Constants.UserDefaultsKeys.openCount)
            return
        }
        openCount += 1
        UserDefaults.standard.set(openCount, forKey: Constants.UserDefaultsKeys.openCount)
    }
    static func checkAndAskForReview() { // call this whenever appropriate
        // this will not be shown everytime. Apple has some internal logic on how to show this.
        guard let openCount = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.openCount) as? Int else {
            UserDefaults.standard.set(1, forKey: Constants.UserDefaultsKeys.openCount)
            return
        }
        
        switch openCount {
        case 5,25:
            StoreReviewHelper().requestReview()
        case _ where openCount%100 == 0 :
            StoreReviewHelper().requestReview()
        default:
            print("Open count is : \(openCount)")
            break;
        }
        
    }
    fileprivate func requestReview() {
        SKStoreReviewController.requestReview()
    }
}
