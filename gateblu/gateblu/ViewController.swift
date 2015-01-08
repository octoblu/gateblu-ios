//
//  ViewController.swift
//  gateblu
//
//  Created by Jade Meskill on 1/7/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation

class ViewController: UIViewController, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  var deviceManager:DeviceManager!
  @IBOutlet weak var deviceCollectionView: UICollectionView?
  @IBOutlet weak var uuidLabel: UILabel?
  @IBOutlet weak var uuidView: UIView?
  
  var cellSize : CGSize!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addGestures()
    startDeviceManager()
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var uuid = userDefaults.stringForKey("uuid")
    if uuid == nil {
      uuid = ""
    }
    self.uuidLabel!.text = uuid
    
    
    self.deviceCollectionView!.delegate = self
    self.deviceCollectionView!.dataSource = self
    self.deviceCollectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    self.cellSize = CGSize(width: 150, height: 150)
  }
  
  func startDeviceManager() {
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    deviceManager = appDelegate.deviceManager
    deviceManager.start()
    deviceManager.setOnDevicesChange({() -> () in
      self.deviceCollectionView!.reloadData()
      
      for device in self.deviceManager.devices {
        //        device.start()
      }
    })
  }
  
  func addGestures() {
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: "copyUuid:")
    doubleTapGesture.delegate = self
    doubleTapGesture.numberOfTapsRequired = 2
    doubleTapGesture.numberOfTouchesRequired = 1
    self.uuidView!.addGestureRecognizer(doubleTapGesture)
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
    NSLog("Recognizing touch")
    if CGRectContainsPoint(self.uuidLabel!.bounds, touch.locationInView(self.view)) {
      return false
    }
    return true
  }
  
  func copyUuid(sender: UIView){
    let copyUuid = self.uuidLabel!.text
    NSLog("Copying UUID \(copyUuid)")
    UIPasteboard.generalPasteboard().string = copyUuid
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.deviceManager.devices.count
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
