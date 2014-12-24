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
    println(message.body)
  }
}

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIWebViewDelegate {
  
  @IBOutlet var deviceCollectionView : UICollectionView?
  var deviceManager:DeviceManager!

  override func viewDidLoad() {
      super.viewDidLoad()
      println("Starting Manager")
      let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
      deviceManager = appDelegate.deviceManager
      deviceManager.start()
      startDeviceCollectionView()
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func startDeviceCollectionView(){
    let deviceWidth = self.view.bounds.width
    let deviceHeight = self.view.bounds.height
    
    let frame = CGRect(x: 0, y: 60, width: deviceWidth, height: deviceHeight - 60)
    let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    
    layout.itemSize = CGSize(width: (deviceWidth / 2) - 10, height: 120)
    deviceCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
    deviceCollectionView!.delegate = self
    deviceCollectionView!.dataSource = self
    deviceCollectionView!.backgroundColor = UIColor.whiteColor()
    deviceCollectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    
    self.view.addSubview(deviceCollectionView!)
    
    
    let buttonView = UIButton(frame: CGRect(x: 0, y: self.view.bounds.height - 70, width: 100, height: 50))
      
    buttonView.addTarget(self, action: Selector("killEverything"), forControlEvents: UIControlEvents.TouchUpInside)
    buttonView.setTitle("KILLL IT!", forState: UIControlState.Normal)
    buttonView.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
    
    self.view.addSubview(buttonView)
  }
  
  func killEverything(){
    kill(getpid(), SIGKILL)
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return deviceManager.devices.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = deviceCollectionView!.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
    cell.backgroundColor = UIColor.lightGrayColor()
    cell.addSubview(createDeviceView(cell, indexPath: indexPath))
    return cell
  }
  
  func createDeviceView(cellView: UICollectionViewCell, indexPath: NSIndexPath) -> UIView {
    let height = cellView.bounds.height
    let width = cellView.bounds.width
    let deviceView = UIView(frame: cellView.frame)
    let device: Device? = deviceManager.devices[indexPath.item]
    NSLog("Adding Device view \(device!.name)")
    
    if device == nil {
      return deviceView
    }
    let labelHeight = (height / 4)
    let deviceLabelFrame = CGRect(x: 0, y: height -  (labelHeight + 10) , width: width - 10, height: labelHeight)
    let deviceLabel = UITextView(frame: deviceLabelFrame)
    
    deviceLabel.text = device!.name
    deviceLabel.textColor = UIColor.darkGrayColor()
    
    deviceView.addSubview(deviceLabel)
    
    return deviceView
  }
  
}


