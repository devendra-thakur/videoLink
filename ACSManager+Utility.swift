//
//  ACSManager+Utility.swift
//  BrandedResidence
//
//  Created by Devendra Thakur on 26/06/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import DVCUtility
import SensonicCore
import AccessControlAPI
extension AccessControlManager {
    internal func validLifeCycle() -> Bool {
        // Step 1: User Should be logged in
        guard Sensonic.shared.isUserSignedIn else {return false}
        // Step 2: Device Token should be stored
        guard validateAPNSToken() else {return false}
        // Step 3: At least one door feature should be enabled
        switch mobileKeyLifeCycle {
        case .bleMode:
            guard isFeaturesEnabled() else {return false}
        case .walletMode:
            guard walletEnabled() == .wallet else {return false}
        }
        // Step 4: After above validations Controller should be init
        return true
    }
    internal func walletEnabled() -> ACSMode {
        if appdelegate.launchManager.getFeatureByCode(featureCode: .wallet) != nil {
            self.mobileKeyLifeCycle = .walletMode
            return .wallet
        } else {
            return .walletNotEnabled
        }
    }
    // Validate APNs token presence
    internal func validateAPNSToken() -> Bool {
        if !appdelegate.apnsToken.isEmpty {
            return true
        }
        return false
    }
    // Check if features are enabled
    internal func hidFeatureIsEnabled() -> Bool {
        if appdelegate.launchManager.getFeatureByCode(featureCode: .doorLockHID) != nil {
            return true
        }
        return false
    }
    internal func vingFeatureIsEnabled() -> Bool {
        if appdelegate.launchManager.getFeatureByCode(featureCode: .doorLockVingCard) != nil {
            return true
        }
        return false
    }
    internal func isFeaturesEnabled() -> Bool {
        if appdelegate.forceLogoutInProgress {
            return true
        } else {
            let hid = hidFeatureIsEnabled()
            let ving = vingFeatureIsEnabled()
            if hid && ving {
                doorType = .hid
                waitingForNextDoorType = .ving
            } else if hid {
                doorType = .hid
            } else if ving {
                doorType = .ving
            }
            if !hid && !ving {
                skipUserAccessControlAccess = true
            }
            return hid || ving
        }
    }
    func deleteDeviceFromACSSystem(deleteToken: String,
                                   withLogout: Bool,
                                   completion: @escaping (_ status: Bool) -> Void) {
        AccessControl().deleteDevice(devicetoken: deleteToken) { [weak self] result in
            guard let self = self else {return}
            completion(true)
            switch result {
            case .success(let response):
                logMessage(message: "Delete Device Success:\(response)")
                completion(true)
            case .failure(let error):
                logMessage(message: "Delete Device Faield:\(error)")
                completion(false)
            }
        }
    }
    func forceTerminateBLE() {
        if mobileKeyController != nil, bleSetupStarted {
            viewState = .bleKeysDeactivated
            doorType = .forceTerminate
            waitingMode = .waitingForWallet
            mobileKeyController?.doorType = .forceTerminate
            mobileKeyController?.terminateEndpoint(withLogout: false)
        } else {
            waitingMode = .waitingForWallet
            mobileKeyLifeCycle = .bleMode
            doorType = .forceTerminate
            startBLEMode()
        }
    }
    func addSubscriberForProcess() {
        $viewState.sink { status in
            if status != .none {
                let message = status.message()
                Queue.main.execute {
                    if appdelegate.toastView == nil {
                        appdelegate.toastView = NotificationView(title: message, colorStyle: "viewLowNetwork|common")
                        appdelegate.toastView?.show()
                    } else {
                        appdelegate.toastView?.updateMessage(message: message)
                    }
                }
            }
        }.store(in: &cancellables)
    }
    func deviceTokenChangeFound(oldToken: String) {
        // Here need to call the delete device for this token
        doorType = .forceTerminate
        startBLEMode()
        appdelegate.acsManager.deleteDeviceFromACSSystem(deleteToken: oldToken, withLogout: false) { _ in }
    }
    func userIsSyncedInCSV() -> Bool {
        if validLifeCycle(), bleSetupStarted || walletSetupStarted {
            if let date = UserDefaults.standard.value(forKey: Key.userAccessDeined.rawValue) as? Date {
                let currentDate = Date()
                let secondInterval = currentDate.secondsSince(date)
                if secondInterval < csvsyncTime {
                    return false
                }
                resetUserSyncInCSV(activate: false)
                return true
            }
        }
        return true
    }
    func resetUserSyncInCSV(activate: Bool) {
        if activate {
            let date = Date()
            UserDefaults.standard.set(date, forKey: Key.userAccessDeined.rawValue)
        } else {
            UserDefaults.standard.removeObject(forKey: Key.userAccessDeined.rawValue)
        }
        UserDefaults.standard.synchronize()
    }
    func getErrorMessage(_ error: SensonicError) -> String {
        switch error {
        case .customError(let errorCode, _, _):
            return errorCode.message
        default:
            return error.localizedDescription
        }
    }
}
internal enum ACSMode: String {
    case ble = "BLE"
    case wallet = "Wallet"
    case walletNotEnabled = "WalletEnabled"
}
internal enum WaitingMode: String {
    case waitingForWallet = "WaitingForWallet"
    case waitingForBLE = "WaitingForBLE"
    case none = "None"
    var message: String {
        switch self {
        case .waitingForWallet:
            return "Application will auto start setup for Wallet pass"
        case .waitingForBLE:
            return "Application will auto start setup for BLE mode"
        case .none:
            return ""
        }
    }
}
enum ACSSystemProcessStatus: Int {
  case bleModeInprogress = 1
  case bleInProgress
  case hidKeysDone
  case vingKeysDone
  case keyFailed
  case bleToWalletInProgress
  case bleKeysDeactivated
  case walletInProgress
  case walletPassAdded
  case walletToBleStarted
  case walletDeactivated
  case none
  func message() -> String {
    switch self {
    case .bleModeInprogress:
      return "Mobile Keys setup is starting."
    case .bleInProgress:
      return "Mobile Keys setup is in progress..."
    case .hidKeysDone:
      return "Mobile Keys setup is done for HID."
    case .vingKeysDone:
      return "Mobile Keys setup is done for VING."
    case .keyFailed:
      return "Mobile Keys setup failed. Please wait, the app will automatically retry."
    case .bleToWalletInProgress:
      return "Switching mode from BLE to Wallet in progress..."
    case .bleKeysDeactivated:
      return "BLE keys are deactivated. The app will automatically start for Wallet setup."
    case .walletToBleStarted:
      return "Switching mode from Wallet to BLE..."
    case .walletDeactivated:
      return "Wallet is deactivated. The app will automatically start for BLE mode."
    case .walletInProgress:
      return "Wallet setup is in progress..."
    case .walletPassAdded:
      return "Your pass has been successfully added to your wallet\nYou can now access it easily for future use."
    case .none: return ""
    }
  }
}
