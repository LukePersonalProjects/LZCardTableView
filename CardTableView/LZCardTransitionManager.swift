//
//  TransitionManager.swift
//  Cutify
//
//  Created by Luke Zhao on 2015-04-12.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit

class LZCardTransitionManager: NSObject, UIViewControllerTransitioningDelegate  {
  var presenting = true
  func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    self.presenting = true
    return self
  }
  func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    self.presenting = false
    return self
  }
}

extension LZCardTransitionManager:UIViewControllerAnimatedTransitioning{
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    let container = transitionContext.containerView()
    if presenting{
      let cardVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! LZCardViewController
      let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
      
      container.addSubview(cardVC.view)
      
      let duration = self.transitionDuration(transitionContext)
      
      if let card = cardVC.tableView.selectedCard{
        toVC.view.alpha = 0
        card.addSubview(toVC.view)
        UIView.animateWithDuration(duration, animations: {
          toVC.view.alpha = 1
        })
        cardVC.tableView.openCard(card, duration: duration) {
          container.addSubview(toVC.view)
          transitionContext.completeTransition(true)
        }
      }else{
        container.addSubview(toVC.view)
        container.backgroundColor = toVC.view.backgroundColor
        toVC.view.alpha = 0
        UIView.animateWithDuration(duration, animations: {
          toVC.view.alpha = 1
        }){ (c) -> Void in
          transitionContext.completeTransition(true)
        }
      }
    }else{
      let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
      let cardVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! LZCardViewController
      
      container.addSubview(cardVC.view)
      
      let duration = self.transitionDuration(transitionContext)
      if let card = cardVC.tableView.selectedCard{
        fromVC.view.alpha = 1
        card.addSubview(fromVC.view)
        card.image = fromVC.view.takeSnapshot()
        UIView.animateWithDuration(duration, animations: {
          fromVC.view.alpha = 0
        })
        cardVC.tableView.closeCard(card, duration: duration) {
          fromVC.view.removeFromSuperview()
          transitionContext.completeTransition(true)
        }
      }else{
        transitionContext.completeTransition(true)
      }
    }
  }
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
    return presenting ? 0.4 : 0.7
  }
}
