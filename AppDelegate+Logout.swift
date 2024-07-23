//
//  AppDelegate+Logout.swift
//  BrandedResidence
//
//  Created by Devendra Thakur on 05/08/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import DVCUtility
import UIKit
import SensonicCore
import SessionManagement
extension AppDelegate {
    func test() {
        let array: [String] = []
        print("\(array.first)")
    }
    @objc func forceLogout(isForceLogout: Bool = false) {
        if DVCUtility.isNetworkAvailable {
            if isForceLogout {
                forceLogoutInProgress = true
                Queue.main.execute {
                    UIApplication.shared.lastViewController?.showActionSheet(description:
                    "Your session has expired. Please log in again to continue.",
                    destructiveCancel: false, cancelTitle: "OK")
                }
            }
            UIApplication.shared.lastViewController?.showActivityOnWindow()
            SensonicAuth().logoutUser(deviceToken: apnsToken) { [weak self] status, message in
                guard let self = self else {return}
                DVLogger.log(message: status, event: .debug)
                self.stepToRemoveUserOfflineDataOnLogout()
            }
            deleteDeviceOnLogout()
        } else {
            forceLogoutInProgress = false
            UIApplication.shared.lastViewController?.removeActivityFromWindow()
            UIApplication.shared.lastViewController?.showErrorMessage(error: .noNetwork)
        }
    }
}
extension AppDelegate {
    func stepToRemoveUserOfflineDataOnLogout() {
        Queue.main.execute { [weak self] in
            guard let self = self else {return}
            UIApplication.shared.rootViewController?.removeActivityFromWindow()
            acsManager.resetOnLogout()
            Sensonic.shared.isActiveUser = true
            SensonicAuth().forceResetAPICache()
            SensonicAuth().logout()
            self.appLayoutType = .layout3
            launchManager.appProfile = nil
            launchManager.currentRetryCount = 0
            launchManager.shouldReloadTabbar = true
            SessionManagement().flxrequestHolder.resetAll()
            SessionManagement().flxrequestHolder.userTpye = .none
            UserDefaults.standard.removeObject(forKey: Key.apnsToken.rawValue)
            UserDefaults.standard.removeObject(forKey: Key.jwtToken.rawValue)
            UserDefaults.standard.removeObject(forKey: Key.userAccessDeined.rawValue)
            UserDefaults.standard.removeObject(forKey: Key.usrelaunchedOnLayout1.rawValue)
            UserDefaults.standard.synchronize()
            UIApplication.shared.rootViewController?.pushToLoginView()
        }
    }
}
