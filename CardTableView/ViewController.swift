//
//  ViewController.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-14.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var tableView: LZCardTableView!
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func addPage(sender: AnyObject) {
    tableView.addEmptyCard(animate: true)
  }

}

extension ViewController: UITableViewDelegate{
  
}

extension ViewController: UITableViewDataSource{
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
    cell.backgroundColor = .clearColor()
    return cell
  }
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 40
  }
}