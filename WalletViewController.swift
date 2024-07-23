//
//  WalletViewController.swift
//  BrandedResidence
//
//  Created by Devendra Thakur on 29/02/24.
//  Copyright © 2024 Apple. All rights reserved.
//
// Need to handle success / failed state from SDK
// when succes need to close this view. or in background can close once process will start for add to wallet

import UIKit
import AccessControl
import OrigoSDK
import DVCUtility
import Combine
import SensonicCore
import PassKit
class WalletViewController: BaseViewController {
    @IBOutlet var addToWalletView: UIView!
    @IBOutlet var labelStatus: UILabel!
    @IBOutlet var passIsAdded: UIView!
    @IBOutlet var labelPdassAdde: UILabel!
    @IBOutlet var buttonViewInWallet: UIButton!
    internal var cancellables = [AnyCancellable]()
    @IBOutlet weak var imageBrandLogo: UIImageView!
    var isPassAdded: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        appdelegate.acsManager.delegate = self
        appdelegate.acsManager.validateSDKStatus()
        labelStatus.text = ""
        setBrandLogo()
        passIsAdded.isHidden = true
        addToWalletView.isHidden = true
        buttonViewInWallet.isHidden = true
        self.navigationBar?.headerTitle = "Wallet Setup"
        if Sensonic.shared.appConfig.enableWallet {
            handleWalletStatus()
            handleWalletError()
            showActivity()
            isUserHaveActivePass()
        } else {
            labelStatus.text = "The Wallet feature is currently not available." +
            "Please contact the support team for assistance."
        }
    }
    @IBAction func actionOnCross(_ sender: Any) {
        self.goback()
    }
    @IBAction func passButtonAction (_ sender: Any) {
        if self.isPassAdded {
            switchFromWalletToBLE()
        } else {
            switchFromBLEToWallet()
        }
    }
    @IBAction func viewInWallet (_ sender: Any) {
        if self.isPassAdded {
            switchFromWalletToBLE()
        } else {
            switchFromBLEToWallet()
        }
    }
    deinit {
        appdelegate.acsManager.mobileWalletController?.walletError = nil
        appdelegate.acsManager.mobileWalletController?.setupProgress.passStatus = .none
        cancellables.removeAll()
    }
    func handleWalletStatus() {
        appdelegate.acsManager.mobileWalletController?.$setupProgress.sink { [weak self] status in
            guard let self = self else { return }
            if status.passStatus != .none {
                  switch status.passStatus {
                  case .none: break
                  case .passAdded:
                      DVLogger.log(message: "[MOBILE-WALLET- Pass added", event: .debug)
                      showAlertForPassAdded()
                  case .invalidPass:
                      DVLogger.log(message: "[MOBILE-WALLET- Invalid pass", event: .debug)
                  case .passProcessFailed:
                      DVLogger.log(message: "[MOBILE-WALLET- Pass Process Failed", event: .debug)
                      self.goback()
                  }
            }
        }.store(in: &cancellables)
    }
    func handleWalletError() {
        appdelegate.acsManager.mobileWalletController?.$walletError.sink { [weak self] error in
            guard let self = self else { return }
            if let error, !error.isEmpty {
                DVLogger.log(message: "[MOBILE-WALLET- error:\(String(describing: error))", event: .debug)
                labelStatus.text = error
            }
        }.store(in: &cancellables)
    }
}
extension WalletViewController {
    fileprivate func setBrandLogo() {
        if isThemeAmanOWO {
            imageBrandLogo.image = UIImage(named: "SEOS-by-ASSA-ABLOY-RGB-Black")
        } else {
            imageBrandLogo.image = UIImage(named: "SEOS-by-ASSA-ABLOY-RGB-White")
        }
    }
}

extension WalletViewController {
    func showAlertForPassAdded() {
        Queue.main.execute {
            appdelegate.acsManager.viewState = .walletPassAdded
            self.labelStatus.text = "Congratulations!"
            appdelegate.acsManager.mobileWalletController?.setupProgress.passStatus = .none
            appdelegate.acsManager.resetUserSyncInCSV(activate: true)
            self.goback()
        }
    }
    func goback() {
        Queue.main.execute {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
extension WalletViewController {
    fileprivate func processWithWallet() {
        if Sensonic.shared.appConfig.enableWallet {
            appdelegate.acsManager.viewState = .walletInProgress
            labelStatus.text = "Waiting for token..."
            showActivity()
            addToWalletView.isHidden = true
            appdelegate.acsManager.getWalletInvitationCode { result in
                switch result {
                case .success(let status):
                    if status == false {
                        self.addToWalletView.isHidden = false
                    } else {
                        self.labelStatus.text = "Setup In progress..."
                    }
                case .failure(let error):
                    self.labelStatus.text = error.localizedDescription
                    self.addToWalletView.isHidden = false
                }
                self.removeActivity()
            }
        } else {
            labelStatus.text = "The Wallet feature is currently not available." +
            "Please contact the support team for assistance."
        }
    }
}
extension WalletViewController {
    func switchFromBLEToWallet() {
        if UserDefaults.isHIDKeys &&  UserDefaults.hidSetupIsDoneWithKey {
            appdelegate.acsManager.viewState = .bleToWalletInProgress
            appdelegate.acsManager.logMessage(message: "User have active BLE setup start with deactivate ")
            appdelegate.acsManager.forceTerminateBLE()
            appdelegate.acsManager.deleteDeviceFromACSSystem(deleteToken: appdelegate.apnsToken, withLogout: false) { _ in }
        } else {
            appdelegate.acsManager.logMessage(message: "start with Wallet setup")
            processWithWallet()
        }
    }
    func switchFromWalletToBLE() {
        appdelegate.acsManager.mobileKeyLifeCycle = .bleMode
        appdelegate.acsManager.viewState = .walletToBleStarted
        if self.isPassAdded {
            appdelegate.acsManager.deleteDeviceFromACSSystem(deleteToken: appdelegate.apnsToken, withLogout: false) { _ in
                appdelegate.acsManager.validateSDKStatus()
            }
        } else {
            appdelegate.acsManager.validateSDKStatus()
        }
    }
}
extension WalletViewController: ACSDelegate {
    func bleTerminationProcessDone() {
        processWithWallet()
    }
}
