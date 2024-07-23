//
//  SceneDelegate.swift
//  BrandedResidence
//
//  Created by Apple on 07/11/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import UIKITExtension
import CoreSpotlight
import Combine
import DVCUtility
import SensonicCore
import AppManagement
import Amenity
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var overlayView: OverlayView?
    internal var cancellables: Set<AnyCancellable> = []
    var isEnableGuestRequest = false
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        UNUserNotificationCenter.current().delegate = self
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(scene, continue: userActivity)
        } else {
            checkURLContextAndNavigate(urlContext: connectionOptions.urlContexts)
        }
        handledNotificationType()
        toastSetup()
        uiAppearance()
        appdelegate.launchManager.startApp()
        // MARK: Required a common call When app launch or user login
    }
    func toastSetup() {
        ToastManager.shared.queueEnabled = true
        ToastManager.shared.duration = 3.0
        ToastManager.shared.position = .center
        ToastManager.shared.tapToDismissEnabled = false
    }
    func uiAppearance() {
        Queue.main.execute {
            let demoView = UIView()
            demoView.colorStyle = "brandTint|generic"
            UITextField.appearance().tintColor = demoView.tintColor
            UITextView.appearance().tintColor = demoView.tintColor
            UILabel.appearance(whenContainedInInstancesOf: [UIDatePicker.self]).textColor = UIColor.white
        }
    }
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        checkURLContextAndNavigate(urlContext: URLContexts)
    }
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo,
               let activityURL = userInfo[CSSearchableItemActivityIdentifier] as? String {
                let arrayComponent = activityURL.split(separator: ".")
                let typeIDComponent = arrayComponent.last?.split(separator: "_")
                if arrayComponent.contains("book"), let itemID = Int(typeIDComponent?.last ?? ""),
                   let type = typeIDComponent?.first {
                    switch type {
                    case "category":
                        openBookingView(itemID: itemID)
                    case "item":
                        openBookingSubview(itemID: itemID)
                    default: break
                    }
                }
            }
        } else if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            DVLogger.log(message: url.absoluteString, event: .debug)
            /* Need to finalise shortlink domains */
            let handler = PushNotificationHandler()
            if url.absoluteString.contains("btler.app") {
                handler.redirectURL(url: url)
                return
            }
            let param = handler.queryParameters(from: url)
            DVLogger.log(message: param ?? "", event: .info)
        }
    }
    func sceneDidDisconnect(_ scene: UIScene) {
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        if Sensonic.shared.isUserSignedIn && Sensonic.shared.isActiveUser {
            if appdelegate.apnsToken.isEmpty {
                appdelegate.registerForPushNotifications()
            } else {
                UIApplication.shared.applicationIconBadgeNumber = 0
                DispatchQueue.main.asyncAfter(deadline: .now()+20) {
                    appdelegate.registerDeviceToken(action: .clearBadge, token: appdelegate.apnsToken)
                }
            }
        }
        removeOverlayView()
    }
    func sceneWillResignActive(_ scene: UIScene) {
        UserDefaults.standard.setValue((appdelegate.appLayoutType == .layout1), forKey: Key.appLayoutTab.rawValue)
        if appdelegate.lastLayoutChangeTime == nil {
            appdelegate.lastLayoutChangeTime = Date().timeIntervalSince1970
        }
        if let loginVC = UIApplication.shared.lastViewController {
            loginVC.view.endEditing(true)
        }
        showOverlayView()
    }
    func sceneWillEnterForeground(_ scene: UIScene) {
        if appdelegate.launchManager.appProfile != nil {
            appdelegate.launchManager.checkAcceptedPrivacyPolicy()
        }
        appdelegate.networkTest.apiCallTime = 2.0
        appdelegate.networkTest.networkSpeedTestStart(withUrl: "https://api.digivalet.app/")
        appdelegate.networkTest.liveNetworkTrackerStart(avoidnextCallForSec: 0.0)
        if Sensonic.shared.isUserSignedIn {
            if DVCUtility.isNetworkAvailable {
                if let timeStamp = appdelegate.lastLayoutChangeTime {
                    let timeDifference = Date().timeIntervalSince1970 - timeStamp
                    if timeDifference >= 40 {
                        appdelegate.launchManager.checkAppVersion() // For Force update notification
                        appdelegate.launchManager.acknowledgementOfMessage()
                        appdelegate.launchManager.sensonicConfiguration(withAPiCall: true)
                        appdelegate.launchManager.getApplicationLayoutFirstTime { _ in
                            NotificationCenter.default.post(name: NotificationCenter.Names.appLayoutReferesh,
                                                            object: nil, userInfo: ["requiredAppRefresh": true])
                        }
                    }
                }
            }
        }
    }
    func sceneDidEnterBackground(_ scene: UIScene) {
        appdelegate.networkTest.networkSpeedTestStop()
        appdelegate.networkTest.liveNetworkTrackerStop()
    }
    private func showOverlayView() {
        guard let window = window else { return }
        if overlayView == nil {
            overlayView = OverlayView(frame: window.bounds)
        }
        window.addSubview(overlayView!)
    }
    private func removeOverlayView() {
        overlayView?.removeFromSuperview()
    }
}
