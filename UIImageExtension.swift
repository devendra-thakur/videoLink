//
//  File.swift
//  
//
//  Created by Apple on 04/02/21.
//

import UIKit

extension UIImage {

    public enum DataUnits: String {
        case byte, kilobyte, megabyte, gigabyte
      var text:String {
        switch self {
        case .byte:
          return "Byte|imageValidation".localized()
        case .kilobyte:
          return "Kilobyte|imageValidation".localized()
        case .megabyte:
          return "Megabyte|imageValidation".localized()
        case .gigabyte:
          return "Gigabyte|imageValidation".localized()
        }
      }
    }

    private func getImageSize(_ type: DataUnits)-> Double {

        guard let data = self.pngData() else {
          return 0.0
        }

        var size: Double = 0.0

        switch type {
        case .byte:
            size = Double(data.count)
        case .kilobyte:
            size = Double(data.count) / 1024
        case .megabyte:
            size = Double(data.count) / 1024 / 1024
        case .gigabyte:
            size = Double(data.count) / 1024 / 1024 / 1024
        }
        return size
        //return String(format: "%.2f", size)
    }
  
  public func isValidImageSize(_ type: DataUnits, maxSize:Double, minSize:Double = 0.0) ->(status:Bool, message:String) {
    let size = getImageSize(type)
    if size > 0.0 {
      if size < minSize {
        return (status:false, message:"Image size should bigger then \(minSize) \(type.text)")
      } else if size > maxSize {
        return (status:false, message:"Image size should not bigger then \(maxSize) \(type.text)")
      } else {
        return (status: true, message: "valid Size")
      }
    }
    return (status:false, message:"No size found")
  }
  
  public func stretchImage(inset:UIEdgeInsets = .zero, mode: ResizingMode = .tile) -> UIImage {
    let resizable = self.resizableImage(withCapInsets: UIEdgeInsets(top: inset.top,
                                                                    left: inset.left,
                                                                    bottom: inset.bottom,
                                                                    right: inset.right),
                                             resizingMode: mode)
    return resizable
  }
  public func resize(targetSize: CGSize) -> UIImage {
      autoreleasepool {
          let size = self.size
          
          let widthRatio  = targetSize.width  / self.size.width
          let heightRatio = targetSize.height / self.size.height
          
          var newSize: CGSize
          if widthRatio > heightRatio {
              newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
          } else {
              newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
          }
          if newSize.width == 0 || newSize.height == 0 {
              newSize = self.size
          }
          let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
          let scale = self.scale
          UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
          self.draw(in: rect)
          let newImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          
          return newImage!
      }
      }
      
      public func scale(by scale: CGFloat) -> UIImage? {
          let size = self.size
          let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
          return self.resize(targetSize: scaledSize)
      }
    
    public func fixImageOrientation() -> UIImage {
        guard let cgImage = self.cgImage else {
            // Return the original image if the CGImage is not available
            return self
        }

        // Get the orientation from the image's metadata
        let orientation = self.imageOrientation

        var transform = CGAffineTransform.identity

        switch orientation {
        case .up:
            // No transformation needed
            break

        case .down:
            // Flip the image 180 degrees
            transform = transform.translatedBy(x: CGFloat(self.size.width), y: CGFloat(self.size.height))
            transform = transform.rotated(by: CGFloat.pi)

        case .left, .leftMirrored:
            // Rotate the image 90 degrees counterclockwise
            transform = transform.translatedBy(x: CGFloat(self.size.width), y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)

        case .right, .rightMirrored:
            // Rotate the image 90 degrees clockwise
            transform = transform.translatedBy(x: 0, y: CGFloat(self.size.height))
            transform = transform.rotated(by: -CGFloat.pi / 2.0)

        default:
            break
        }

        // Apply the transformation to the image
        if let context = CGContext(data: nil,
                                   width: Int(self.size.width),
                                   height: Int(self.size.height),
                                   bitsPerComponent: cgImage.bitsPerComponent,
                                   bytesPerRow: 0,
                                   space: cgImage.colorSpace!,
                                   bitmapInfo: cgImage.bitmapInfo.rawValue) {
            context.concatenate(transform)
            switch orientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                // For left and right orientations, swap the width and height
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
            default:
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            }

            // Create a new UIImage from the transformed context
            if let rotatedImage = context.makeImage() {
                return UIImage(cgImage: rotatedImage)
            }
        }

        // Return the original image if any issues occur
        return self
    }

}
