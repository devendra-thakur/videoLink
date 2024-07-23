//
//  EventDetailVC+Datasource.swift
//  BrandedResidence
//
//  Created by Siddhant Dubey on 16/08/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import DVCUtility
import Foundation
import SensonicCore
import UIKit
import UIKITExtension
import AVKit
import AVFoundation

extension EventDetailViewController {
    enum RowType: Hashable {
        case carousel
        case noCarousel
        case eventDetail
        case ticketSale
        case eventDescription
        case pdf(uuid: UUID)
    }

    enum SectionType: Hashable {
        case carousel
        case noCarousel
        case eventDetail
        case eventDescription
        case pdf
    }

    typealias Datasource = UICollectionViewDiffableDataSource<SectionType, RowType>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionType, RowType>
    func registerCells() {
        collectionView.register(nib: EventCarouselCell.self)
        collectionView.register(nib: EventActivityDetailCell.self)
        collectionView.register(nib: TicketSaleCell.self)
        collectionView.register(nib: OutletCartTermsConditionCell.self)
        collectionView.register(nib: EventActivityDescriptionCell.self)
        collectionView.register(nib: CommonTappableCell.self)
        collectionView.register(nib: EventActivityPdfCell.self)
        collectionView.register(nib: NoCarouselImageCell.self)
    }

    // MARK: - Datasource and snapshot
    func configureCarouselCell(_ collectionView: UICollectionView,
                               _ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: EventCarouselCell.self,
                                                      forIndexPath: indexPath)
        cell.arrImageAndVideo = []
        if let arrImage = eventDetail?.attachment?.images?.compactMap({ $0 }), !arrImage.isEmpty {
            var arrImgObject: [CarouselItem] = []
            _ = arrImage.compactMap({ url in
                arrImgObject.append(CarouselItem(url: url))
            })
            if let primaryImg = eventDetail?.attachment?.primaryImage, !primaryImg.isEmpty {
                let imgObject = CarouselItem(url: primaryImg, carouselItemType: .image)
                arrImgObject.insert(imgObject, at: 0)
            }
            cell.arrImageAndVideo = arrImgObject
        } else if let primaryImg = eventDetail?.attachment?.primaryImage, !primaryImg.isEmpty {
            let imgObject = CarouselItem(url: primaryImg, carouselItemType: .image)
            cell.arrImageAndVideo.insert(imgObject, at: 0)
        }
        if let videoLink = eventDetail?.attachment?.link, !videoLink.isEmpty {
            var isVideoPlayable = false
            if let videoUrl = URL(string: videoLink) {
                if let videoId = videoLink.youtubeID, !videoId.isEmpty {
                    isVideoPlayable = true
                } else {
                    isVideoPlayable = AVAsset(url: videoUrl).isPlayable
                }
            }
            if isVideoPlayable {
                let videoObject = CarouselItem(url: videoLink, carouselItemType: .video)
                cell.arrImageAndVideo.insert(videoObject, at: 0)
            }
        }
        let showFewSpots = configFewSpotsLeft()
        cell.viewFewSpotsLeft.isHidden = !showFewSpots
        cell.callBackOpenPreview = { [weak self] previewImage in
            guard let self = self else { return }
            guard let viewController = GenericViewController.instantiate(storyboard:
                                              StoryboardId.main.rawValue) else { return }
            viewController.openImage(path: previewImage)
            viewController.title = ""
            self.navigationController?.pushViewController(viewController:
                                              viewController, animated: true, completion: {
            })

        }
        return cell
    }

    fileprivate func setAdvancedTicketDetails(_ cell: EventActivityDetailCell) {
        if let advanceTicketing = self.eventDetail?.ticketing?.advancedTicketing?.first {
            cell.labelPrice.text = advanceTicketing?.priceLabel
            if let guestCapacity = advanceTicketing?.companionInfo?.capacity, guestCapacity != 0 {
                if isDetailPage {
                    if eventBookingDetail?.guestPaxCount == 0,
                       filterTotalBookedObject(eventDetail: eventDetail).totalGuestCount == guestCapacity,
                       !isAllSlotsBooked {
                        cell.labelGuestPrice.isHidden = true
                    } else {
                        cell.labelGuestPrice.isHidden = false
                        cell.labelGuestPrice.text = advanceTicketing?.companionInfo?.priceLabel
                    }
                } else {
                    if filterTotalBookedObject(eventDetail:
                                                eventDetail).totalGuestCount == guestCapacity, !isAllSlotsBooked {
                        cell.labelGuestPrice.isHidden = true
                    } else {
                        cell.labelGuestPrice.isHidden = false
                        cell.labelGuestPrice.text = advanceTicketing?.companionInfo?.priceLabel
                    }
                }
            }
        }
    }
    
    fileprivate func configureEventDetailCell(_ collectionView: UICollectionView,
                                              _ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: EventActivityDetailCell.self,
                                                      forIndexPath: indexPath)
        cell.labelEventName.text = eventDetail?.title
        cell.labelEventName.lineBreakMode = .byTruncatingTail
        let occurrences = eventDetail?.location?.amenityCategory?.occurrences?.first
        if let location = occurrences??.name, !location.isEmpty {
            cell.labelEventTitle.text = location.uppercased()
        } else {
            cell.labelEventTitle.text = eventDetail?.location?.name?.uppercased()
        }
        cell.labelEventTitle.lineBreakMode = .byTruncatingTail
        cell.labelEventSubtitle.text = eventDetail?.subTitle
        cell.labelEventSubtitle.lineBreakMode = .byTruncatingTail
        var dateToShow: String?
        let startDate = eventDetail?.scheduleConfig?.startDate?
            .getDate(format: DateFormatType.apiFormat.format, withUTC: true)
        let endDate = eventDetail?.scheduleConfig?.endDate?
            .getDate(format: DateFormatType.apiFormat.format, withUTC: true)
        let strStartDate = startDate?.toString(dateFormat: DateFormatType.date.format)
        let strStartTime = startDate?.toString(dateFormat: DateFormatType.time12.format)
        let start = "\(strStartDate ?? "") \(strStartTime ?? "")"
        let strEndDate = endDate?.toString(dateFormat: DateFormatType.date.format)
        let strEndTime = endDate?.toString(dateFormat: DateFormatType.time12.format)
        let end = "\(strEndDate ?? "") \(strEndTime ?? "")"
        if let startDate = startDate, let endDate = endDate {
            if startDate.isSameDay(date: endDate) {
                dateToShow = "\(strStartDate ?? "") \(strStartTime ?? "") - \(strEndTime ?? "")"
            } else {
                dateToShow = "\(start) - \(end)"
            }
        }
        cell.labelEventDate.text = dateToShow ?? ""
        if eventDetail?.attachment?.images?.isEmpty == true ||
            eventDetail?.attachment?.images == nil {
            if eventDetail?.attachment?.primaryImage?.isEmpty == true ||
                eventDetail?.attachment?.primaryImage == nil {
                let showFewSpots = configFewSpotsLeft()
                cell.viewFewSpotsLeft.isHidden = !showFewSpots
            }
        }
        if eventDetail?.eventType == .freeBookingTickets || eventDetail?.eventType == .reservationOnly {
            cell.labelPrice.isHidden = true
            cell.labelGuestPrice.isHidden = true
        } else {
            cell.labelPrice.isHidden = false
            if let isAdvanced = self.eventDetail?.ticketing?.isAdvanced, isAdvanced {
                setAdvancedTicketDetails(cell)
            } else {
                if let ticketing = self.eventDetail?.ticketing?.generalTicketing {
                    cell.labelPrice.text = ticketing.priceLabel
                    cell.labelGuestPrice.isHidden = true
                }
            }
        }
        return cell
    }

    fileprivate func configureTicketSaleCell(_ collectionView: UICollectionView,
                                             _ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: TicketSaleCell.self,
                                                      forIndexPath: indexPath)
        if !isDetailPage {
            if let ticketSaleStartDate = eventDetail?.ticketing?.sellingPeriod?.startDate?
                .getDate(format: DateFormatType.apiFormat.format, withUTC: true) {
                if let ticketSaleEndDate = eventDetail?.ticketing?.sellingPeriod?.endDate?
                    .getDate(format: DateFormatType.apiFormat.format, withUTC: true) {
                    cell.labelTicketSaleDescription.text = self.ticketSaleStatus(startDate: ticketSaleStartDate,
                                                                                 endDate: ticketSaleEndDate)
                }
            }
        } else {
            if let eventEndDate = eventDetail?.scheduleConfig?.endDate?
                .getDate(format: DateFormatType.apiFormat.format, withUTC: true),
               eventEndDate.isInPast {
                cell.labelTicketSaleDescription.text = "You have attended this event"
            } else {
                cell.labelTicketSaleDescription.text = "You are attending this event"
            }
            cell.imageTicket.image = .eventBooked
        }
        return cell
    }

    fileprivate func configureEventDescriptionCell(_ collectionView: UICollectionView,
                                                   _ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: EventActivityDescriptionCell.self,
                                                      forIndexPath: indexPath)
        cell.labelDescription.text = eventDetail?.description
        return cell
    }

    fileprivate func configurePdfCell(_ collectionView: UICollectionView, _ indexPath: IndexPath,
                                      _ self: EventDetailViewController) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: EventActivityPdfCell.self,
                                                      forIndexPath: indexPath)
        if let attachments = self.eventDetail?.attachment?.fileAttachments, !attachments.isEmpty {
            cell.labelTitle.text = attachments[indexPath.item]?.name ?? ""
            cell.labelTitle.lineBreakMode = .byTruncatingTail
            cell.callBackTap = {
                cell.isUserInteractionEnabled = false
                cell.bounceAnimation(completion: {
                    self.openPdfViewController(url: attachments[indexPath.item]?.url ?? "",
                                               title: attachments[indexPath.item]?.name ?? "")
                    cell.isUserInteractionEnabled = true
                })
            }
        }
        return cell
    }

    func configureDatasource() -> Datasource {
    let datasource = Datasource(collectionView: collectionView,
                   cellProvider: { [weak self] (collectionView, indexPath, rowType)
            -> UICollectionViewCell in
            guard let self = self else { return UICollectionViewCell() }
            switch rowType {
            case .carousel:
                return self.configureCarouselCell(collectionView, indexPath)
            case .eventDetail:
                return self.configureEventDetailCell(collectionView, indexPath)
            case .ticketSale:
                return self.configureTicketSaleCell(collectionView, indexPath)
            case .eventDescription:
                return self.configureEventDescriptionCell(collectionView, indexPath)
            case .pdf:
                return self.configurePdfCell(collectionView, indexPath, self)
            case .noCarousel:
                let cell = collectionView.dequeueReusableCell(ofType: NoCarouselImageCell.self,
                                                              forIndexPath: indexPath)
                return cell
            }
        })
        return datasource
    }
    func createSnapshot() {
        var snapshot = Snapshot()
        var isVideoPlayable = false
        if let videoLink = eventDetail?.attachment?.link, !videoLink.isEmpty {
            if let videoUrl = URL(string: videoLink) {
                if let videoId = videoLink.youtubeID, !videoId.isEmpty {
                    isVideoPlayable = true
                } else {
                    isVideoPlayable = AVAsset(url: videoUrl).isPlayable
                }
            }
        }
        if let arrImages = eventDetail?.attachment?.images?.compactMap({ $0 }), !arrImages.isEmpty {
            collectionView.contentInset.top = 0
            snapshot.appendSections([.carousel])
            snapshot.appendItems([.carousel], toSection: .carousel)
        } else if let primaryImage = eventDetail?.attachment?.primaryImage, !primaryImage.isEmpty {
            snapshot.appendSections([.carousel])
            snapshot.appendItems([.carousel], toSection: .carousel)
        } else if isVideoPlayable {
            snapshot.appendSections([.carousel])
            snapshot.appendItems([.carousel], toSection: .carousel)
        } else {
            collectionView.contentInset.top = 24
            snapshot.appendSections([.noCarousel])
            snapshot.appendItems([.noCarousel], toSection: .noCarousel)
        }
        snapshot.appendSections([.eventDetail, .eventDescription])
        snapshot.appendItems([.eventDetail], toSection: .eventDetail)
        if let ticketSaleStartDate = eventDetail?.ticketing?.sellingPeriod?.startDate,
            !ticketSaleStartDate.isEmpty {
            if let ticketSaleEndDate = eventDetail?.ticketing?.sellingPeriod?.endDate,
               !ticketSaleEndDate.isEmpty {
                snapshot.appendItems([.ticketSale], toSection: .eventDetail)
            }
        }
        if isDetailPage {
            snapshot.appendItems([.ticketSale], toSection: .eventDetail)
        }
        snapshot.appendItems([.eventDescription], toSection: .eventDescription)
        if let attachments = eventDetail?.attachment?.fileAttachments, !attachments.isEmpty {
            snapshot.appendSections([.pdf])
            _ = attachments.compactMap({ _ in
                snapshot.appendItems([.pdf(uuid: UUID())], toSection: .pdf)
            })
        }
        datasource.apply(snapshot, animatingDifferences: true)
    }

    func openPdfViewController(url: String, title: String) {
        guard let viewController = PDFViewController.instantiate(storyboard:
            StoryboardId.book.rawValue) else { return }
        if let pdfUrl = URL(string: url) {
            SensonicCore().downloadPDF(pdfUrl: pdfUrl) { [weak self] _, url in
                guard let self = self else { return }
                if let destination = url {
                    viewController.pdfURL = destination
                    viewController.title = title
                    self.navigationController?.pushViewController(viewController:
                        viewController, animated: true, completion: nil)
                }
            }
        }
    }
}
