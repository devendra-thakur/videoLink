//
//  ACSManager+HID.swift
//  BrandedResidence
//
//  Created by Devendra Thakur on 25/06/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import AccessControlAPI
import AccessControl
import SensonicCore
extension AccessControlManager {
    func getHIDToken(completion: @escaping (String?) -> Void) {
        AccessControl().generateHIDToken(devicetoken: appdelegate.apnsToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let invitationCode = response?.invitation, !invitationCode.isEmpty else { return }
                UserDefaults.hidInvitationCode = invitationCode
                mobileKeyController?.setupProgress.endPointStatus = .hidTokenFound
                completion(invitationCode)
            case .failure(let error):
                self.mobileKeyController?.hidEndPointGenerationFailed()
                self.logMessage(message: "invitationCode generate failed with error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    func getHIDKeys(containerId: UInt, completion: @escaping (String?) -> Void) {
        AccessControl().generateHIDKey(devicetoken: appdelegate.apnsToken, ContainerId: containerId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let credential = response?.credential, !credential.isEmpty else { return }
                mobileKeyController?.setupProgress.keyStatus = .done
                completion(credential)
            case .failure(let error):
                self.mobileKeyController?.hidKeyGeneratedFailed()
                self.logMessage(message: "Key generate failed with error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
