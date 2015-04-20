//
//  LZCardView.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-14.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import Foundation
import UIKit

@objc protocol LZCardViewDelegate: UITableViewDelegate{
  optional func cardTableView(cardTableView:LZCardView, didSelectCardAtIndex index:Int);
}
@objc protocol LZCardViewDataSource: UITableViewDataSource{
  func numberOfCardsInCardView(cardView:LZCardView) -> Int
  optional func cardView(cardView:LZCardView, imageForCardAtIndex index:Int) -> UIImage?
}

public class LZCardView: UITableView {
  
  var cards:[LZCardItemView] = []
  
  // MARK: - tableview function overrides
  var cardViewDelegate:LZCardViewDelegate?{
    return delegate as? LZCardViewDelegate
  }
  var cardViewDataSource:LZCardViewDataSource?{
    return dataSource as? LZCardViewDataSource
  }
  
  var listenToScroll = true
  override public var contentOffset:CGPoint{
    didSet{
      if listenToScroll{
        for card in cards{
          card.frame = frame
        }
        resetAll()
      }
    }
  }

  override public func reloadData(){
    super.reloadData()
    if let dataSource = cardViewDataSource{
      let numCards = dataSource.numberOfCardsInCardView(self)
      if numCards > cards.count{
        for i in cards.count..<numCards{
          addEmptyCard(animate: false)
        }
      }else{
        for i in numCards..<cards.count{
          cards.removeAtIndex(i)
        }
      }
      resetSize()
      resetAll()
      for i in 0..<numCards{
        cards[i].image = dataSource.cardView?(self, imageForCardAtIndex: i)
      }
    }
  }
  
  // MARK: - Initializers
  override public init(frame: CGRect, style: UITableViewStyle){
    super.init(frame: frame, style: style)
    setup()
  }

  required public init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  func setup(){
    backgroundView = UIView(frame: frame)
    resetSize()
  }
  
  
  // MARK: - Add Card
  public func addEmptyCard(animate:Bool = false){
    addCard(nil, animate: animate)
  }
  public func addCard(image:UIImage?, animate:Bool = false){
    let card = LZCardItemView(frame: frame)
    card.image = image
    cards.append(card)
    backgroundView?.addSubview(card)
    card.backgroundColor = .whiteColor()
    
    let tapGR = UITapGestureRecognizer(target: self, action: "tap:")
    tapGR.delegate = self
    card.addGestureRecognizer(tapGR)
    
    let longPressGR = UILongPressGestureRecognizer(target: self, action: "longPress:")
    longPressGR.minimumPressDuration = 0.6
    longPressGR.delegate = self
    card.addGestureRecognizer(longPressGR)
    
    let panGR = UIPanGestureRecognizer(target: self, action: "pan:")
    panGR.maximumNumberOfTouches = 1
    panGR.delegate = self
    card.addGestureRecognizer(panGR)
    resetSize()
    if animate{
      resetCardAtIndex(cards.count-1)
      card.translation3d = Point(y: 500)
      card.applyTransform()
      card.alpha = 0
      UIView.animateBounceWithDuration(0.5,animations:{
        card.alpha = 1
        card.translation3d = Point()
        card.applyTransform()
      })
      UIView.animateWithDuration(0.3,animations:{
        self.resetAllExcept(card)
      })
    }else{
      resetAll()
    }
  }
  
  // MARK: - reset functions
  
  // resetSize should be called before resetAll or resetCard
  // since this updates contentOffset
  // which is a parameter for resetAll
  // it shouldn't be animated
  func resetSize(){
    listenToScroll = false
    let newTopInset = max(frame.size.height, CGFloat(cards.count)*cardSeperation)
    contentInset = UIEdgeInsets(top: newTopInset, left: 0, bottom: 0, right: 0);
    listenToScroll = true
  }
  func resetAll(){
    for i in 0..<cards.count{
      resetCardAtIndex(i)
    }
  }
  func resetAllExcept(card: LZCardItemView){
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
  
  // MARK: - data calculation
  var cardRotation:CGFloat{
    if cards.count == 0{
      return -20
    }
    return -50 + 40 / (CGFloat(cards.count) - panProgress)
  }
  var cardSeperation:CGFloat{
    if cards.count == 0{
      return 600
    }
    return 100 + 500 / (CGFloat(cards.count) - panProgress)
  }
  func translationForCard(cardIndex:CGFloat) -> Point{
    let topOffset:CGFloat = 60
    let scrollOffset = -contentInset.top - contentOffset.y
    let y = scrollOffset + topOffset + cardIndex * cardSeperation
    return Point(x:0, y:y, z:-50)
  }
  
  // MARK: - touch
  override public func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    if let card = hitTest((touches.first as! UITouch).locationInView(self), withEvent: event) as? LZCardItemView{
      card.xRotation = 2
      card.translation3d = Point(z:-20)
      UIView.animateEaseInWithDuration(0.2, animations: {
        card.applyTransform()
      })
    }
    super.touchesBegan(touches, withEvent: event)
  }
  
  // MARK: - reorder cards
  var reorderingInitialLocation:CGPoint?
  var reorderingGR:UILongPressGestureRecognizer?
  var reorderScrollTimer:NSTimer?
  var reorderScrollSpeed:CGFloat = 0{
    didSet{
      if reorderScrollSpeed == 0{
        reorderScrollTimer?.invalidate()
        reorderScrollTimer = nil
      }else if reorderScrollTimer == nil{
        reorderScrollTimer = NSTimer.scheduledTimerWithTimeInterval(1/60, target: self, selector: "scroll", userInfo: nil, repeats: true)
      }
    }
  }
  var reorderingCard:LZCardItemView!{
    return reorderingGR!.view as! LZCardItemView
  }
  var reordering:Bool{
    return reorderingInitialLocation != nil
  }
  func scroll(){
    if reorderScrollSpeed != 0{
      listenToScroll = false
      let maxScroll = CGFloat(cards.count)*cardSeperation + 200 - contentInset.top - frame.height
      let minScroll = -contentInset.top
      var newYOffset = max(min(contentOffset.y + reorderScrollSpeed, maxScroll), minScroll)
      if contentOffset.y > maxScroll{
        // we are below the maximum scroll point, only allow scroll up
        if reorderScrollSpeed > 0{
          return;
        }
        newYOffset = contentOffset.y + reorderScrollSpeed
      }
      let diff = newYOffset - contentOffset.y
      contentOffset.y = newYOffset
      listenToScroll = true
      for i in 0..<cards.count{
        if cards[i] != reorderingCard{
          cards[i].defaultTranslation = translationForCard(CGFloat(i))
          cards[i].applyTransform()
        }else{
          reorderingCard!.defaultTranslation.y -= diff
        }
      }
      swapIfNeeded()
    }
  }
  func swapIfNeeded(){
    let reorderingLocation = reorderingGR?.locationInView(self)
    let yOffset = reorderingLocation!.y - reorderingInitialLocation!.y
    let cardIndex = find(cards, reorderingCard)!
    var swappedCard:LZCardItemView? = nil
    if cardIndex != cards.count - 1 && yOffset + reorderingCard.defaultTranslation.y > cards[cardIndex+1].defaultTranslation.y - cardSeperation/2{
      //swap with next
      swappedCard = cards[cardIndex+1]
      cards[cardIndex+1] = reorderingCard
      cards[cardIndex] = swappedCard!
    }else if cardIndex != 0 && yOffset + reorderingCard.defaultTranslation.y < cards[cardIndex-1].defaultTranslation.y + cardSeperation/2{
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
          if !self.reordering{
            //we stopped reordering, just let it reset. dont run another transform animation
            return
          }
          swappedCard.applyTransform()
          UIView.animateBounceWithDuration(0.6){
            swappedCard.alpha = 1.0
            swappedCard.translation3d = Point(x: 0, y: 50, z:-30)
            swappedCard.applyTransform()
          }
      })
      swappedCard.defaultTranslation = translationForCard(CGFloat(cardIndex))
    }
    reorderingCard.translation = Point(y: yOffset)
    reorderingCard.applyTransform()
  }
  func longPress(sender:UILongPressGestureRecognizer){
    if sender.state == .Began{
      reorderingGR = sender
      reorderingInitialLocation = sender.locationInView(self)
      UIView.animateEaseInWithDuration(0.25){
        for card in self.cards{
          if card != self.reorderingCard{
            card.translation3d = Point(x: 0, y: 50, z:-30)
            card.darkenLayer.opacity = 1
            card.xRotation = 2
            card.applyTransform()
          }
        }
      }
    }else if sender.state == .Changed{
      let locationOnScreen = sender.locationInView(nil)
      if locationOnScreen.y > frame.size.height - 150{
        reorderScrollSpeed = 5 + (locationOnScreen.y - (frame.size.height - 200))*0.05
      }else if locationOnScreen.y < 150{
        reorderScrollSpeed = -5 - (200 - locationOnScreen.y)*0.05
      }else{
        reorderScrollSpeed = 0
      }
      swapIfNeeded()
    }else if sender.state == .Ended{
      reorderScrollSpeed = 0
      reorderingInitialLocation = nil
      reorderingGR = nil
      UIView.animateEaseOutWithDuration(0.5, animations:{
        self.resetAll()
      })
    }
  }
  
  
  // MARK: - slide to delete
  var panInitialLocation:CGPoint?
  var panProgress:CGFloat = 0
  var paning:Bool{
    return panInitialLocation != nil
  }
  
  func pan(sender:UIPanGestureRecognizer){
    var panCard = sender.view as! LZCardItemView
    if sender.state == .Began{
      panCard.xRotation = 2
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
      panInitialLocation = nil
      panProgress = 0
      self.resetSize()
      UIView.animateEaseOutWithDuration(0.5, animations:{
        self.resetAll()
      })
    }
  }
  
  
  // MARK: - open & close card
  func tap(tapGR:UIGestureRecognizer){
    if let tappedCard = tapGR.view as? LZCardItemView, let cardIndex = find(self.cards, tappedCard){
      selectedCard = tappedCard
      cardViewDelegate?.cardTableView?(self, didSelectCardAtIndex: cardIndex)
    }
  }
  
  var lastOpenedTopOffset:CGFloat?
  public var selectedCard:LZCardItemView?
  public func openCard(card:LZCardItemView, duration:NSTimeInterval, completion:() -> Void){
    if let cardIndex = find(cards, card){
      listenToScroll = false
      UIView.animateEaseOutWithDuration(duration, animations: {
        for i in 0..<self.cards.count{
          if i < cardIndex{
            self.cards[i].translation = Point(y:-self.frame.height)
            self.cards[i].applyTransform()
          }else if i > cardIndex{
            self.cards[i].translation = Point(y:self.frame.height)
            self.cards[i].applyTransform()
          }
        }
        card.layer.transform = CATransform3DIdentity
        card.gradientLayer.opacity = 0
        self.lastOpenedTopOffset = self.contentOffset.y
        self.contentOffset.y = -self.frame.height
      }, completion: completion)
    }
  }
  
  public func closeCard(card:LZCardItemView, duration:NSTimeInterval, completion:() -> Void){
    if let cardIndex = find(cards, card){
      listenToScroll = false
      if selectedCard == nil || lastOpenedTopOffset == nil || card != selectedCard{
        selectedCard = card
        listenToScroll = false
        for i in 0..<self.cards.count{
          if i < cardIndex{
            self.cards[i].translation = Point(y:-self.frame.height)
            self.cards[i].applyTransform()
          }else if i > cardIndex{
            self.cards[i].translation = Point(y:self.frame.height)
            self.cards[i].applyTransform()
          }
        }
        card.layer.transform = CATransform3DIdentity
        card.gradientLayer.opacity = 0
        self.lastOpenedTopOffset = self.contentOffset.y
        self.contentOffset.y = -self.frame.height
      }
      listenToScroll = true
      UIView.animateBounceWithDuration(duration, animations: {
        card.gradientLayer.opacity = 1.0
        self.contentOffset.y = self.lastOpenedTopOffset!
      }, completion: completion)
      selectedCard = nil
      lastOpenedTopOffset = nil
    }
  }
}

extension LZCardView: UIGestureRecognizerDelegate{
  override public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let card = gestureRecognizer.view as? LZCardItemView{
      if paning || reordering{
        return false
      }
      if let gr = gestureRecognizer as? UIPanGestureRecognizer{
        let velocity = gr.velocityInView(self)
        if abs(velocity.x) > abs(velocity.y){
          panInitialLocation = gr.locationInView(self)
          return true
        }
        return false
      }
      return true
    }
    
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
}
