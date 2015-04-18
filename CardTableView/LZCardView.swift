//
//  LZCardView.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-14.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit

class Point{
  var x:CGFloat = 0
  var y:CGFloat = 0
  var z:CGFloat = 0
  init(){
    
  }
  init(x: CGFloat, y: CGFloat, z: CGFloat){
    self.x = x
    self.y = y
    self.z = z
  }
  init(x: CGFloat){
    self.x = x
  }
  init(y: CGFloat){
    self.y = y
  }
  init(z: CGFloat){
    self.z = z
  }
}
class LZCardView: UIView {
  var view:UIView?
  var defaultTranslation = Point()
  var translation = Point()
  var translation3d = Point()
  var xRotation:CGFloat = 0
  var defaultRotation:CGFloat = 0
  var darkenLayer:CALayer = CALayer()
  func applyTransform(){
    var transform = CATransform3DIdentity
    
    transform.m34 = CGFloat(1.0 / -1000)
    transform = CATransform3DTranslate(transform, translation.x + defaultTranslation.x, translation.y + defaultTranslation.y, translation.z + defaultTranslation.z)
    transform = CATransform3DRotate(transform, ((defaultRotation + xRotation) / 180) * CGFloat(M_PI), CGFloat(1.0), CGFloat(0.0), CGFloat(0.0))
    transform = CATransform3DTranslate(transform, translation3d.x, translation3d.y, translation3d.z)
    self.layer.transform = transform
  }
  
  override class func layerClass() -> AnyClass{
    return CAGradientLayer.self
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    darkenLayer.frame = bounds
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    if let layer = layer as? CAGradientLayer{
      layer.colors = [
        UIColor(white: 0.4, alpha: 0.0).CGColor,
        UIColor(white: 0.4, alpha: 0.5).CGColor,
        UIColor(white: 0.4, alpha: 0.8).CGColor,
      ]
      layer.startPoint = CGPoint(x:0.5, y:0.0)
      layer.endPoint = CGPoint(x:0.5, y:1.0)
    }
    darkenLayer.backgroundColor = UIColor(white: 0.5, alpha: 0.4).CGColor
    darkenLayer.opacity = 0
    darkenLayer.frame = frame
    layer.addSublayer(darkenLayer)
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
