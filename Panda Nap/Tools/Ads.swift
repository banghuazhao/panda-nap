//
//  Ads.swift
//  Height Tracker
//
//  Created by Banghua Zhao on 2021/1/31.
//  Copyright © 2021 Banghua Zhao. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
    import AppTrackingTransparency
    import Foundation

    // NEWLY ADDED PERMISSIONS FOR iOS 14
    func requestATTPermission() {
        if #available(iOS 14, *), ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }

//

#endif
