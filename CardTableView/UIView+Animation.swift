//
//  UIView+Animation.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-17.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit

let damping:CGFloat = 0.6
let initialV:CGFloat = 0.0
extension UIView {
  class func animateEaseInWithDuration(duration:NSTimeInterval, animations:() -> Void){
    UIView.animateEaseInWithDuration(duration, animations:animations){}
  }
  class func animateEaseInWithDuration(duration:NSTimeInterval, animations:() -> Void, completion:() -> Void){
    UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseIn, animations: animations) { (completed) -> Void in
      completion()
    }
  }
  class func animateEaseOutWithDuration(duration:NSTimeInterval, animations:() -> Void){
    UIView.animateEaseOutWithDuration(duration, animations:animations){}
  }
  class func animateEaseOutWithDuration(duration:NSTimeInterval, animations:() -> Void, completion:() -> Void){
    UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseOut, animations: animations) { (completed) -> Void in
      completion()
    }
  }
  class func animateBounceWithDuration(duration:NSTimeInterval, animations:() -> Void) {
    UIView.animateBounceWithDuration(duration, animations:animations){}
  }
  class func animateBounceWithDuration(duration:NSTimeInterval, animations:() -> Void, completion:(() -> Void)?) {
    UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: initialV, options: [], animations: animations){(completed) -> Void in
      completion?()
    }
  }
  func takeSnapshot() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
    
    drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
    
    // old style: layer.renderInContext(UIGraphicsGetCurrentContext())
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}

