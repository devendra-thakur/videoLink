//
//  EventResidentGuestCountModel.swift
//  BrandedResidence
//
//  Created by Siddhant Dubey on 25/08/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import EventActivity
import SensonicCore
struct ResidentGuestCount: Hashable {
    var title: String = ""
    var type: AttendeeType?
    var value: Int?
    var minimumCount: Int = 0
    var maximumCount: Int = 0
    var showError: Bool = false
    var errorMessage: String = ""
}
enum AttendeeType {
    case resident
    case guest
    case ticket   // In case of general
    case attendee // In case of rsvp
}

func filterTotalBookedObject(eventDetail: EventActivityInfo?) -> (totalPrimaryCount: Int, totalGuestCount: Int) {
    guard let eventDetail = eventDetail else { return (0, 0) }
    let userType = Sensonic.shared.requestUserAppType
    if let isAdvanced = eventDetail.ticketing?.isAdvanced,
       isAdvanced {
        if let totalBooked = eventDetail.bookingInfo?.totalBooked?
            .filter({$0?.bookedForType?.rawValue == userType.rawValue}).first {
            if let totalBookedObj = totalBooked {
                let totalPrimaryCount = totalBookedObj.totalPrimaryCount ?? 0
                let totalGuestCount = totalBookedObj.totalGuestCount ?? 0
                return (totalPrimaryCount, totalGuestCount)
            }
        }
    } else {
        var totalPrimaryCount = 0
        var totalGuestCount = 0
        _ = eventDetail.bookingInfo?.totalBooked?.compactMap({ obj in
            let primaryCount = obj?.totalPrimaryCount ?? 0
            let guestCount = obj?.totalGuestCount ?? 0
            totalPrimaryCount += primaryCount
            totalGuestCount += guestCount
        })
        return (totalPrimaryCount, totalGuestCount)
    }
    return (0, 0)
}
