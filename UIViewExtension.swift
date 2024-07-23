//
//  File.swift
//  
//
//  Created by Apple on 19/01/21.
//

import UIKit


extension UIView {
  
  /// testCaseId is using for set and get object accessibilityIdentifier
  /// This is using during writing UI and Unit test cases
  /// UI Test case files are getting object by this id
  /// standard format to set testCase Id is: class.objectName
  /// For example : controller.buttonContinue, login.buttonDone etc..
  @IBInspectable public var testCaseId: String {
    get {
      return accessibilityIdentifier ?? ""
    }
    set {
      accessibilityIdentifier = newValue
      accessibilityLabel = newValue
    }
  }
  
  //MARK:- Load UIView from nib name
  public func loadViewFromNib<T: UIView>() -> T? {
    return Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)?.first as? T
  }
  
  //MARK:- Add a UIView inside any view including constraint
  public func fixInView(_ container: UIView?) {
      autoreleasepool {
          translatesAutoresizingMaskIntoConstraints = false
          if let container = container {
              frame = container.frame
              container.addSubview(self)
              NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal,
                                 toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
              NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal,
                                 toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
              NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal,
                                 toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
              NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal,
                                 toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
          }
      }
  }
  @IBInspectable public var languageLayout: Bool {
    set {
      if newValue {
        self.semanticContentAttribute = UIKitManager.shared().isRTL ? .forceRightToLeft : .forceLeftToRight
        switch self {
        
        case let btn as UIButton:
          btn.titleEdgeInsets = .init(top: UIKitManager.shared().isRTL ? -btn.titleEdgeInsets.top : btn.titleEdgeInsets.top,
                                      left: UIKitManager.shared().isRTL ? -btn.titleEdgeInsets.left : btn.titleEdgeInsets.left,
                                      bottom: UIKitManager.shared().isRTL ? -btn.titleEdgeInsets.bottom : btn.titleEdgeInsets.bottom,
                                      right: UIKitManager.shared().isRTL ? -btn.titleEdgeInsets.right : btn.titleEdgeInsets.right)
          btn.setTitle(btn.title(for: .normal)?.localized(), for: .normal)
          btn.setTitle(btn.title(for: .selected)?.localized(), for: .selected)
          
        case let slider as UISlider:
          slider.imageDirection = 2
          
        case let sgmnt as UISegmentedControl:
          (0 ..< sgmnt.numberOfSegments).forEach { sgmnt.setTitle(sgmnt.titleForSegment(at: $0)?.localized(), forSegmentAt: $0) }
          
        case let textView as UITextView:
          textView.text = textView.text?.localized()
          if textView.textAlignment != .center {
            textView.textAlignment = UIKitManager.shared().isRTL ? .right : .left
          }
          
        case let textField as UITextField:
          textField.text = textField.text?.localized()
          if textField.textAlignment != .center {
            textField.textAlignment = UIKitManager.shared().isRTL ? .right : .left
          }
          
        default:
          break
        }
      } else {
        semanticContentAttribute = .unspecified
      }
    }
    get {
      return false
    }
  }
  ///
  /// Change the direction of the view depeneding in the language, there is no return value for this variable.
  ///
  /// The expectid values:
  ///
  /// -`fixed`: if the view must not change the direction depending on the language.
  ///
  /// -`leftToRight`: if the view must change the direction depending on the language
  /// and the view is left to right view.
  ///
  /// -`rightToLeft`: if the view must change the direction depending on the language
  /// and the view is right to left view.
  ///
  internal var direction: ViewDirection {
    set {
      switch newValue {
      case .fixed:
        break
      case .rightToLeft where UIKitManager.shared().isRTL:
        transform = CGAffineTransform(scaleX: -1, y: 1)
      case .leftToRight where !UIKitManager.shared().isRTL:
        transform = CGAffineTransform(scaleX: -1, y: 1)
      default:
        break
      }
    }
    get {
      fatalError("There is no value return from this variable, this variable used to change the view direction depending on the langauge")
    }
  }
}
///Dont remove below Code it will be useful once we will start rigth code for Text and other controls in term of Language direction
/*
 
 //        case let txtf as UITextField:
 //             txtf.text = txtf.text?.localized()
 //             txtf.placeholder = txtf.placeholder?.localized()
 //           case let lbl as UILabel:
 //             lbl.text = lbl.text?.localized()
 //           case let tabbar as UITabBar:
 //             tabbar.items?.forEach({ $0.title = $0.title?.localized() })
 
 
 UIVIew Extension for language change (Now not using but holding for future use )
 
 /*
 static func localize() {
 
 let orginalSelector = #selector(awakeFromNib)
 let swizzledSelector = #selector(swizzledAwakeFromNib)
 
 let orginalMethod = class_getInstanceMethod(self, orginalSelector)
 let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
 
 let didAddMethod = class_addMethod(self, orginalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
 
 if didAddMethod {
 class_replaceMethod(self, swizzledSelector, method_getImplementation(orginalMethod!), method_getTypeEncoding(orginalMethod!))
 } else {
 method_exchangeImplementations(orginalMethod!, swizzledMethod!)
 }
 
 }
 
 @objc func swizzledAwakeFromNib() {
 swizzledAwakeFromNib()
 
 switch self {
 case let txtf as UITextField:
 txtf.text = txtf.text?.localized()
 txtf.placeholder = txtf.placeholder?.localized()
 case let lbl as UILabel:
 lbl.text = lbl.text?.localized()
 case let tabbar as UITabBar:
 tabbar.items?.forEach({ $0.title = $0.title?.localized() })
 case let btn as UIButton:
 btn.setTitle(btn.title(for: .normal)?.localized(), for: .normal)
 case let sgmnt as UISegmentedControl:
 (0 ..< sgmnt.numberOfSegments).forEach { sgmnt.setTitle(sgmnt.titleForSegment(at: $0)?.localized(), forSegmentAt: $0) }
 case let txtv as UITextView:
 txtv.text = txtv.text?.localized()
 default:
 break
 }
 }
 */
 
 */
