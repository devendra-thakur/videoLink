//
//  EventDetailVC+Delegate.swift
//  BrandedResidence
//
//  Created by Siddhant Dubey on 16/08/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import DVCUtility
import UIKITExtension
import UIKit
extension EventDetailViewController {
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionId, _) -> NSCollectionLayoutSection? in
            guard let self = self else {return nil}
            guard let section = self.datasource.sectionIdentifier(for: sectionId) else {return nil}
            switch section {
            case .carousel:
                return self.createCarouselLayout()
            case .eventDetail, .eventDescription, .pdf, .noCarousel:
                return self.createEventLayout()
            }
        }
        let config = UICollectionViewCompositionalLayoutConfiguration()
        layout.configuration = config
        return layout
    }
    func createCarouselLayout() -> NSCollectionLayoutSection {
        let edge = NSDirectionalEdgeInsets(top: 0,
                                           leading: LayoutConstant.leadingTrailingZero, bottom: 24,
                                           trailing: LayoutConstant.leadingTrailingZero)
        let objDimension = CollectionDimension(supplymentaryWAndH: [],
                                               groupAndSectionSpacing: (item: 0, group: 0),
                                               contentEdge: edge,
                                               itemWidthAndHeight: (width: .fractionalWidth(1),
                                                                    height: .absolute(260)),
                                               groupWidthAndHeight: (width: .fractionalWidth(1),
                                                                     height: .absolute(260)))
        return collectionView.createSection(objDimension: objDimension)
    }
    func createEventLayout() -> NSCollectionLayoutSection {
        let edge = NSDirectionalEdgeInsets(top: 0, leading: LayoutConstant.leadingTrailing16,
                                           bottom: 24, trailing: LayoutConstant.leadingTrailing16)
        let objDimension = CollectionDimension(supplymentaryWAndH: [],
                                               groupAndSectionSpacing: (item: 24, group: 0),
                                               contentEdge: edge,
                                               itemWidthAndHeight: (width: .fractionalWidth(1),
                                                                    height: .estimated(32)),
                                               groupWidthAndHeight: (width: .fractionalWidth(1),
                                                                     height: .estimated(32)))
        return collectionView.createSection(objDimension: objDimension)
    }
}
