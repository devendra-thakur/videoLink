//
//  AccessControlTimeCell.swift
//  BrandedResidence
//
//  Created by Siddhant Dubey on 15/03/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit

class AccessControlTimeCell: UICollectionViewCell {
    @IBOutlet weak var labelWaiting: UILabel!
    weak var parentView: AccessControlViewController?
    private var timer: Timer?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        showRemainingTime(withTimer: true)
    }
    func showRemainingTime(withTimer: Bool) {
        if let date = UserDefaults.standard.value(forKey: Key.userAccessDeined.rawValue) as? Date {
            let currentDate = Date()
            let minInterval = currentDate.minutesSince(date)
            if minInterval < appdelegate.acsManager.csvsyncTime {
                let minute = appdelegate.acsManager.csvsyncTime - minInterval
                labelWaiting.text = "Please wait \(minute) minutes to sync your keys"
                if withTimer {
                    syncTime()
                }
            } else {
                appdelegate.acsManager.resetUserSyncInCSV(activate: false)
                labelWaiting.text = ""
                removeTimer()
            }
        } else {
            removeTimer()
        }
    }
    func syncTime() {
            timer =  Timer.scheduledTimer(timeInterval: 15.0,
                                         target: self,
                                         selector: #selector(timerTriggered),
                                         userInfo: nil,
                                         repeats: true)
    }
    @objc func timerTriggered() {
        showRemainingTime(withTimer: false)
    }
   func removeTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        if let parent = parentView {
           parent.applySnapshot()
        }
    }
    deinit {
        removeTimer()
    }
}
