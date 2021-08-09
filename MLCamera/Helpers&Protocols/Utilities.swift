//
//  Utilities.swift
//  MLCamera
//
//  Created by Roi Kedarya on 07/08/2021.
//

import Foundation
import UIKit
import MLKit
import AVFoundation

class Utilities {
    
    public static func imageOrientation() -> UIImage.Orientation {
      var deviceOrientation = UIDevice.current.orientation
      if deviceOrientation == .faceDown || deviceOrientation == .faceUp
        || deviceOrientation
          == .unknown
      {
        deviceOrientation = currentUIOrientation()
      }
      switch deviceOrientation {
      case .portrait:
        return  .right
      case .landscapeLeft:
        return  .up
      case .portraitUpsideDown:
        return  .left
      case .landscapeRight:
        return  .down
      case .faceDown, .faceUp, .unknown:
        return .up
      @unknown default:
        fatalError()
      }
    }
    
    private static func currentUIOrientation() -> UIDeviceOrientation {
      let deviceOrientation = { () -> UIDeviceOrientation in
        if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
            switch interfaceOrientation {
            case .landscapeLeft:
              return .landscapeRight
            case .landscapeRight:
              return .landscapeLeft
            case .portraitUpsideDown:
              return .portraitUpsideDown
            case .portrait, .unknown:
              return .portrait
            @unknown default:
              fatalError()
            }
        }
        fatalError("can't find KeyWindow orientation")
      }
      guard Thread.isMainThread else {
        var currentOrientation: UIDeviceOrientation = .portrait
        DispatchQueue.main.sync {
          currentOrientation = deviceOrientation()
        }
        return currentOrientation
      }
      return deviceOrientation()
    }
    
    public static func getImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let image =  UIImage(ciImage: ciImage, scale: 1.0, orientation: Utilities.imageOrientation())
            return image
        }
        return nil
    }

}
