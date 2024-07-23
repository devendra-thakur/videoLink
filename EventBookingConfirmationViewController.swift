//
//  EventBookingConfirmationViewController.swift
//  BrandedResidence
//
//  Created by Siddhant Dubey on 21/08/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import EventActivity
import SensonicCore

class EventBookingConfirmationViewController: BaseViewController {
    @IBOutlet weak var labelSuccessHeader: UILabel!
    @IBOutlet weak var labelSuccessMsg: UILabel!
    @IBOutlet weak var imageConfirmation: UIImageView!
    @IBOutlet weak var viewDefaultImage: UIView!
    @IBOutlet weak var viewPrimaryImage: UIView!
    @IBOutlet weak var imageDefault: UIImageView!
    @IBOutlet weak var imageDefaultLarge: UIImageView!
    @IBOutlet weak var viewSubDefaultBg: UIView!
    @IBOutlet weak var imageViewAman: UIImageView!
    var eventDetail: EventActivityInfo?
    var isCancelEvent = false
    var isFromUpdate = false
    override func viewDidLoad() {
        super.viewDidLoad()
        setImage()
        configMessages()
        let currentTheme = UIApplication.shared.currentTheme
        if currentTheme == .owo {
            imageDefault.isHidden = true
            imageDefaultLarge.isHidden = false
            imageViewAman.isHidden = true
        } else if currentTheme == .aman {
            imageDefault.isHidden = true
            imageDefaultLarge.isHidden = true
            imageViewAman.isHidden = false
            viewSubDefaultBg.backgroundColor = .clear
        } else {
            imageDefault.isHidden = false
            imageDefaultLarge.isHidden = true
            imageViewAman.isHidden = true
        }
        if isFromUpdate {
            sendFirebaseLog(moduleName: .eventsActivity, screenType: .update)
        } else {
            sendFirebaseLog(moduleName: .eventsActivity, screenType: .confirm)
        }
    }
    @IBAction func actionOnDone(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.bounceAnimation(completion: {
            sender.isUserInteractionEnabled = true
            self.redirectToBookTab()
        })
    }
    @IBAction func actionOnBack(_ sender: Any) {
        redirectToBookTab()
    }
    func setImage() {
        if let url = eventDetail?.attachment?.primaryImage, !url.isEmpty {
            SensonicCore().downloadThumbImage(imageUrl: url,
                                              size: CGSize(width: self.imageConfirmation.frame.width,
                                                           height: self.imageConfirmation.frame.height)) {image, _ in
                DispatchQueue.main.async {[weak self] in
                    guard let self = self else {return}
                    if let image = image {
                        self.viewPrimaryImage.isHidden = false
                        self.viewDefaultImage.isHidden = true
                        self.imageDefaultLarge.isHidden = true
                        self.imageConfirmation.image = image
                        self.imageViewAman.isHidden = true
                    } else {
                        self.viewPrimaryImage.isHidden = true
                        self.viewDefaultImage.isHidden = false
                        self.imageViewAman.isHidden = false
                        if self.isCancelEvent {
                            self.imageDefault.image = .checkCircle
                            self.imageDefaultLarge.image = .checkCircle
                            self.imageViewAman.image = .checkCircle
                        } else {
                            self.imageDefault.image = .noEventCalender
                            self.imageDefaultLarge.image = .noEventCalender
                            self.imageViewAman.image = .noEventCalender
                        }
                    }
                }
            }
        } else {
            self.viewPrimaryImage.isHidden = true
            self.viewDefaultImage.isHidden = false
            self.imageViewAman.isHidden = true
            if isCancelEvent {
                self.imageDefault.image = .checkCircle
                self.imageDefaultLarge.image = .checkCircle
                self.imageViewAman.image = .checkCircle
            } else {
                self.imageDefault.image = .noEventCalender
                self.imageDefaultLarge.image = .noEventCalender
                self.imageViewAman.image = .noEventCalender
            }
        }
    }
    func configMessages() {
        if isFromUpdate {
            if isCancelEvent {
                labelSuccessHeader.text = "Registration Cancelled"
                let subDescription = "If you wish to make any new requests, please head to Book."
                labelSuccessMsg.text = "Your request has been removed from your calendar. \(subDescription)"
            } else {
                labelSuccessHeader.text = "Registration Updated"
                labelSuccessMsg.text = eventDetail?.bookingUpdateSuccessMessage
            }
        } else {
            labelSuccessHeader.text = "Registration Complete"
            labelSuccessMsg.text = eventDetail?.bookingSuccessMessage
        }
    }
    func redirectToBookTab() {
        APIName.getResidentAllEvents.updatePolicy(isUpdate: false)
        if let tabTitle = UserDefaults.standard.string(forKey: Key.featureName.rawValue) {
            if tabTitle.lowercased() == "home" || tabTitle.lowercased() == "upcoming" {
                NotificationCenter.default.post(name: NotificationCenter.Names.tabbarChangeEvent,
                                                object: nil,
                                                userInfo: ["code": FeatureCode.home.rawValue])
            } else {
//                NotificationCenter.default.post(name: NotificationCenter.Names.tabbarChangeEvent,
//                                                object: nil,
//                                                userInfo: ["code": FeatureCode.book.rawValue])
            }
        } else {
//            NotificationCenter.default.post(name: NotificationCenter.Names.tabbarChangeEvent,
//                                            object: nil,
//                                            userInfo: ["code": FeatureCode.book.rawValue])
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
}
