//
//  LZCardViewController.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-14.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit

class LZCardViewController: UIViewController {
  @IBOutlet weak var tableView: LZCardView!
  var transitionManager = LZCardTransitionManager()
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let vc = segue.destinationViewController as? UIViewController{
      vc.transitioningDelegate = transitionManager
    }
  }
  
  var firstBoot = true
  override func viewWillAppear(animated: Bool) {
    if firstBoot{
      view.alpha = 0
      view.opaque = false
    }else{
      view.alpha = 1
      view.opaque = true
    }
    super.viewWillAppear(animated)
  }
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    if firstBoot{
      performSegueWithIdentifier("Show Page", sender: self)
      firstBoot = false
    }
  }
  
  @IBAction func addPage(sender: AnyObject) {
    tableView.addEmptyCard(animate: true)
  }
  @IBAction func unwindToCardView(segue: UIStoryboardSegue) {}
}

extension LZCardViewController: LZCardViewDelegate{
  func numberOfCard() -> Int{
    return 0
  }
  func imageForCardAtIndex(index:Int) -> UIImage?{
    return nil
  }
  func cardTableView(cardTableView: LZCardView, didSelectCardAtIndex index: Int) {
    self.performSegueWithIdentifier("Show Page", sender: self)
  }
}

extension LZCardViewController: UITableViewDataSource{
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
    cell.backgroundColor = .clearColor()
    return cell
  }
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }
}