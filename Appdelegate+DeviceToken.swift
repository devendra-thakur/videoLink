//
//  Appdelegate+Token.swift
//  BrandedResidence
//
//  Created by Devendra Thakur on 01/07/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import DVCUtility
import SensonicCore
import KeychainSwift
import UIKit

extension AppDelegate {
    var apnsToken: String {
        get {
            guard let token = UserDefaults.standard.string(forKey: Key.apnsToken.rawValue), !token.isEmpty else {
                return ""
            }
            return token
        } set {
            let token = UserDefaults.standard.string(forKey: Key.apnsToken.rawValue)
            if token != newValue {
                UserDefaults.standard.set(newValue, forKey: Key.apnsToken.rawValue)
            }
        }
    }
    // MARK: - Push Notification Register
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        DVLogger.log(message: "********---Device Token: \(token):\(apnsToken)", event: .info)
        if apnsToken.isEmpty {
            registerDeviceToken(action: .save, token: token)
        } else if apnsToken != token {
            apnsToken = token
            UserDefaults.standard.synchronize()
            registerDeviceToken(action: .save, token: token)
        }
    }
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DVLogger.log(message: "Failed to register: \(error)", event: .error)
    }
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if application.applicationState == .inactive || application.applicationState == .background {
            notificationUserInfo = userInfo
            let handler = PushNotificationHandler()
            if !handler.isSilentNotification(userInfo: userInfo) {
                NotificationCenter.default.post(name: NotificationCenter.Names.showTabbarBadge,
                                                object: nil,
                                                userInfo: nil)
            }
        } else {
            appdelegate.openNotificationInfo(userInfo: userInfo)
        }
        completionHandler(.newData)
    }
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                    guard let self = self else {return}
                    DVLogger.log(message: "Permission granted: \(granted)", event: .debug)
                    guard granted else {
                        logFirebaseEvent(parameters: ["log_type": "Permission",
                                                      "log": "Push Notification denied"])
                        self.showNotificationBenefitsMessage()
                        return
                    }
                    self.getNotificationSettings()
                }
    }
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DVLogger.log(message: "Notification settings: \(settings)", event: .debug)
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    func registerDeviceToken(action: DeviceTokenAction,
                             token: String = "") {
        if !Sensonic.shared.isUserSignedIn {
            return
        }
        if !token.isEmpty && Sensonic.shared.isUserSignedIn {
            if !deviceRegistrationInProgress {
                deviceRegistrationInProgress = true
                DVLogger.log(message: "Device Token: \(token) -\(action)", event: .info)
                SensonicCore().deviceTokenAPNS(token: token, action: action) { status, message in
                    Queue.main.execute {
                        DVLogger.log(message:
                                        "Device Token API: \(status) message \(message) action \(action) for token: \(token)",
                                     event:
                                .info)
                        self.deviceRegistrationInProgress = false
                        if status {
                            self.storeApnsToken(token: token)
                        }
                    }
                }
            }
        }
    }
}
extension AppDelegate {
    func storeApnsToken(token: String) {
        self.apnsToken = token
        UserDefaults.standard.synchronize()
        DVLogger.log(message: "token saved: \(self.apnsToken)", event: .debug)
    }
    // MARK: Ask user to provide Notification permission again
    func showNotificationBenefitsMessage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            let message = "Stay informed about new features, updates, and special offers! Enable Push notifications for the best app experience."
            let alert = UIAlertController(title: "Push Notifications", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default))
            alert.addAction(UIAlertAction(title: "Open Setting", style: .default, handler: { _ in
                if let bundleIdentifier = Bundle.main.bundleIdentifier,
                   let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) {
                    if UIApplication.shared.canOpenURL(appSettings) {
                        UIApplication.shared.open(appSettings)
                    }
                }
            }))
            if var topController = UIApplication.shared.window?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                topController.present(alert, animated: true, completion: nil)
            }
        }
    }
}
