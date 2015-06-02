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
import DZNEmptyDataSet

class ViewController: UIViewController, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
  
  var controllerManager = ControllerManager()
  var deviceManager : DeviceManager!
  @IBOutlet var deviceCollectionView: UICollectionView?
  @IBOutlet var uuidLabel: UILabel?
  @IBOutlet var uuidView: UIView?
  private let reuseIdentifier = "DeviceCell"
  
  var loading = true
  
  override func viewDidLoad() {
    self.deviceManager = controllerManager.getDeviceManager()
    super.viewDidLoad()
    self.deviceCollectionView!.emptyDataSetSource = self
    self.deviceCollectionView!.emptyDataSetDelegate = self
    self.startDeviceManager()
  }
  
  override func viewDidAppear(animated: Bool) {
    SVProgressHUD.showWithStatus("Starting Gateblu...")
    self.addGestures()
    super.viewDidAppear(animated)
  }
  
  func setUuidLabel() {
    let authController = controllerManager.getAuthController()
    self.uuidLabel!.text = authController.uuid
  }
  
  func startDeviceManager() {
    let deviceManager = controllerManager.getDeviceManager()
    deviceManager.start()
    println("started device manager")
    deviceManager.setOnDevicesChange({() -> () in
      self.loading = false
      self.setUuidLabel()
      self.deviceCollectionView!.reloadData()
      println("Devices changed!")
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
    
    let values = [
      "imageUrl": device.getRemoteImageUrl()
    ]
    let html = Template.getTemplateFromBundle("device", replaceValues: values)
    cell.webView!.loadHTMLString(html, baseURL: NSURL(fileURLWithPath:"http://app.octoblu.com"))
    cell.webView!.scrollView.scrollEnabled = false
    cell.webView!.scrollView.bounces = false
    
    return cell
  }
  
  
  func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
    return NSAttributedString(string: "No Devices")
  }
  
  func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
    let robotNumber = arc4random_uniform(9) + 1;
    return UIImage(named: "robot\(robotNumber).png")
  }
  
  func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
    return !loading
  }
}
