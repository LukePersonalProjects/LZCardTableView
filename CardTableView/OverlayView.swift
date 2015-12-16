//
//  OverlayView.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-11-23.
//  Copyright © 2015 SoySauce. All rights reserved.
//

import UIKit




class OverlayView: UIView {
  
  //// Color Declarations
  let line = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
  let fill = UIColor(red: 0.572, green: 0.788, blue: 1.000, alpha: 0.455)

  var show:Bool = false{
    didSet{
      if show{
        UIView.animateWithDuration(0.3, animations: { () -> Void in
          self.alpha = 1
        })
      }else{
        UIView.animateWithDuration(0.3, animations: { () -> Void in
          self.alpha = 0
        })
      }
    }
  }

  override func drawRect(rect: CGRect) {
    //// General Declarations
    let context = UIGraphicsGetCurrentContext()
    
    //// Bezier Drawing
    CGContextSaveGState(context)
    
    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(topLeft)
    bezierPath.addLineToPoint(topRight)
    bezierPath.addLineToPoint(bottomRight)
    bezierPath.addLineToPoint(bottomLeft)
    bezierPath.addLineToPoint(topLeft)
    bezierPath.closePath()
    fill.setFill()
    bezierPath.fill()
    line.setStroke()
    bezierPath.lineWidth = 1
    bezierPath.stroke()
    
    CGContextRestoreGState(context)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.opaque = false
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

  var topLeft: CGPoint = CGPointMake(10, 20), topRight: CGPoint = CGPointMake(30, 20), bottomLeft: CGPoint = CGPointMake(10, 30), bottomRight: CGPoint = CGPointMake(20, 30)
  func updatePoints(topLeft: CGPoint, topRight: CGPoint,
    bottomLeft: CGPoint, bottomRight: CGPoint){
      self.topLeft = topLeft
      self.topRight = topRight
      self.bottomLeft = bottomLeft
      self.bottomRight = bottomRight
      self.setNeedsDisplay()
  }
}
