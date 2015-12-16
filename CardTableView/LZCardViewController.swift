//
//  LZCardViewController.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-14.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit


enum Action:Int{
  case Insert,Reload,Delete
  var description:String{
    switch self{
    case .Insert:
      return "Insert"
    case .Reload:
      return "Reload"
    case .Delete:
      return "Delete"
    }
  }
}
class LZCardViewController: UIViewController {
  @IBOutlet weak var tableView: LZCardView!

  var presentTransition = LZCardPresentTransition()
  var dismissTransition = LZCardDismissTransition()
  
  var thumbnails:[UIImage?] = [UIImage(named: "c1"),UIImage(named: "c2"),UIImage(named: "c2"),UIImage(named: "c2"),UIImage(named: "c3")]
  
  var childViewController:PageViewController?
  
  // selectedCardIndex represent the card index for the child controller
  // that is currently (or will be) on screen. After setting this value,
  // call performSegueWithIdentifier:sender:, the transitionObject will then
  // grab this value and animate the corresponding card to show the 
  // child view controller
  // if selectedCardIndex is beyond the bounds of the existing cards,
  // the transition object will insert a new card and animate that on screen
  var selectedCardIndex:Int?

  @IBOutlet weak var actionButton: UIButton!
  
  var selectedAction:Action = .Insert{
    didSet{
      actionButton.setTitle(selectedAction.description, forState: .Normal)
      tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
    }
  }
  var selectedAnimation:LZCardAnimation = .Automatic{
    didSet{
      tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Fade)
    }
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .LightContent
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let vc = segue.destinationViewController as? PageViewController{
      childViewController = vc
      vc.transitioningDelegate = self
    }
  }
  
  var firstBoot = true
  override func viewWillAppear(animated: Bool) {
    if let childViewController = childViewController, selectedCardIndex = selectedCardIndex{
      // update the thumbnail image if we are coming from a child view controller
      thumbnails[selectedCardIndex] = childViewController.thumbnail
      tableView.reloadCardsAtIndexes([selectedCardIndex], withCardAnimation: .None, completion: nil)
    }
    
    // Hide the view when launching the app,
    // Since we want to go into child view controller directly
    // This ensures there is no glitch or sudden flash
//    view.hidden = firstBoot
    super.viewWillAppear(animated)
  }
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    if firstBoot{
      // directly go into a child controller.
//      selectedCardIndex = 0
//      thumbnails.append(nil)
//      performSegueWithIdentifier("Show Page", sender: self)
      firstBoot = false
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.contentInset = UIEdgeInsets(top: tableView.contentInset.top, left: 0, bottom: 44, right: 0)
  }
  var randomAnimation:LZCardAnimation{
    let animations:[LZCardAnimation] = [.Pop,.Fade,.SlideLeft,.SlideRight]
    return animations[Int(arc4random_uniform(7)) % animations.count]
  }
  @IBAction func addPage(sender: AnyObject) {
    selectedCardIndex = thumbnails.count
    thumbnails.append(nil)
    performSegueWithIdentifier("Show Page", sender: self)
  }
  
  @IBAction func doneBtnTapped(sender: AnyObject) {
    performSegueWithIdentifier("Show Page", sender: self)
  }
  
  
  @IBAction func actionBtnTapped(sender: AnyObject) {
    switch selectedAction{
    case .Insert:
      var indexes = [Int]()
      for i in 0..<Int(arc4random_uniform(10)){
        let max = UInt32(thumbnails.count+1)
        let index = Int(arc4random_uniform(max))
        thumbnails.insert(nil, atIndex: index)
        for i in 0..<indexes.count{
          if index <= indexes[i]{
            indexes[i] += 1
          }
        }
        indexes.append(index)
      }
      indexes.sortInPlace(<)
      print("Inserting \(indexes)")
      self.tableView.insertCardsAtIndexes(indexes, withCardAnimation: selectedAnimation, completion: nil)
    case .Reload:
      let cards = UInt32(thumbnails.count)
      var indexes = [Int]()
      for i in 0..<Int(arc4random_uniform(cards+1)){
        let max = UInt32(thumbnails.count)
        let index = Int(arc4random_uniform(max))
        if !indexes.contains(index){
          indexes.append(index)
        }
      }
      indexes.sortInPlace(<)
      print("Reloading \(indexes)")
      self.tableView.reloadCardsAtIndexes(indexes, withCardAnimation: selectedAnimation, completion: nil)
    case .Delete:
      let cards = UInt32(thumbnails.count)
      var indexes = [Int]()
      for i in 0..<Int(arc4random_uniform(cards+1)){
        let max = UInt32(thumbnails.count-1)
        let index = Int(arc4random_uniform(max))
        if !indexes.contains(index){
          indexes.append(index)
        }
      }
      indexes.sortInPlace(>)
      for i in indexes{
        thumbnails.removeAtIndex(i)
      }
      print("Deleting \(indexes)")
      self.tableView.deleteCardsAtIndexes(indexes, withCardAnimation: selectedAnimation, completion: nil)
    }
  }
  @IBAction func unwindToCardView(segue: UIStoryboardSegue) {}
}

extension LZCardViewController: UIViewControllerTransitioningDelegate{
  func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return firstBoot ? LZCardInstantPresentTransition() : presentTransition
  }
  func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return dismissTransition
  }
}

extension LZCardViewController: LZCardViewDataSource{
  func numberOfCardsInCardView(cardView: LZCardView) -> Int {
    return thumbnails.count
  }
  func cardView(cardView: LZCardView, imageForCardAtIndex index: Int) -> UIImage? {
    return thumbnails[index]
  }
  func cardView(cardView: LZCardView, canDeleteCardAtIndex index: Int) -> Bool {
    return true
  }
  func cardView(cardView: LZCardView, commitDeletionAtIndex index: Int) {
    thumbnails.removeAtIndex(index)
  }
  func cardView(cardView: LZCardView, sizeForCardAtIndex index: Int) -> CGSize {
    return CGSizeMake(cardView.frame.width, 250)
  }
}

extension LZCardViewController: LZCardViewDelegate{
  func cardTableView(cardTableView: LZCardView, didSelectCardAtIndex index: Int) {
    selectedCardIndex = index
    performSegueWithIdentifier("Show Page", sender: self)
  }
}

extension LZCardViewController: UITableViewDelegate{
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.section == 0{
      selectedAction = Action(rawValue: indexPath.row)!
    }else{
      selectedAnimation = LZCardAnimation(rawValue: indexPath.row)!
    }
  }
}
extension LZCardViewController: UITableViewDataSource{
  func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView(frame: CGRectMake(0, 0, view.frame.width, 50))
    let label = UILabel(frame: CGRectMake(16, 20, view.frame.width-16, 30))
    headerView.addSubview(label)
    label.font = UIFont.systemFontOfSize(12)
    label.text = self.tableView(tableView, titleForHeaderInSection: section)?.uppercaseString
    label.textColor = UIColor(white: 1, alpha: 0.5)
    return headerView
  }
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return section == 0 ? "Left button action" : "Animation"
  }
  func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 50
  }
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Action Cell", forIndexPath: indexPath) 
    let bgColorView = UIView()
    bgColorView.backgroundColor = UIColor(white: 1, alpha: 0.5)
    cell.selectedBackgroundView = bgColorView
    if indexPath.section == 0{
      let action = Action(rawValue: indexPath.row)!
      cell.textLabel?.text = "\(action.description) Cards"
      if action == selectedAction{
        cell.accessoryType = .Checkmark
      }else{
        cell.accessoryType = .None
      }
    }else{
      let animation = LZCardAnimation(rawValue: indexPath.row)!
      cell.textLabel?.text = animation.description
      if animation == selectedAnimation{
        cell.accessoryType = .Checkmark
      }else{
        cell.accessoryType = .None
      }
    }
    return cell
  }
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 2
  }
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? 3 : 6
  }
}