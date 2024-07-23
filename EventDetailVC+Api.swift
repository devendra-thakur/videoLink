//
//  EventDetailVC+Api.swift
//  BrandedResidence
//
//  Created by Siddhant Dubey on 16/08/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import EventActivity
import DVCUtility
import SensonicCore
import UIKit
extension EventDetailViewController {
    func getEventDetail() {
        showActivity()
        eventActivity.getEventActivityItemDetail(eventActivityId: self.eventId ?? "",
                                                 completion: { [weak self] result in
            guard let self = self else { return }
            self.removeActivity()
            switch result {
            case .success(let response):
                if let eventDetail = response {
                    self.eventDetail = eventDetail
                    if let isAlreadyBooked = eventDetail.bookingInfo?.isAlreadyBooked, isAlreadyBooked {
                        if let bookingReferenceId = eventDetail.bookingInfo?.bookingReferenceId,
                           !bookingReferenceId.isEmpty {
                            self.isDetailPage = true
                            self.eventBookingId = bookingReferenceId
                        }
                    }
                    if let btnLabel = eventDetail.callToActionLabel, !btnLabel.isEmpty, !self.isDetailPage {
                        self.btnContinue.titleLabel?.numberOfLines = 1
                        self.btnContinue.setTitle(btnLabel, for: .normal)
                        self.btnContinue.titleLabel?.lineBreakMode = NSLineBreakMode.byTruncatingTail
                    } else {
                        if eventDetail.eventType == .reservationOnly {
                            self.btnContinue.setTitle("View Request", for: .normal)
                        } else {
                            self.btnContinue.setTitle("View Tickets", for: .normal)
                        }
                    }
                    self.navigationBar?.headerTitle = eventDetail.title ?? ""
                    self.btnContinue.isHidden = true
                    sendViewItemLog(itemId: eventDetail._id,
                                    itemName: eventDetail.title ?? "", itemCategory: nil,
                                    parentName: ModuleName.eventsActivity.rawValue)
                    self.eventTitleName = eventDetail.title ?? ""
                }
                if self.isDetailPage {
                    self.getEventBookingDetail()
                } else {
                    self.createSnapshot()
                    self.bottomButtonState(eventDetail: self.eventDetail)
                }
            case .failure(let error):
                self.showErrorMessage(error: error)
                DVLogger.log(message: error, event: .error)
            }
        })
    }
    func bottomButtonState(eventDetail: EventActivityInfo?) {
        if eventDetail?.status == .cancelled {
            isEventCancelled = true
            btnContinue.isHidden = true
        }
        if !isEventCancelled {
            if isDetailPage {
                btnContinue.isHidden = false
            } else {
                if let ticketSaleStartDate = eventDetail?.ticketing?.sellingPeriod?.startDate?
                    .getDate(format: DateFormatType.apiFormat.format, withUTC: true) {
                    if let ticketSaleEndDate = eventDetail?.ticketing?.sellingPeriod?.endDate?
                        .getDate(format: DateFormatType.apiFormat.format, withUTC: true) {
                        if !ticketSaleStartDate.isInFuture, !ticketSaleEndDate.isInPast, !isAllSlotsBooked {
                            self.btnContinue.isHidden = false
                        }
                    }
                } else if eventDetail?.eventType == .reservationOnly {
                    if let eventStartDate = eventDetail?.scheduleConfig?.startDate?
                        .getDate(format: DateFormatType.apiFormat.format, withUTC: true),
                        eventStartDate.isInFuture {
                        self.btnContinue.isHidden = false
                    }
                }
            }
        }
    }
    func getEventBookingDetail() {
        showActivity()
        eventActivity.getEventActivityBookingDetail(bookingId: self.eventBookingId ?? "",
                                                    completion: { [weak self] response in
            guard let self = self else { return }
            self.removeActivity()
            switch response {
            case .success(let eventBookingDetail):
                if let bookingDetail = eventBookingDetail {
                    self.eventBookingDetail = bookingDetail
                }
                self.createSnapshot()
                self.bottomButtonState(eventDetail: self.eventDetail)
                sendViewItemLog(itemId: eventBookingDetail?._id,
                                itemName: eventTitleName, itemCategory: nil,
                                parentName: ModuleName.eventsActivity.rawValue)
            case .failure(let error):
                DVLogger.log(message: error, event: .error)
            }
        })
    }
    func getUserBookingStatus() {
        eventActivity.getUserBookingStatus(eventActivityId: eventId ?? "",
                                           completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let bookingStatus):
                if bookingStatus {
                    self.isDetailPage = true
                    self.getEventDetail()
                } else {
                    self.isDetailPage = false
                    self.getEventDetail()
                }
            case .failure(let error):
                self.getEventDetail()
                DVLogger.log(message: error, event: .error)
            }
        })
    }
}
