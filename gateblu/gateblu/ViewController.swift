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
import SwiftyJSON

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
  
  var controllerManager = ControllerManager()
  var deviceManager : DeviceManager!
  private let reuseIdentifier = "DeviceCell"
  var loading = true
  
  @IBOutlet var deviceCollectionView: UICollectionView?
  @IBOutlet var uuidLabel: UILabel?
  @IBOutlet var uuidView: UIView?
  @IBOutlet var stopAndStart: UIBarButtonItem?
  @IBOutlet var navigationBar: UINavigationBar?
  @IBAction func startOrStopGateblu(sender: UIButton){
    if deviceManager.stopped {
      stopAndStart = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Pause, target: self, action: "startOrStopGateblu:")
      self.loading = true
      SVProgressHUD.showWithStatus("Starting Gateblu...")
      deviceManager.startGateblu()
    } else {
      deviceManager.stopGateblu()
      stopAndStart = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Play, target: self, action: "startOrStopGateblu:")
    }
    stopAndStart?.tintColor = UIColor.whiteColor()
    navigationBar?.topItem?.leftBarButtonItem = stopAndStart
  }
  @IBAction func createActionMenu(sender: UIBarButtonItem){
    let alertController = UIAlertController(title: "Actions", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
    let copyUuidAction = UIAlertAction(title: "Copy Uuid", style: .Default) { (action) in
      self.copyUuid();
    }
    alertController.addAction(copyUuidAction)
    let copyTokenAction = UIAlertAction(title: "Copy Token", style: .Default) { (action) in
      self.copyToken();
    }
    alertController.addAction(copyTokenAction)
    let copyMeshbluJSONAction = UIAlertAction(title: "Copy Meshblu.json", style: .Default) { (action) in
      self.copyMeshbluJSON();
    }
    alertController.addAction(copyMeshbluJSONAction)
    let resetGatebluAction = UIAlertAction(title: "Reset Gateblu", style: .Destructive) { (action) in
      self.resetGateblu();
    }
    alertController.addAction(resetGatebluAction)
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
    }
    alertController.addAction(cancelAction)
    if let popoverController = alertController.popoverPresentationController {
      popoverController.barButtonItem = sender
    }
    self.presentViewController(alertController, animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    self.deviceManager = controllerManager.getDeviceManager()
    super.viewDidLoad()
    self.deviceCollectionView!.emptyDataSetSource = self
    self.deviceCollectionView!.emptyDataSetDelegate = self
    self.startDeviceManager()
  }
  
  override func viewDidAppear(animated: Bool) {
    SVProgressHUD.showWithStatus("Starting Gateblu...")
    super.viewDidAppear(animated)
  }
  
  func resetGateblu(){
    var alert = UIAlertController(title: "Reset Gateblu", message: "Are you sure you want to reset this gateblu?", preferredStyle: UIAlertControllerStyle.Alert)
    let alertAction = UIAlertAction(title: "Reset", style: UIAlertActionStyle.Destructive, handler: { action in
      println("reset gateblu")
      self.resetGatebluNow()
    })
    alert.addAction(alertAction)
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
    alert.addAction(cancelAction)
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  func setUuidLabel() {
    let authController = controllerManager.getAuthController()
    self.uuidLabel!.text = authController.uuid
  }
  
  func resetGatebluNow(){
    SVProgressHUD.showWithStatus("Resetting...")
    self.loading = true
    self.deviceManager.stopGateblu()
    self.deviceCollectionView!.reloadData()
    let authController = ControllerManager().getAuthController()
    authController.reset()
    authController.register({
      self.startDeviceManager()
    })
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
  
  func copyUuid(){
    let uuid = controllerManager.getAuthController().uuid!
    println("Copying uuid \(uuid)")
    UIPasteboard.generalPasteboard().string = uuid
  }
  
  func copyToken(){
    let token = controllerManager.getAuthController().token!
    println("Copying token \(token)")
    UIPasteboard.generalPasteboard().string = token
  }
  
  func copyMeshbluJSON(){
    let uuid = controllerManager.getAuthController().uuid!
    let token = controllerManager.getAuthController().token!
    let meshbluConfig = ["uuid": uuid, "token": token, "server": "meshblu.octoblu.com", "port": 443]
    let meshbluJSON = JSON(meshbluConfig)
    let rawMeshbluJSON = meshbluJSON.rawString()!
    println("Copying meshblu.json \(rawMeshbluJSON)")
    UIPasteboard.generalPasteboard().string = rawMeshbluJSON
  
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if deviceManager.stopped {
      return 0
    }
    return deviceManager.devices.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! DeviceCell
    
    let device = deviceManager.devices[indexPath.item]
    cell.device = device
    cell.label!.text = device.name
    
    let imageUrl = device.getRemoteImageUrl()
    let values = [
      "imageUrl": imageUrl
    ]
    let html = Template.getTemplateFromBundle("device", replaceValues: values)
    cell.webView!.loadHTMLString(html, baseURL: NSURL(fileURLWithPath:"http://app.octoblu.com"))
    cell.webView!.scrollView.scrollEnabled = false
    cell.webView!.scrollView.bounces = false
    
    return cell
  }
  
  
  func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
    if deviceManager.stopped {
      return NSAttributedString(string: "Gateblu Stopped")
    }
    return NSAttributedString(string: "No Devices")
  }
  
  func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
    if deviceManager.stopped {
      return nil
    }
    let robotNumber = arc4random_uniform(9) + 1;
    return UIImage(named: "robot\(robotNumber).png")
  }
  
  func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
    return deviceManager.stopped || !loading
  }
}
