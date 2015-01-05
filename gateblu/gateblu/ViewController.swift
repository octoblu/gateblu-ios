//
//  ViewController.swift
//  gateblu
//
//  Created by Koshin on 12/17/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import UIKit
import WebKit


class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler {
  func userContentController(_userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    NSLog("DEBUG: \(message.body)")
  }
}

let TOP_BAR_MARGIN : CGFloat = 60
let CELL_PADDING : CGFloat = 5
let CELL_HEIGHT : CGFloat = 160

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIWebViewDelegate {
  
  var deviceCollectionView : UICollectionView?
  var deviceManager:DeviceManager!
  var cellSize : CGSize!

  override func viewDidLoad() {
    super.viewDidLoad()
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    deviceManager = appDelegate.deviceManager
    startDeviceCollectionView()
    deviceManager.start()
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func startDeviceCollectionView(){
    let deviceWidth = self.view.bounds.width
    let deviceHeight = self.view.bounds.height
    
    let frame = CGRect(x: 0, y: TOP_BAR_MARGIN, width: deviceWidth, height: deviceHeight - TOP_BAR_MARGIN)
    let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: CELL_PADDING, left: CELL_PADDING, bottom: CELL_PADDING, right: CELL_PADDING)
    let cellWidth : CGFloat = (frame.width / 2) - (CELL_PADDING * 2)
    self.cellSize = CGSize(width: cellWidth, height: CELL_HEIGHT)
    layout.itemSize = self.cellSize
    deviceCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
    deviceCollectionView!.delegate = self
    deviceCollectionView!.dataSource = self
    deviceCollectionView!.backgroundColor = UIColor.whiteColor()
    deviceCollectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    
    self.view.addSubview(deviceCollectionView!)
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return deviceManager.devices.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = deviceCollectionView!.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
    cell.backgroundColor = UIColor.clearColor()
    let deviceView = createDeviceView(cell, indexPath: indexPath)
    let width = NSLayoutConstraint(item: deviceView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
    let height = NSLayoutConstraint(item: deviceView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
    
    cell.addSubview(deviceView)
    
    cell.addConstraint(width)
    cell.addConstraint(height)
    
    return cell
  }
  
  func createDeviceView(cellView: UICollectionViewCell, indexPath: NSIndexPath) -> UIView {
    let height = cellSize.height
    let width = cellSize.width
    let deviceView = UIView()
    
    let device: Device? = deviceManager.devices[indexPath.item]
    if device == nil {
      return deviceView
    }
    let deviceImage: UIImage! = UIImage(named: device!.getImagePath())
    let deviceImageView: UIImageView! = UIImageView(image: deviceImage)
    deviceImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
    deviceImageView.backgroundColor = UIColor.clearColor()
    
    let centerx = NSLayoutConstraint(item: deviceImageView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: deviceView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
    
    deviceView.setTranslatesAutoresizingMaskIntoConstraints(false)
    deviceView.addSubview(deviceImageView)
    
    deviceView.addConstraint(centerx)
    
    let deviceLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.cellSize.width, height: 20))
    deviceLabel.text = device!.name
    deviceLabel.textAlignment = NSTextAlignment.Center
    deviceLabel.textColor = UIColor.darkGrayColor()
    
    deviceView.addSubview(deviceLabel)
  
    let labelTop = NSLayoutConstraint(item: deviceLabel, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: deviceImageView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 10)
    deviceView.addConstraint(labelTop)
    return deviceView
  }
  
}
