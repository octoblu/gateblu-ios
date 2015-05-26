//
//  ViewController.swift
//  gateblu
//
//  Created by Jade Meskill on 1/7/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD

class ViewController: UIViewController, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  var deviceManager:DeviceManager!
  @IBOutlet var deviceCollectionView: UICollectionView?
  @IBOutlet var uuidLabel: UILabel?
  @IBOutlet var uuidView: UIView?
  private let reuseIdentifier = "DeviceCell"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    SVProgressHUD.showWithStatus("Loading devices...")
    addGestures()
    startDeviceManager()
    setUuidLabel()
  }
  
  func setUuidLabel() {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var uuid = userDefaults.stringForKey("uuid")
    if uuid == nil {
      uuid = ""
    }
    self.uuidLabel!.text = uuid
  }
  
  func startDeviceManager() {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    deviceManager = appDelegate.deviceManager
    deviceManager.start()
    deviceManager.setOnDevicesChange({() -> () in
      self.deviceCollectionView!.reloadData()
      
      for device in self.deviceManager.devices {
        device.start()
      }
      
      SVProgressHUD.dismiss()
      
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
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! DeviceCell
    
    let device = self.deviceManager.devices[indexPath.item]
    cell.label!.text = device.name
    
    let deviceImage: UIImage! = UIImage(named: device.getImagePath())
    
    cell.imageView!.image = deviceImage
    
    return cell
  }
}
