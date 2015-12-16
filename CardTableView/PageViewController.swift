//
//  PageViewController.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-18.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit


class PageViewController: CameraViewController {
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  @IBAction func shoot(sender: AnyObject) {
    print("shoot")
    super.takeShot { (image) -> Void in
      self.thumbnail = UIImage(CIImage: image)
      self.performSegueWithIdentifier("edit", sender: self);
    }
  }
  
  var thumbnail:UIImage = UIImage(named: "c2")!
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "edit"{
      let vc = segue.destinationViewController as! EditViewController
      vc.image = self.thumbnail
    }
  }
}
