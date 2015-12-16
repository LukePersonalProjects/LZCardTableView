//
// Copyright 2014 Scott Logic
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import AVFoundation



class CameraViewController: UIViewController {
  
  let cameraView = CameraView()
//  var videoFilter: CoreImageVideoFilter!
  var detector: CIDetector!
  var overlayView = OverlayView()
  var count = 0
  var frequency = 10
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.blackColor()
    
    cameraView.frame = view.bounds
    view.addSubview(cameraView)

    overlayView.frame = view.bounds
    view.addSubview(overlayView)
    
    view.sendSubviewToBack(overlayView)
    view.sendSubviewToBack(cameraView)

    // Create the video filter
//    videoFilter = CoreImageVideoFilter(superview: view, applyFilterCallback: nil)
    detector = prepareRectangleDetector()
//
//    
    cameraView.applyFilter = { image in
      if self.count == self.frequency{
        dispatch_async(dispatch_get_main_queue(), {
          self.performRectangleDetection(image)
        })
        self.count = 0
      }
      self.count++
    }
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    checkPermissions()
  }
  
  private func checkPermissions() {
    if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Authorized {
      startCamera()
    } else {
      AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { granted in
        dispatch_async(dispatch_get_main_queue()) {
          if granted == true {
            self.startCamera()
          } else {
            self.showNoPermissionsView()
          }
        }
      }
    }
  }
  
  private func showNoPermissionsView() {
//    let permissionsView = ALPermissionsView(frame: view.bounds)
//    view.addSubview(permissionsView)
//    view.addSubview(closeButton)
//    
//    closeButton.addTarget(self, action: "close", forControlEvents: UIControlEvents.TouchUpInside)
//    closeButton.setImage(UIImage(named: "retakeButton", inBundle: NSBundle(forClass: ALCameraViewController.self), compatibleWithTraitCollection: nil), forState: UIControlState.Normal)
//    closeButton.sizeToFit()
//    
//    let size = view.frame.size
//    let closeSize = closeButton.frame.size
//    let closeX = horizontalPadding
//    let closeY = size.height - (closeSize.height + verticalPadding)
//    
//    closeButton.frame.origin = CGPointMake(closeX, closeY)
  }
  
  private func startCamera() {
    cameraView.startSession()
//    cameraButton.addTarget(self, action: "capturePhoto", forControlEvents: .TouchUpInside)
//    swapButton.addTarget(self, action: "swapCamera", forControlEvents: .TouchUpInside)
//    libraryButton.addTarget(self, action: "showLibrary", forControlEvents: .TouchUpInside)
//    closeButton.addTarget(self, action: "close", forControlEvents: .TouchUpInside)
//    flashButton.addTarget(self, action: "toggleFlash", forControlEvents: .TouchUpInside)
//    layoutCamera()
  }
  
  func takeShot(callback:CameraShotCompletion){
    cameraView.capturePhoto { (sourceImage) -> Void in
      if let feature = self.getFeatures(sourceImage){
        let outputImage = sourceImage.imageByApplyingFilter("CIPerspectiveCorrection",
          withInputParameters: [
            "inputTopLeft": CIVector(CGPoint: feature.topLeft),
            "inputTopRight": CIVector(CGPoint: feature.topRight),
            "inputBottomLeft": CIVector(CGPoint: feature.bottomLeft),
            "inputBottomRight": CIVector(CGPoint: feature.bottomRight)
          ])
        callback(outputImage.imageByApplyingOrientation(6))
      }else{
        callback(sourceImage.imageByApplyingOrientation(6))
      }
    }
  }
  
  //MARK: Utility methods
  func getFeatures(image: CIImage) -> CIRectangleFeature?{
    let features = detector.featuresInImage(image) as! [CIRectangleFeature]
    return features.first
  }
  
  func performRectangleDetection(image: CIImage) {
    if let feature = getFeatures(image){
      let topLeft = cameraView.convertImagePoint(feature.topLeft)
      let topRight = cameraView.convertImagePoint(feature.topRight)
      let bottomLeft = cameraView.convertImagePoint(feature.bottomLeft)
      let bottomRight = cameraView.convertImagePoint(feature.bottomRight)
      
      overlayView.updatePoints(topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
      overlayView.show = true
    }else{
      overlayView.show = false
    }
  }
  
  func prepareRectangleDetector() -> CIDetector {
    let options: [String: AnyObject] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0]
    return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
  }

}

