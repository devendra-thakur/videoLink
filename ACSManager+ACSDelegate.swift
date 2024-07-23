//
//  ACSManager+ACSDelegate.swift
//  BrandedResidence
//
//  Created by Devendra Thakur on 25/06/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import AccessControl
import AccessControlAPI
import DVCUtility
import DVAnalytics
import SensonicCore

extension AccessControlManager: MobileKeyDelegate, LogServiceDelegate {
    func logDetail(parameters: [String: Any]?) {
        guard let parameters else {return}
        let otherInfo =  parameters[LogInfoKey.otherInfo.rawValue] ?? ""
        if var analyticsInfo = parameters[LogInfoKey.logInfo.rawValue] as? [String: Any] {
            analyticsInfo[LogInfoKey.otherInfo.rawValue] = otherInfo
            Queue.background.execute {
                DVAnalytics().logEvent(eventName: Sensonic.CustomEvent.genericEvent.rawValue, parameters: analyticsInfo)
            }
        }
        if let message = parameters[LogInfoKey.message.rawValue] {
            DVLogger.log(message: "[ACS SDK] \(message)-\(otherInfo)", event: .debug)
        }
    }
    func checkForNextDoorType() {
        if waitingForNextDoorType != .none, doorType != waitingForNextDoorType {
            waitingForNextDoorType = .none
            if doorType == .hid {
                logMessage(message: "HID Setup closed now start validating Ving setup")
                doorType = .ving
                mobileKeyController?.doorType = .ving
                mobileKeyController?.validateSeosEndpointSetup()
            } else {
                logMessage(message: "Ving Setup closed now start validating HID setup")
                doorType = .hid
                mobileKeyController?.doorType = .hid
                mobileKeyController?.validateHIDEndpointSetup()
            }
        } else {
            logMessage(message: "Enabled Door type validation closed")
        }
    }
    func hidTokenRequest() {
        logMessage(message: "Get the call for HID Token")
        viewState = .bleInProgress
        getHIDToken { [weak self] code in
            guard let self = self else {return}
            if let code, !code.isEmpty {
                self.mobileKeyController?.validateHIDEndpointSetup()
            }
        }
    }
    func hidKeyRequest(endPointId: UInt) {
        logMessage(message: "Get the call for HID Keys")
        getHIDKeys(containerId: endPointId) { [weak self] status in
            guard let self = self else {return}
            if let status, !status.isEmpty {
                viewState = .hidKeysDone
                self.mobileKeyController?.hidKeyGeneratedSuccessfully()
                self.resetUserSyncInCSV(activate: true)
            }
        }
    }
    func seosTokenRequest() {
        logMessage(message: "Get the call for VING Token")
        getVingCardInvitationCode { [weak self] code in
            guard let self = self else {return}
            if let code, !code.isEmpty {
                self.mobileKeyController?.validateSeosEndpointSetup()
            }
        }
    }
    func seosKeyRequest() {
        logMessage(message: "Get the call for VING Keys")
        getVingCardKey { [weak self] status in
            guard let self = self else {return}
            if let status, !status.isEmpty {
                viewState = .vingKeysDone
                self.mobileKeyController?.seosKeyGeneratedSuccessfully()
                self.resetUserSyncInCSV(activate: true)
            } else {
                viewState = .keyFailed
            }
        }
    }
    func forceDeviceTerminate() {
        mobileKeyController?.terminateEndpoint(withLogout: false)
    }
    func restartAfterClearOldData() {
        logMessage(message: waitingMode.message)
        if doorType != .forceTerminate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                self.validateSDKStatus()
            }
        } else if waitingMode == .waitingForWallet {
            viewState = .walletInProgress
            self.mobileKeyLifeCycle = .walletMode
            self.delegate?.bleTerminationProcessDone()
        }
    }
    func logMessage(message: String) {
        logDetail(parameters: [LogInfoKey.message.rawValue: message,
                               LogInfoKey.doorType.rawValue: doorType.rawValue,
                               LogInfoKey.logType.rawValue: "ACS System"])
    }
}
