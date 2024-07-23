//
//  Today+CollectionDelegate.swift
//  BrandedResidence
//
//  Created by Devendra Thakur on 05/10/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import Service
import DVCUtility
import UIKITExtension
import Collator
import Amenity
import Outlet
import SensonicCore
import SessionManagement
import AppManagement
import EventActivity

extension HomeViewController {

    func didselectEventActivity(_ indexPath: IndexPath,
                                _ event: EventActivityInfo) {
        if let cell = collectionView.cellForItem(at: indexPath) as? UpcomingExploreCell {
            cell.isUserInteractionEnabled = false
            cell.bounceAnimation(completion: {
                cell.isUserInteractionEnabled = true
                self.openEventDetailVC(eventId: event._id ?? "")
            })
        }
    }

    func didSelectExplore(_ indexPath: IndexPath,
                          _ exploreItem: BookCategory) {
        if let cell = collectionView.cellForItem(at: indexPath) as? UpcomingExploreCell {
            cell.isUserInteractionEnabled = false
            cell.bounceAnimation(completion: {
                cell.isUserInteractionEnabled = true
                self.didSelectExplore(exploreItem)
            })
        }
    }

    func didSelectToday(_ indexPath: IndexPath, _ event: ResidentEvent?) {
//        if arrayUpcomingBookings.count > indexPath.section {
            if let item = event {
                if item.bookingParent == .serviceRequest {
                    openServiceView(item: item)
                } else if item.bookingParent == .amenity {
                    openAmenityView(item: item)
                } else if item.bookingParent == .visitor {
                    if let eventType = event?.additionalInfo?["visitType"],
                        let visitType = eventType as? String, visitType == "PARTY_MODE" {
                        guard let partyModeReviewVC = PartyModeReviewViewController
                            .instantiate(storyboard: StoryboardId.visitor.rawValue) else {return}
                        partyModeReviewVC.bookingId = event?._id
                        partyModeReviewVC.eventReviewFlow = .isViewOnly
                        switch item.currentState {
                        case .verifying, .denied, .cancelled, .completed, .lapsed, .inProgress:
                            partyModeReviewVC.eventReviewFlow = .disabled
                        case .some(_), .none:
                            partyModeReviewVC.eventReviewFlow = .isViewOnly
                        }
                        self.navigationController?.pushViewController(viewController:
                                                                        partyModeReviewVC,
                                                                      animated: true, completion: nil)
                    } else {
                        openGuestDetailScreen(bookingId: event?._id ?? "")
                    }
                } else if item.bookingParent == .parcel {
                    openParcelDetailScreen(bookingId: event?.bookingParentId ?? "")
                } else if item.bookingParent == .outlet {
                    openOutletOrderDetailView(item: item)
                } else if item.bookingParent == .integration,
                          item.integratorCode ?? "" == IntegratorCode.flx.rawValue {
                    openFlxClassDetail(item: item)
                } else if item.bookingParent == .outletReservation {
                    openOutletReservation(item: item)
                } else if item.bookingParent == .eventActivity {
                    openEventDetailVC(eventId: item.bookingParentId,
                                      bookingId: item.bookingReferenceId)
                }
            }
//        }
    }

    fileprivate func openAccessFeatures(_ itemFeature: Feature) {
        if itemFeature.featureCode == .wallet {
            self.openTappedFeature(code: itemFeature)
        } else {
            if appdelegate.acsManager.userIsSyncedInCSV() {
                self.openTappedFeature(code: itemFeature)
            } else {
                if let date = UserDefaults.standard.value(forKey: Key.userAccessDeined.rawValue) as? Date {
                    let currentDate = Date()
                    let minInterval = currentDate.minutesSince(date)
                    if minInterval < appdelegate.acsManager.csvsyncTime {
                        let minute = appdelegate.acsManager.csvsyncTime - minInterval
                        self.showErrorMessage(otherMessage: "Please wait for \(minute) minutes")
                    }
                }
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if !DVCUtility.isNetworkAvailable {
          self.showErrorMessage(error: SensonicError.noNetwork)
          return
        }
        guard let item = upcomingDataSource?.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .upcomingEventRow(event: let event):
            self.didSelectToday(indexPath, event)
        case .actionableEvent(event: let event):
            if event?.bookingParent == .parcel {
                openParcelRequestScreen(bookingId: event?._id ?? "", notificationId: "", uniqueParcelId: "")
            } else {
                openGuestRequestScreen(bookingId: event?._id ?? "", notificationId: "", uniqueGroupId: "")
            }
        case .eventActivity(event: let event):
            self.didselectEventActivity(indexPath, event)
        case .blogs(let feature):
            openBlogsViewController(indexPath, feature: feature)
        case .more:
            moreScreenRedirection()
        case .noBookings:
            DVLogger.log(message: "", event: .debug)
        case .welcomeMessage:
            DVLogger.log(message: "", event: .debug)
        case .brandLogo:
            DVLogger.log(message: "", event: .debug)
        case .explore(exploreItem: let exploreItem):
            self.didSelectExplore(indexPath, exploreItem)
        case .favourites(let fav):
            let itemsCount = upcomingDataSource?.snapshot().numberOfItems(inSection: .favourites)
            if (indexPath.item + 1) == itemsCount {
                self.openFavouriteView()
            } else {
                openControllers(withItemIdentifier: fav)
                self.isFavChanged = true
            }
           // FIXME: - need to add redirection for parcel and visitor
        case .moreActionableEvent:
            NotificationCenter.default.post(name: NotificationCenter.Names.tabbarChangeEvent,
                                            object: nil, userInfo: ["code": FeatureCode.activity.rawValue])
            NotificationCenter.default.post(name: NotificationCenter.Names.didSetNotificationTab,
                                            object: nil,
                                            userInfo: nil)
        case .feedItem(let itemFeed):
            self.openFeedDetailViewController(item: itemFeed)
        case .feedIndicatorRow:
            break
        case .accessFeatures(itemFeature: let itemFeature):
            openAccessFeatures(itemFeature)
        }
    }
    func openBlogsViewController(_ indexPath: IndexPath, feature: Feature) {
        if let cell = collectionView.cellForItem(at: indexPath) as? BlogsItemCell {
             cell.isUserInteractionEnabled = false
             cell.bounceAnimation(completion: {
                 cell.isUserInteractionEnabled = true
                 self.blogScreenRedirection(feature: feature)
             })
         }
    }

    func didSelectExplore(_ item: BookCategory) {
        if let exploreItem = item.items?.first, let exploreId = exploreItem?._id {
            switch exploreItem?.type {
            case .amenity:
                openAmenityFromExplore(amenityId: exploreId)
            case .service:
                openServiceFromExplore(serviceID: exploreId)
            case .parcel, .parcelManagement:
                openParcelFromExplore(parcelID: exploreId)
            case .visitor:
                openVisitorFromExplore(visitorID: exploreId)
            case .outlet:
                openOutletFromExplore(outletID: exploreId)
            default:
                DVLogger.log(message: "item type is: \(String(describing: exploreItem?.type)) not handled now",
                             event: .debug)
            }
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Put Animation On Header
        if collectionView.contentSize.height < collectionView.frame.height {
            return
        }
        if collectionView.contentOffset.y < 0 {
            navigationBar?.isHidden = true
            viewTopHeader.isHidden = false
        } else {
            navigationBar?.isHidden = false
            viewTopHeader.isHidden = true
        }
    }

    func checkEditModeForMultiCapBooking(eventItem: ResidentEvent?) -> Bool {
        if let recipients = self.amenity.requestHolder.recipients, !recipients.isEmpty {
            if let loginUserId = Sensonic.shared.requestUserId, loginUserId != eventItem?.bookedForId ?? "" {
                return true
            }
            return false
        }
        return false
    }
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView,
                        forElementKind elementKind: String, at indexPath: IndexPath) {
        if !applyingData {
            if elementKind == InterestsHeader.reuseIdentifier {
                let initialProperty = AnimationProperty(alpha: 0)
                let param = AnimationParameter.init(yDisplacement: 10, xDisplacement: 0,
                                                    initialProperty: initialProperty)
                let animationEffect = AnimationEffect.usingSpringWithDamping(damping: 0.8, velocity: 5)
                view.animate(duration: 0.6, delay: 0.05, param: param,
                             animationEffect: animationEffect)
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        let section = self.upcomingDataSource?.sectionIdentifier(for: indexPath.section)
        if section != .favourites {
            if !applyingData {
                let initialProperty = AnimationProperty(alpha: 0)
                 let param = AnimationParameter.init(yDisplacement: 40, xDisplacement: 0,
                 initialProperty: initialProperty)
                 let animationEffect = AnimationEffect.usingSpringWithDamping(damping: 0.8, velocity: 5)
                 cell.animate(duration: 0.6, delay: 0.05, param: param,
                 animationEffect: animationEffect)
            }
        }
        if let myCell = cell as? DummyCell {
            if myCell.indexValue == (self.feedDetailModel?.arrItemFeed.count ?? 0)-1 {
                feedDetailModel?.currentPage += 1
                if feedDetailModel?.currentPage ?? 0 > feedDetailModel?.totalPage ?? 0 {
                    feedDetailModel?.currentPage = feedDetailModel?.totalPage ?? 0
                } else {
                    self.getAllCommunityFeeds(isPaginated: true,
                                              cachePolicy: .fetchIgnoringCacheData,
                                              isFromRefresh: true, completion: { _ in
                        self.setUpUpcomingData()
                    })
                }
            }
        }
    }
}
