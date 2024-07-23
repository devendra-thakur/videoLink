//
//  File.swift
//  
//
//  Created by Devendra Thakur on 05/03/21.
//

import UIKit

extension UISlider {
  var imageDirection: Int {
    set {
      direction = ViewDirection(rawValue: newValue)!
    }
    get {
      return direction.rawValue
    }
  }
}
