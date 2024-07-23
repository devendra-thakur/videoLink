//
//  EventDetailViewController.swift
//  BrandedResidence
//
//  Created by Siddhant Dubey on 14/08/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import EventActivity
import SensonicCore
import DVCUtility
class EventDetailViewController: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnContinue: UIButton!
    lazy var datasource = configureDatasource()
    var eventActivity = EventActivity()
    var eventId: String?          // to get the id value from HomeViewController
    var eventBookingId: String?
    var eventDetail: EventActivityInfo?
    var eventBookingDetail: EventActivityBookingInfo?
    var isAllSlotsBooked = false
    var isDetailPage = false
    var callBackDismiss: (Bool) -> Void = {_ in }
    var fromDeepLink = false
    var isEventCancelled = false
    var eventTitleName: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar?.headerTitle = " "
        collectionView.contentInset.bottom = 30
        registerCells()
        collectionView.collectionViewLayout = createLayout()
        btnContinue.isHidden = true
        getEventDetail()
        sendFirebaseLog(moduleName: .eventsActivity)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? EventCarouselCell {
            if let cell = cell.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? CarouselImageCell {
                cell.videoYouTube.pause()
                if cell.isPlayerStarted {
                    cell.player.pause()
                }
            }
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }
    func openEventTicketBookingVC() {
        guard let eventTicketBookingVC = EventTicketBookingViewController
            .instantiate(storyboard: StoryboardId.eventsActivity.rawValue) else {return}
        eventTicketBookingVC.eventDetail = self.eventDetail
        eventTicketBookingVC.eventBookingDetail = self.eventBookingDetail
        eventTicketBookingVC.isDetailPage = self.isDetailPage
        eventTicketBookingVC.eventBookingId = self.eventBookingId
        self.navigationController?.pushViewController(viewController:
                                                        eventTicketBookingVC, animated: true, completion: nil)
    }
    func openTicketBookingPopup() {
        guard let eventTicketBookingPopup = TicketBookingPopupViewController
            .instantiate(storyboard: StoryboardId.eventsActivity.rawValue) else {return}
        eventTicketBookingPopup.eventDetail = self.eventDetail
        eventTicketBookingPopup.isDetailPage = isDetailPage
        eventTicketBookingPopup.eventBookingDetail = eventBookingDetail
        eventTicketBookingPopup.eventBookingId = eventBookingId
        eventTicketBookingPopup.callBackPresentConfirmation = { [weak self] isFromUpdate, cancelEvent in
            guard let self = self else { return }
            guard let eventBookingConfirmationVC = EventBookingConfirmationViewController
                .instantiate(storyboard: StoryboardId.eventsActivity.rawValue) else {return}
            eventBookingConfirmationVC.eventDetail = self.eventDetail
            eventBookingConfirmationVC.isCancelEvent = cancelEvent
            eventBookingConfirmationVC.isFromUpdate = isFromUpdate
            self.navigationController?.pushViewController(viewController: eventBookingConfirmationVC,
                                                          animated: true, completion: nil)
        }
        self.present(eventTicketBookingPopup, animated: true)
    }
    @IBAction func actionOnBtnContinue(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.bounceAnimation(completion: {
            sender.isUserInteractionEnabled = true
            if self.eventDetail?.eventType == .freeBookingTickets ||
                self.eventDetail?.eventType == .reservationOnly {
                if let terms = self.eventDetail?.termsAndConditions,
                   !terms.isEmpty {
                    self.openEventTicketBookingVC()
                } else {
                    self.openTicketBookingPopup()
                }
            } else {
                self.openEventTicketBookingVC()
            }
        })
    }
    func ticketSaleStatus(startDate: Date, endDate: Date) -> String {
        var calendar: Calendar {
            return Calendar(identifier: Calendar.current.identifier)
        }
        var primaryCapacity = 0
        if eventDetail?.ticketing?.isAdvanced == true {
            if let advacedTicketing = eventDetail?.ticketing?.advancedTicketing?.first {
                primaryCapacity = advacedTicketing?.capacity ?? 0
            }
        } else {
            if let generalTicketing = eventDetail?.ticketing?.generalTicketing {
                primaryCapacity = generalTicketing.capacity ?? 0
            }
        }
        if primaryCapacity == filterTotalBookedObject(eventDetail: eventDetail).totalPrimaryCount {
            isAllSlotsBooked = true
            btnContinue.isHidden = true
        }
        if isEventCancelled {
            return "This event has been cancelled"
        } else {
            if isAllSlotsBooked {
                return "Event sold out"
            }
            if startDate.isInFuture {
                let timeDifference = Date().timeDifferenceDivision(targetedDate: startDate)
                return "Ticket sale start in \(timeDifference)"
            } else if startDate.isInPast {
                if endDate.isInFuture {
                    let timeDifference = Date().timeDifferenceDivision(targetedDate: endDate)
                    return "Ticket sale end in \(timeDifference)"
                } else {
                    self.btnContinue.isHidden = true
                    return "Ticket sale ended"
                }
            }
        }
        return ""
    }
    func configFewSpotsLeft() -> Bool {
        var totalPrimaryBooked = 0
        var totalGuestBooked = 0
        var totalBooked = 0
        if eventDetail?.eventType != .reservationOnly, !isDetailPage {
            _ = eventDetail?.bookingInfo?.totalBooked?.compactMap({ object in
                totalPrimaryBooked += object?.totalPrimaryCount ?? 0
                totalGuestBooked += object?.totalGuestCount ?? 0
            })
            totalBooked = totalPrimaryBooked + totalGuestBooked
            let totalCapacity = eventDetail?.bookingInfo?.totalCapacity ?? 0
            let percentBooked = (Double(totalBooked) / Double(totalCapacity)) * 100
            var primaryCapacity = 0
            if eventDetail?.ticketing?.isAdvanced == true {
                if let advacedTicketing = eventDetail?.ticketing?.advancedTicketing?.first {
                    primaryCapacity = advacedTicketing?.capacity ?? 0
                }
            } else {
                if let generalTicketing = eventDetail?.ticketing?.generalTicketing {
                    primaryCapacity = generalTicketing.capacity ?? 0
                }
            }
            if primaryCapacity == filterTotalBookedObject(eventDetail: eventDetail).totalPrimaryCount {
                return false
            }
            if Int(percentBooked) == 100 {
                isAllSlotsBooked = true
                if !isDetailPage {
                    self.btnContinue.isHidden = true
                }
                return false
            } else if Int(percentBooked) >= 90,
                      Int(percentBooked) < 100 {
                isAllSlotsBooked = false
                if let ticketSaleStartDate = eventDetail?.ticketing?.sellingPeriod?.endDate?
                    .getDate(format: DateFormatType.apiFormat.format, withUTC: true), ticketSaleStartDate.isInPast {
                    return false
                }
                return true
            }
        }
        return false
    }
}
