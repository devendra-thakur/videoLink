//
//  File.swift
//  
//
//  Created by Apple on 16/01/21.
//

import Foundation

public enum DateTimeSelectionViewType: String {
    case dateSelection // Show only Calendar without Top header
    case repeatOnly // Show repeat selection view with header
    case repeatDaily // show repeat view with daily option
    case repeatWeekly // show repeat view with weekly option
    case repeatMonthly // show repeat view with monthly option
    case timeSelection // show repeat view with time selection

    public var text: String {
        switch self {
        case .dateSelection:
            return ""
        case .repeatOnly:
            return "Repeat"
        case .repeatDaily:
            return "Custom"
        case .repeatWeekly:
            return "Custom"
        case .repeatMonthly:
            return "Custom"
        case .timeSelection:
            return "Time"
        }
    }
}
public enum ViewAnimationType: String {
    case fromLeft
    case fromRight
    case fromTop
    case fromBottom
}

/// Country filtering options
public enum CountryFilterOption {
    case countryName
    case countryCode
    case countryDialCode
}

/// Repeat View - Schedule Type
enum RepeatSegementType: String {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

/// Day Name Enum to show Day name
/// Week starting from SUN
enum DaysName: String, CaseIterable {
    case sunday = "0"
    case monday = "1"
    case tuesday = "2"
    case wednesday = "3"
    case thursday = "4"
    case friday = "5"
    case saturday = "6"
    var shortName: String {
        switch self {
        case .sunday:
            return "Sun"
        case .monday:
            return "Mon"
        case .tuesday:
            return "Tue"
        case .wednesday:
            return "Wed"
        case .thursday:
            return "Thu"
        case .friday:
            return "Fri"
        case .saturday:
            return "Sat"
        }
    }
    var fullName: String {
        switch self {
        case .sunday:
            return "Sunday"
        case .monday:
            return "Monday"
        case .tuesday:
            return "Tuesday"
        case .wednesday:
            return "Wednesday"
        case .thursday:
            return "Thursday"
        case .friday:
            return "Friday"
        case .saturday:
            return "Saturday"
        }
    }
    var dayIndex: String {
        switch self {
        case .sunday:
            return "0"
        case .monday:
            return "1"
        case .tuesday:
            return "2"
        case .wednesday:
            return "3"
        case .thursday:
            return "4"
        case .friday:
            return "5"
        case .saturday:
            return "6"
        }
    }
}
enum DaysIndex: String, CaseIterable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    var shortName: String {
        switch self {
        case .sunday:
            return "0"
        case .monday:
            return "1"
        case .tuesday:
            return "2"
        case .wednesday:
            return "3"
        case .thursday:
            return "4"
        case .friday:
            return "5"
        case .saturday:
            return "6"
        }
    }
}
/// Week of a Month
enum WeekOfMonth: Int, CaseIterable {
    case firstWeek = 0
    case secondWeek
    case thirdWeek
    case fourthWeek
    var displayName: String {
        switch self {
        case .firstWeek:
            return "1st week"
        case .secondWeek:
            return "2nd week"
        case .thirdWeek:
            return "3rd week"
        case .fourthWeek:
            return "4th week"
        }
    }
    var shorName: String {
        switch self {
        case .firstWeek:
            return "1st"
        case .secondWeek:
            return "2nd"
        case .thirdWeek:
            return "3rd"
        case .fourthWeek:
            return "4th"
        }
    }
}
enum IntegratorCode: String {
    case flx = "SESSION_MANAGEMENT_WELLNESS"
}
// FIXME: - replace these values with the dynamic values from API
enum VehicleType: String {
  case car
  case bike
  case bicycle
}
enum Key: String {
    case updateBadge = "notificationBadgeUpdate"
    case messageUpdateBadge = "messageUpdateBadge"
    case featureName = "featureName"
    case featureCode = "featureCode"
    case policyVersion = "policyVersion"
    case policyUrl = "policyUrl"
    case acceptPolicy = "isAcceptPrivacyPolicy"
    case secondLogin = "isSecondLogin"
    case appUpdateOptional = "AppUpdateForOptional"
    case dNDActivate = "isDNDActivate"
    case voipToken = "VOIP_TOKEN"
    case apnsToken = "APNS_TOKEN_IN_APP"
    case jwtToken = "DV_JWT_SCHINDLER"
    case jwtTokenExpiresAt = "DV_JWT_SCHINDLER_EXPIRESAT"
    case userAccessDeined = "validateUserAccessToDoorLock"
    case buildHardResetDone = "APNS_TOKEN_FORCE_RESET_REQUIRED"
    case usrelaunchedOnLayout1 = "usrelaunchedOnLayout1"
    case appLayoutTab = "appLayout1"
}
// FIXME: Need to move those Date formats in DVCUtility
enum DateFormatTypeLocal: String {
    case dayMonthName = "EEE, MMM, dd, yyyy"
    case fullDayMonthName = "EEEE, MMM dd, yyyy"
}
