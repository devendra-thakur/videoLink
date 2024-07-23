//
//  File.swift
//  
//
//  Created by Apple on 19/01/21.
//

import UIKit

extension UIViewController {
  public static func instantiate(storyboard: String) -> Self? {
    let idValue = String(describing: self)
    let storyboard = UIStoryboard(name: storyboard, bundle: .main)
    return storyboard.instantiateViewController(withIdentifier: idValue) as? Self
  }
}
