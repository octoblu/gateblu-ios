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
  
  var controllerManager = ControllerManager()
  var deviceManager : DeviceManager!
  @IBOutlet var deviceCollectionView: UICollectionView?
  @IBOutlet var uuidLabel: UILabel?
  @IBOutlet var uuidView: UIView?
  private let reuseIdentifier = "DeviceCell"
  
  override func viewDidLoad() {
    self.deviceManager = controllerManager.getDeviceManager()
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
    let deviceManager = controllerManager.getDeviceManager()
    deviceManager.start()
    println("started device manager")
    deviceManager.setOnDevicesChange({() -> () in
      self.deviceCollectionView!.reloadData()
  
      println("About to start devices...")
      for device in deviceManager.devices {
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
    println("Recognizing touch")
    if CGRectContainsPoint(self.uuidLabel!.bounds, touch.locationInView(self.view)) {
      return false
    }
    return true
  }
  
  func copyUuid(sender: UIView){
    let copyUuid = self.uuidLabel!.text
    println("Copying UUID \(copyUuid)")
    UIPasteboard.generalPasteboard().string = copyUuid
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return deviceManager.devices.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! DeviceCell
    
    let device = deviceManager.devices[indexPath.item]
    cell.label!.text = device.name
    
    let deviceImage: UIImage! = UIImage(named: device.getImagePath())
    
    cell.imageView!.image = deviceImage
    
    return cell
  }
}
