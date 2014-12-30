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
  
  var deviceCollectionView : UICollectionView?
  var deviceManager:DeviceManager!
  var cellSize : CGSize!

  override func viewDidLoad() {
      super.viewDidLoad()
      self.cellSize = CGSize(width: (self.view.bounds.width / 2) - 10, height: 120)
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
    cell.backgroundColor = UIColor.grayColor()
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
    let deviceImage: UIImage! = getDeviceImage(device)
//    deviceView.backgroundColor = UIColor(patternImage: deviceImage)
    let deviceImageView: UIImageView = UIImageView(image: deviceImage)
    deviceImageView.backgroundColor = UIColor.clearColor()
    deviceView.addSubview(deviceImageView)
    let labelHeight = (height / 4)
    let deviceLabelFrame = CGRect(x: 0, y: height -  (labelHeight + 10) , width: width - 10, height: labelHeight)
    let deviceLabel = UITextView(frame: deviceLabelFrame)
    
    deviceLabel.text = device!.name
    deviceLabel.textColor = UIColor.darkGrayColor()
    deviceLabel.backgroundColor = UIColor.clearColor()
    
    deviceView.addSubview(deviceLabel)
    
    return deviceView
  }
  
  func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
    
    let hasAlpha = false
    let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
    
    UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
    imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
    
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    return scaledImage
  }
  
  func getDeviceImage(device : Device!) -> UIImage {
    var heightScale : CGFloat
    var widthScale : CGFloat
    
    let file = device.getImagePath()
    var iconImage : UIImage! = UIImage(named: file)

    if iconImage.size.height > iconImage.size.width {
      heightScale = 1
      widthScale = iconImage.size.width / iconImage.size.height
    } else {
      widthScale = 1
      heightScale = iconImage.size.height / iconImage.size.width
    }
    let widthSize = widthScale * self.cellSize.width
    let heightSize = heightScale * self.cellSize.height
    
    NSLog("device dimensions: \(widthSize) x \(heightSize)")
    NSLog("cell dimensions: \(self.cellSize.width) x \(self.cellSize.height)")
    return imageResize(iconImage, sizeChange: CGSize(width: widthSize, height: heightSize))
  }
  
}
