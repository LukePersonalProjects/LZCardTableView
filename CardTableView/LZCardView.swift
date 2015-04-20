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
  optional func cardView(cardView:LZCardView, canDeleteCardAtIndex: Int) -> Bool
  optional func cardView(cardView:LZCardView, commitDeletionAtIndex: Int)
}

public enum LZCardAnimation{
  case Automatic, PopIn, SlideLeft, SlideRight, Fade, None
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
          insertCard(newCardWithImage(image: nil), atIndex: i)
        }
      }else{
        for i in numCards..<cards.count{
          cards.removeAtIndex(i)
        }
      }
      for i in 0..<numCards{
        cards[i].image = dataSource.cardView?(self, imageForCardAtIndex: i)
      }
      resetSize()
      resetAll()
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
  public func insertCardsAtIndexes(indexes:[Int], withCardAnimation:LZCardAnimation, completion:() -> Void = {}){
    if let dataSource = cardViewDataSource{
      let numCards = dataSource.numberOfCardsInCardView(self)
      if numCards != indexes.count + cards.count{
        assertionFailure("Number of cards after insert must match")
      }
      for i in indexes{
        let image = dataSource.cardView?(self, imageForCardAtIndex: i)
        insertCard(newCardWithImage(image: image), atIndex: i)
      }
      
      if paning{
        resetSize(moveUp: false)
      }else{
        resetSize()
      }
      if withCardAnimation != .None{
        for i in indexes{
          resetCardAtIndex(i)
          let card = cards[i]
          card.translation3d = Point(y: 500)
          card.applyTransform()
          card.alpha = 0
        }
        
        // move existing card into their position
        UIView.animateWithDuration(0.2,animations:{
          self.resetAllExcept(indexes)
        })
        // popIn Animation
        UIView.animateBounceWithDuration(0.5,animations:{
          self.resetAll(indexes: indexes)
        })
      }else{
        resetAll()
      }
    }
  }
  public func deleteCardsAtIndexes(indexes:[Int], withCardAnimation:LZCardAnimation, completion:() -> Void = {}){
    
  }
  public func reloadCardsAtIndexes(indexes:[Int], withCardAnimation:LZCardAnimation, completion:() -> Void = {}){
    
  }
  private func newCardWithImage(image:UIImage? = nil) -> LZCardItemView{
    let card = LZCardItemView(frame: frame)
    card.image = image
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
    return card
  }
  private func insertCard(card:LZCardItemView, atIndex:Int){
    if paning && atIndex <= panCardIndex!{
      panCardIndex = panCardIndex! + 1
    }
    backgroundView?.insertSubview(card, atIndex: atIndex)
    cards.insert(card, atIndex: atIndex)
  }
  
  // MARK: - reset functions
  
  // resetSize should be called before resetAll or resetCard
  // since this updates contentOffset
  // which is a parameter for resetAll
  // it shouldn't be animated
  func resetSize(moveUp:Bool = true){
    let oldTop = contentInset.top
    listenToScroll = false
    let newTopInset = max(frame.size.height, CGFloat(cards.count)*cardSeperation)
    contentInset = UIEdgeInsets(top: newTopInset, left: 0, bottom: 0, right: 0);
    if !moveUp{
      let newTop = contentInset.top
      contentOffset.y -= newTop - oldTop
    }
    listenToScroll = true
  }
  func resetAll(indexes: [Int]? = nil){
    if let indexes = indexes{
      for i in indexes{
        resetCardAtIndex(i)
      }
    }else{
      for i in 0..<cards.count{
        resetCardAtIndex(i)
      }
    }
  }
  func resetAllExcept(indexes: [Int]){
    for i in 0..<cards.count{
      if !contains(indexes, i){
        resetCardAtIndex(i)
      }
    }
  }
  func resetCardAtIndex(i:Int){
    if paning && i == panCardIndex!{
      let panCard = cards[panCardIndex!]
      let tempPanProgess = panProgress
      panProgress = 0
      panCard.defaultTranslation = translationForCard(CGFloat(panCardIndex!))
      panCard.defaultRotation = cardRotation
      panProgress = tempPanProgess
      panCard.applyTransform()
      return;
    }
    let card = cards[i]
    let offset = contentInset.top + contentOffset.y
    let rotationOffset:CGFloat = offset < 0 ? offset / 40 : 0
    card.layer.removeAllAnimations()
    card.xRotation = rotationOffset
    card.translation = Point()
    card.translation3d = Point()
    card.defaultRotation = cardRotation
    if paning{
      if i < panCardIndex{
        card.defaultTranslation = translationForCard(CGFloat(i))
      }else if i > panCardIndex{
        card.defaultTranslation = translationForCard(CGFloat(i) - panProgress)
      }
    }else{
      card.defaultTranslation = translationForCard(CGFloat(i))
    }
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
    return reorderingGR?.view as? LZCardItemView
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
  var panCardCanBeDeleted = false
  var paning:Bool{
    return panInitialLocation != nil
  }
  var panCardIndex:Int?
  
  func pan(sender:UIPanGestureRecognizer){
    let panCard = sender.view as! LZCardItemView
    if sender.state == .Began{
      panProgress = 0
    }else if sender.state == .Changed{
      let current = sender.locationInView(self)
      var panLocation = CGPoint(x: current.x - panInitialLocation!.x, y: current.y - panInitialLocation!.y)
      let panAdjustedDx = panLocation.x > 0 || !panCardCanBeDeleted ? panLocation.x/3 : panLocation.x
      panProgress = panCardCanBeDeleted ? min(1, max(0, -panAdjustedDx/frame.size.width)) : 0
      panCard.translation3d = Point(x: panAdjustedDx)
      resetAll()
    }else if sender.state == .Ended{
      let current = sender.locationInView(self)
      var panLocation = CGPoint(x: current.x - panInitialLocation!.x, y: current.y - panInitialLocation!.y)
      let v = sender.velocityInView(self)
      if v.x < 0 && panLocation.x < 0 && panCardCanBeDeleted{
        let cardIndex = find(cards, panCard)!
        cardViewDataSource?.cardView?(self, commitDeletionAtIndex: cardIndex)
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
      panCardCanBeDeleted = false
      panProgress = 0
      resetSize()
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
          panCardIndex = find(cards, card)
          panInitialLocation = gr.locationInView(self)
          panCardCanBeDeleted = cardViewDataSource?.cardView?(self, canDeleteCardAtIndex: panCardIndex!) ?? false
          return true
        }
        return false
      }
      return true
    }
    
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
}
