//
//  PageViewController.swift
//  CardTableView
//
//  Created by Luke Zhao on 2015-04-18.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit


class PageViewController: UIViewController {
  
  @IBOutlet weak var countLabel: UILabel!
  @IBOutlet weak var toolbar: UIToolbar!
  @IBOutlet weak var mainView: UIView!
  
  var viewIndex = 0
  
  override func viewWillAppear(animated: Bool) {
    countLabel.text = "\(viewIndex)"
  }
  
  var thumbnail:UIImage{
    return mainView.takeSnapshot()
  }
}
