//
//  LZCardView.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-14.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit

public class Point{
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

public class CardItemView:UIView{
  public var defaultTranslation = Point()
  public var translation = Point()
  public var translation3d = Point()
  public var xRotation:CGFloat = 0
  public var defaultRotation:CGFloat = 0
  
  public func applyTransform(){
    var transform = CATransform3DIdentity
    transform.m34 = CGFloat(1.0 / -1000)
    transform = CATransform3DTranslate(transform, translation.x + defaultTranslation.x, translation.y + defaultTranslation.y, translation.z + defaultTranslation.z)
    transform = CATransform3DRotate(transform, ((defaultRotation + xRotation) / 180) * CGFloat(M_PI), CGFloat(1.0), CGFloat(0.0), CGFloat(0.0))
    transform = CATransform3DTranslate(transform, translation3d.x, translation3d.y, translation3d.z)
    self.layer.transform = transform
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    layer.anchorPoint = CGPoint(x: 0.5, y: 0)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}


public class LZCardItemView: CardItemView {
  public var imageView:UIImageView
  public var gradientLayer = CAGradientLayer()
  public var maskLayer = CALayer()
  
  public var image:UIImage?{
    get{
      return imageView.image
    }
    set{
      imageView.image = newValue
    }
  }
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = bounds
    imageView.frame = bounds
    maskLayer.frame = bounds
  }
  
  override public init(frame: CGRect) {
    imageView = UIImageView(frame: frame)
    super.init(frame: frame)
    imageView.layer.cornerRadius = 18
    imageView.layer.masksToBounds = true
//    layer.shadowColor = UIColor.blackColor().CGColor
//    layer.shadowOpacity = 1.0
//    layer.shadowRadius = 100
    
    backgroundColor = UIColor.clearColor()
    opaque = false
    
    maskLayer.contents = UIImage(named: "mask")?.CGImage;
    layer.mask = maskLayer
    
    imageView.backgroundColor = UIColor.clearColor()
    addSubview(imageView)
//    gradientLayer.colors = [
//      UIColor(red: 288/255, green: 82/255, blue: 123/255, alpha: 0).CGColor,
//      UIColor(red: 288/255, green: 82/255, blue: 123/255, alpha: 0.1).CGColor,
//      UIColor(red: 288/255, green: 82/255, blue: 123/255, alpha: 1).CGColor,
//      UIColor(red: 288/255, green: 82/255, blue: 123/255, alpha: 1).CGColor,
//    ]
//    gradientLayer.startPoint = CGPoint(x:0.5, y:0.0)
//    gradientLayer.endPoint = CGPoint(x:0.5, y:1.0)
//    gradientLayer.frame = frame
//    layer.addSublayer(gradientLayer)
    
  }

  required public init?(coder aDecoder: NSCoder) {
    imageView = UIImageView(frame: CGRectZero)
    super.init(coder: aDecoder)
  }
}
