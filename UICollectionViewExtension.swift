//
//  File.swift
//  
//
//  Created by Apple on 20/01/21.
//

import UIKit

extension UICollectionReusableView: NibReusableView {}
public typealias ScrollBehaviour = UICollectionLayoutSectionOrthogonalScrollingBehavior

extension UICollectionView {

  //  register for the Class-based cell
  public func register<T: UICollectionViewCell>(class: T.Type) {
    register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
  }

  //  register for the Nib-based cell
  public func register<T: UICollectionViewCell>(nib: T.Type) {
    register(T.nib, forCellWithReuseIdentifier: T.reuseIdentifier)
  }

  public func dequeueReusableCell<T: UICollectionViewCell>(ofType: T.Type, forIndexPath indexPath: IndexPath) -> T {
    //  this deque and cast can fail if you forget to register the proper cell
    guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
      //  thus crash instantly and nudge the developer
      let error1 = "Dequeing a cell with identifier:"
      let error2 = "failed.\nDid you may be forget to register it in viewDidLoad?"
      fatalError(" \(error1) \(T.reuseIdentifier) \(error2)")
    }
    cell.layer.shouldRasterize = true
    cell.layer.rasterizationScale = UIScreen.main.scale

    return cell
  }

  //  register for the Class-based supplementary view
  public func register<T: UICollectionReusableView>(class: T.Type, forKind kind: String) {
    register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseIdentifier)
  }

  //  register for the Nib-based supplementary view
  public func register<T: UICollectionReusableView>(nib: T.Type, forKind kind: String) {
    register(T.nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseIdentifier)
  }

  public func dequeueReusableSupplementaryView<T: UICollectionReusableView>(kind: T.Type,
                                                                            atIndexPath indexPath: IndexPath) -> T {
    //  this deque and cast can fail if you forget to register the proper cell
    guard let view = dequeueReusableSupplementaryView(ofKind: T.reuseIdentifier,
                                                      withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
      //  thus crash instantly and nudge the developer
      let error1 = "Dequeing supplementary view of kind:"
      let error2 = "failed.\nDid you may be forget to register it in viewDidLoad?"
      fatalError(" \(error1) \( kind ) with identifier: \(T.reuseIdentifier) \(error2)")
    }
    view.layer.shouldRasterize = true
    view.layer.rasterizationScale = UIScreen.main.scale
    return view
  }
}
extension UICollectionView {
  // MARK: - CollectionDimension
  // Created number of section(s)
  // - Parameters:
  //   - isHeader: do you want?
  //   - behaviour: it will give paging behaviour and vertical scroll
  //   - headerType: do you want?
  //   - pinHeader: pin header on scroll?
  //   - alignmentHeader: set left,right,top,bottom
  //   - headerWidthAndHeight: headerview dimension(s)?
  //   - tileCount: Do you want grid of two or more
  //   - axis: what kind of axis you want horizontal or vertical
  //   - groupAndSectionSpacing: how much spacing you need to between item(s) and section(s)
  //   - contentEdge: it will set view edges
  //   - itemWidthAndHeight - it will set item widhth & height
  //   - groupWidthAndHeight: it will set item widhth & height ,
  //   you can  give estimated height and it will be approx your content
  //     then it will increase automatically
  // - Returns: NSCollectionLayoutSection it is a type of section which it returning a section
  //Note: Array And Tile Count are proportional, it you will give it nil then we will show array of item(s)
  public func createSection(objDimension: CollectionDimension) -> NSCollectionLayoutSection {

    let itemSize  = NSCollectionLayoutSize(widthDimension:
    objDimension.itemWidthAndHeight?.width ?? .fractionalWidth(1), heightDimension:
    objDimension.itemWidthAndHeight?.height ?? .fractionalWidth(1))
    let item      = NSCollectionLayoutItem(layoutSize: itemSize)
    //item.contentInsets = contentEdge
    let groupSize = NSCollectionLayoutSize(widthDimension:
    objDimension.groupWidthAndHeight?.width ?? .fractionalWidth(1),
    heightDimension: objDimension.groupWidthAndHeight?.height ?? .fractionalWidth(1))
    let group: NSCollectionLayoutGroup!

    if objDimension.arrayAndTileCount != nil {
      if objDimension.arrayAndTileCount?.arrayCount == 1 {
        group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
      } else {
        group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item,
                                                   count: objDimension.arrayAndTileCount?.tileCount ?? 1)
      }
    } else {
      group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    }

    group.interItemSpacing = .fixed(objDimension.groupAndSectionSpacing?.1 ?? 0)

    let section = NSCollectionLayoutSection(group: group)
    if let edgeInset = objDimension.contentEdge {
      section.contentInsets = edgeInset
    }
    section.interGroupSpacing = objDimension.groupAndSectionSpacing?.0 ?? 0
    section.orthogonalScrollingBehavior = objDimension.behaviour

    var arrSupplyMentaryView: [NSCollectionLayoutBoundarySupplementaryItem] = []

    if let viewType = objDimension.supplymentaryWAndH {
      _ = viewType.map {
        let supplymentaryViewSize =
        NSCollectionLayoutSize(widthDimension: $0.width, heightDimension: $0.height)
        let supplyMentaryView = NSCollectionLayoutBoundarySupplementaryItem(layoutSize:
        supplymentaryViewSize, elementKind: $0.supplyMentaryKind, alignment: $0.alignment ?? .top)
        supplyMentaryView.pinToVisibleBounds = $0.pinHeader ?? false
        if let edge = $0.contentEdge {
          supplyMentaryView.contentInsets = edge
        }
        arrSupplyMentaryView.append(supplyMentaryView)
      }
    }

    section.boundarySupplementaryItems = arrSupplyMentaryView
    return section
  }
}
public struct CollectionSupplyMentary {
  public var pinHeader: Bool?
  public var alignment: NSRectAlignment?
  public var contentEdge: NSDirectionalEdgeInsets?
  public var supplyMentaryKind: String
  public var width: NSCollectionLayoutDimension
  public var height: NSCollectionLayoutDimension
  
  public init(pinHeader:Bool = false,
              alignment:NSRectAlignment? = nil,
              contentEdge:NSDirectionalEdgeInsets? = nil,
              supplyMentaryKind:String,
              width:NSCollectionLayoutDimension,
              height:NSCollectionLayoutDimension) {
    
    self.pinHeader = pinHeader
    self.alignment = alignment
    self.contentEdge = contentEdge
    self.supplyMentaryKind = supplyMentaryKind
    self.width = width
    self.height = height
  }
}

// MARK: CollectionDimension
public struct CollectionDimension {
  public var behaviour: ScrollBehaviour = .none
  public var supplymentaryWAndH: [CollectionSupplyMentary]?
  public var arrayAndTileCount: (arrayCount: Int, tileCount: Int)?
  public var groupAndSectionSpacing: (item: CGFloat, group: CGFloat)?
  public var contentEdge: NSDirectionalEdgeInsets?
  public var itemWidthAndHeight: (width: NSCollectionLayoutDimension, height: NSCollectionLayoutDimension)?
  public var groupWidthAndHeight: (width: NSCollectionLayoutDimension, height: NSCollectionLayoutDimension)?
  
  
  public init(behaviour:ScrollBehaviour = .none,
              supplymentaryWAndH:[CollectionSupplyMentary]? = nil,
              arrayAndTileCount:(arrayCount: Int, tileCount: Int)? = nil,
              groupAndSectionSpacing:(item: CGFloat, group: CGFloat)? = nil,
              contentEdge:NSDirectionalEdgeInsets? = .none,
              itemWidthAndHeight:(width: NSCollectionLayoutDimension, height: NSCollectionLayoutDimension)? = nil,
              groupWidthAndHeight:(width: NSCollectionLayoutDimension, height: NSCollectionLayoutDimension)? = nil) {
    
    self.behaviour = behaviour
    self.supplymentaryWAndH = supplymentaryWAndH
    self.arrayAndTileCount = arrayAndTileCount
    self.groupAndSectionSpacing = groupAndSectionSpacing
    self.contentEdge = contentEdge
    self.itemWidthAndHeight = itemWidthAndHeight
    self.groupWidthAndHeight = groupWidthAndHeight
  }
}
