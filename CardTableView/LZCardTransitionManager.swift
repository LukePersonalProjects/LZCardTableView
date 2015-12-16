//
//  TransitionManager.swift
//  Cutify
//
//  Created by Luke Zhao on 2015-04-12.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit


// This transition will present the viewcontroller without running any animation.
// It is used when the app first launch, and we want to get into child
// view controller seemlessly
class LZCardInstantPresentTransition: NSObject, UIViewControllerAnimatedTransitioning{
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    let container = transitionContext.containerView()!
    let cardVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! LZCardViewController
    let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
    container.backgroundColor = toVC.view.backgroundColor
    container.addSubview(toVC.view)
    if let selectedCardIndex =  cardVC.selectedCardIndex{
      if selectedCardIndex < cardVC.tableView.cards.count{
        //existing card
        cardVC.tableView.openCard(cardVC.tableView.cards[selectedCardIndex], duration: 0.0){
          transitionContext.completeTransition(true)
        }
      }else{
        //new card
        cardVC.tableView.openNewCard(0.0) {
          transitionContext.completeTransition(true)
        }
      }
    }else{
      assertionFailure("Must select a card")
    }
  }
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
    return 0.0
  }
}


class LZCardPresentTransition: NSObject, UIViewControllerAnimatedTransitioning{
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    let container = transitionContext.containerView()!
    let cardVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! LZCardViewController
    let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! PageViewController
    
    container.addSubview(cardVC.view)
    container.addSubview(toVC.view)
    
    let duration = self.transitionDuration(transitionContext)
    
    if let selectedCardIndex = cardVC.selectedCardIndex{
      // create a image view to fade in the view content
      let image = toVC.thumbnail
      let imageView = UIImageView(frame: container.frame);
      imageView.image = image
      func completion(){
        // cleanup, this function is run after the animation completes
        toVC.view.alpha = 1
        imageView.removeFromSuperview()
        transitionContext.completeTransition(true)
      }
      let card:LZCardItemView
      if selectedCardIndex < cardVC.tableView.cards.count{
        // we are opening up a existing card. let the cardView help us
        // animate the opening the card
        card = cardVC.tableView.cards[selectedCardIndex]
        cardVC.tableView.openCard(card, duration: duration, completion:completion)
      }else{
        // we are opening up a new card.
        card = cardVC.tableView.openNewCard(duration, completion:completion)
      }
      // add imageview to the card and fade it in
      card.addSubview(imageView)
      imageView.alpha = 0
      toVC.view.alpha = 0
      UIView.animateWithDuration(duration, animations: {
        imageView.alpha = 1
      })
    }else{
      assertionFailure("Must select a card")
    }
  }
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
    return 0.4
  }
}
class LZCardDismissTransition: NSObject, UIViewControllerAnimatedTransitioning{
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    let container = transitionContext.containerView()!
    let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! PageViewController
    let cardVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! LZCardViewController
    
    container.addSubview(cardVC.view)
    container.addSubview(fromVC.view)
    
    let duration = self.transitionDuration(transitionContext)
    if let index = cardVC.selectedCardIndex{
      // animate toolbar fade out
      fromVC.view.alpha = 0
      
      // animate card close
      let card = cardVC.tableView.cards[index]
      cardVC.tableView.closeCard(card, duration: duration) {
        transitionContext.completeTransition(true)
      }
    }else{
      transitionContext.completeTransition(true)
    }
  }
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
    return 0.7
  }
}
