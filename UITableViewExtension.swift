//
//  File.swift
//  
//
//  Created by Apple on 19/01/21.
//

import UIKit


extension UITableView {
  
  //  register for the Class-based cell
  public func register<T: UITableViewCell>(class: T.Type) {
    register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
  }
  
  //  register for the Nib-based cell
  public func register<T: UITableViewCell>(nib: T.Type) {
    register(T.nib, forCellReuseIdentifier: T.reuseIdentifier)
  }
  
  public func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T {
    guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
      let error1 = "Dequeing a cell with identifier:"
      let error2 = "failed.\nDid you maybe forget to register it in viewDidLoad?"
      fatalError(" \(error1) \(T.reuseIdentifier) \(error2)")
    }
    cell.layer.shouldRasterize = true
    cell.layer.rasterizationScale = UIScreen.main.scale
    return cell
  }
  
  public func dequeueReusableCell<T: UITableViewCell>(ofType: T.Type, forIndexPath indexPath: IndexPath) -> T {
    //    this deque and cast can fail if you forget to register the proper cell
    guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
      //    thus crash instantly and nudge the developer
      let error1 = "Dequeing a cell with identifier:"
      let error2 = "failed.\nDid you maybe forget to register it in viewDidLoad?"
      fatalError(" \(error1) \(T.reuseIdentifier) \(error2)")
    }
    cell.layer.shouldRasterize = true
    cell.layer.rasterizationScale = UIScreen.main.scale
    return cell
  }
  
  //  register for the Class-based header/footer view
  public func register<T: UITableViewHeaderFooterView>(class: T.Type) {
    register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
  }
  
  //  register for the Nib-based header/footer view
  public func register<T: UITableViewHeaderFooterView>(nib: T.Type) {
    register(T.nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
  }
  
  public func dequeueReusableView<T: UITableViewHeaderFooterView>() -> T? {
    let view = dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T
    return view
  }
}

extension UITableViewHeaderFooterView: NibReusableView {}
extension UITableViewCell: NibReusableView {}
