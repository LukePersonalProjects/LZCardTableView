//
//  LZCardTableView.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-14.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

let cardTapRotation:CGFloat = 4
class LZCardTableView: UITableView {
  
  var cards:[LZCardView] = []
  
  override init(frame: CGRect, style: UITableViewStyle){
    super.init(frame: frame, style: style)
    setup()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  func addEmptyCard(animate:Bool = false){
    let card = LZCardView(frame: frame)
    cards.append(card)
    backgroundView?.addSubview(card)
    card.backgroundColor = .whiteColor()
    
    let longPressGR = UILongPressGestureRecognizer(target: self, action: "longPress:")
    longPressGR.minimumPressDuration = 0.8
    card.addGestureRecognizer(longPressGR)
    
    let panGR = UIPanGestureRecognizer(target: self, action: "pan:")
    panGR.maximumNumberOfTouches = 1
    panGR.delegate = self
    card.addGestureRecognizer(panGR)
    
    if animate{
      resetCardAtIndex(cards.count-1)
      card.translation3d = Point(y: 500)
      card.applyTransform()
      card.alpha = 0
      UIView.animateBounceWithDuration(0.5){
        card.alpha = 1
        card.translation3d = Point()
        card.applyTransform()
      }
      UIView.animateWithDuration(0.3){
        self.resetAllExcept(card)
      }
    }else{
      resetAll()
    }
  }
  
  var pressingCard:LZCardView?
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    if let card = hitTest((touches.first as! UITouch).locationInView(self), withEvent: event) as? LZCardView{
      card.xRotation = cardTapRotation
      UIView.animateEaseInWithDuration(0.3, animations: {
        card.applyTransform()
      })
      pressingCard = card
    }
    super.touchesBegan(touches, withEvent: event)
  }
  override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
    super.touchesMoved(touches, withEvent: event)
    if let card = pressingCard where panInitialLocation == nil && reorderingInitialLocation == nil{
      card.xRotation = 0
      UIView.animateEaseOutWithDuration(0.3, animations: {
        card.applyTransform()
      })
      pressingCard = nil
    }
  }
  override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
    super.touchesEnded(touches, withEvent: event)
    if let card = pressingCard{
      card.xRotation = 0
      UIView.animateEaseOutWithDuration(0.3, animations: {
        card.applyTransform()
      })
      pressingCard = nil
    }
  }
  
  func setup(){
    contentInset = UIEdgeInsets(top: 667, left: 0, bottom: 0, right: 0);
    backgroundView = UIView(frame: frame)
    
    //fake data
    for i in 0...5{
      addEmptyCard(animate: false)
    }
  }
  
  override var contentOffset:CGPoint{
    didSet{
      for card in cards{
        card.frame = frame
      }
      resetAll()
    }
  }
  override var bounds:CGRect{
    didSet{
//      resetAll()
    }
  }
  
  func resetAll(){
    for i in 0..<cards.count{
      resetCardAtIndex(i)
    }
  }
  func resetAllExcept(card: LZCardView){
    for i in 0..<cards.count{
      if cards[i] != card{
        resetCardAtIndex(i)
      }
    }
  }
  func resetCardAtIndex(i:Int){
    let offset = contentInset.top + contentOffset.y
    let rotationOffset:CGFloat = offset < 0 ? offset / 40 : 0
    let card = cards[i]
    card.layer.removeAllAnimations()
    card.xRotation = rotationOffset
    card.translation = Point()
    card.translation3d = Point()
    card.defaultRotation = cardRotation
    card.defaultTranslation = translationForCard(CGFloat(i))
    card.darkenLayer.opacity = 0
    card.alpha = 1
    card.applyTransform()
  }
  
  var cardRotation:CGFloat{
    if cards.count == 0{
      return -20
    }
    return -60 + 40 / (CGFloat(cards.count) - panProgress)
  }
  var cardSeperation:CGFloat{
    if cards.count == 0{
      return 400
    }
    return 100 + 400 / (CGFloat(cards.count) - panProgress)
  }
  var cardZOffset:CGFloat{
    if cards.count == 0{
      return 120
    }
    return 135 / (CGFloat(cards.count) - panProgress)
  }
  func translationForCard(cardIndex:CGFloat) -> Point{
    let topOffset:CGFloat = 60
    let scrollOffset = -contentInset.top - contentOffset.y
    let rotationOffset = sin((cardRotation) / 180 * CGFloat(M_PI)) * frame.size.height/4
    let y = scrollOffset + topOffset + rotationOffset + cardIndex * cardSeperation
    return Point(x:0, y:y, z:-330 + cardZOffset)
  }
  
  // MARK: long press (reorder)
  var reorderingInitialLocation:CGPoint?
  
  func longPress(sender:UILongPressGestureRecognizer){
    var reorderingCard = sender.view as! LZCardView
    if sender.state == .Began{
      reorderingInitialLocation = sender.locationInView(self)
      UIView.animateEaseInWithDuration(0.5){
        for card in self.cards{
          if card != reorderingCard{
            card.translation3d = Point(y: 50)
            card.darkenLayer.opacity = 1
            card.xRotation = 6
            card.applyTransform()
          }
        }
      }
    }else if sender.state == .Changed{
      let current = sender.locationInView(self)
      let reorderingLocation = CGPoint(x: current.x - reorderingInitialLocation!.x, y: current.y - reorderingInitialLocation!.y)
      
      
      let cardIndex = find(cards, reorderingCard)!
      var swappedCard:LZCardView? = nil
      if cardIndex != cards.count - 1 && reorderingLocation.y + reorderingCard.defaultTranslation.y > cards[cardIndex+1].defaultTranslation.y - cardSeperation/2{
        //swap with next
        swappedCard = cards[cardIndex+1]
        cards[cardIndex+1] = reorderingCard
        cards[cardIndex] = swappedCard!
      }else if cardIndex != 0 && reorderingLocation.y + reorderingCard.defaultTranslation.y < cards[cardIndex-1].defaultTranslation.y + cardSeperation/2{
        //swap with prev
        swappedCard = cards[cardIndex-1]
        cards[cardIndex-1] = reorderingCard
        cards[cardIndex] = swappedCard!
      }
      if let swappedCard = swappedCard{
        let index1 = (backgroundView!.subviews as NSArray).indexOfObject(reorderingCard)
        let index2 = (backgroundView!.subviews as NSArray).indexOfObject(swappedCard)
        backgroundView!.exchangeSubviewAtIndex(index1, withSubviewAtIndex: index2)
        UIView.animateEaseOutWithDuration(0.2, animations: {
          swappedCard.translation3d = Point(y: 400)
          swappedCard.alpha = 0.4
          swappedCard.applyTransform()
          }, completion: { (completed) -> Void in
            if self.reorderingInitialLocation == nil{
              //we stopped reordering, just let it reset. dont run another transform animation
              return
            }
            swappedCard.applyTransform()
            UIView.animateBounceWithDuration(0.6){
              swappedCard.alpha = 1.0
              swappedCard.translation3d = self.reorderingInitialLocation == nil ? Point() : Point(y: 50)
              swappedCard.applyTransform()
            }
        })
        swappedCard.defaultTranslation = translationForCard(CGFloat(cardIndex))
      }
      reorderingCard.translation = Point(y: reorderingLocation.y)
      reorderingCard.applyTransform()
    }else if sender.state == .Ended{
      reorderingInitialLocation = nil
      UIView.animateEaseOutWithDuration(0.5, animations:{
        self.resetAll()
      })
    }
  }
  
  
  // MARK: slide to delete
  var panInitialLocation:CGPoint?
  var panProgress:CGFloat = 0
  
  func pan(sender:UIPanGestureRecognizer){
    var panCard = sender.view as! LZCardView
    if sender.state == .Began{
      panInitialLocation = sender.locationInView(self)
      panCard.xRotation = cardTapRotation
      UIView.animateEaseInWithDuration(0.3){
        panCard.applyTransform()
      }
      panProgress = 0
    }else if sender.state == .Changed{
      let current = sender.locationInView(self)
      var panLocation = CGPoint(x: current.x - panInitialLocation!.x, y: current.y - panInitialLocation!.y)
      panProgress = min(1, max(0, -panLocation.x/frame.size.width))
      panCard.translation3d = Point(x: panLocation.x > 0 ? panLocation.x/3 : panLocation.x)
      panCard.applyTransform()
      
      var panCardIndex = cards.count
      for i in 0..<cards.count{
        let card = cards[i]
        if card == panCard{
          panCardIndex = i
        }else{
          if i < panCardIndex{
            card.defaultTranslation = translationForCard(CGFloat(i))
          }else{
            card.defaultTranslation = translationForCard(CGFloat(i) - panProgress)
          }
          card.defaultRotation = cardRotation
          card.applyTransform()
        }
      }
    }else if sender.state == .Ended{
      let current = sender.locationInView(self)
      var panLocation = CGPoint(x: current.x - panInitialLocation!.x, y: current.y - panInitialLocation!.y)
      let v = sender.velocityInView(self)
      if v.x < 0 && panLocation.x < 0{
        let cardIndex = find(cards,panCard)!
        cards.removeAtIndex(cardIndex)
        let pointsToMove = frame.width * 2
        let duration:Double = Double(pointsToMove / v.x)
        UIView.animateWithDuration(duration, animations: {
          panCard.translation3d = Point(x: panLocation.x - pointsToMove)
          panCard.applyTransform()
        }, completion: { (completed) -> Void in
          panCard.removeFromSuperview()
        })
      }
      panProgress = 0
      UIView.animateEaseOutWithDuration(0.5){
        self.resetAll()
      }
    }
  }
}

extension LZCardTableView: UIGestureRecognizerDelegate{
  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let gr = gestureRecognizer as? UIPanGestureRecognizer, card = gr.view as? LZCardView{
      let velocity = gr.velocityInView(self)
      return abs(velocity.x) > abs(velocity.y)
    }
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
}
