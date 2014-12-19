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
  
  var gatebluService = GatebluService()
  @IBOutlet var deviceCollectionView : UICollectionView?
  
  var devices : [Device] = [
    Device(uuid: "920e6261-5f0c-11e4-b71e-c1e4be219849", token: "e2emvhdmsi7ctyb9dzvv7zzmrgnfjemi"),
    Device(uuid: "d58749e0-87d3-11e4-94c5-ab09a6c94ef5", token: "02ui6u933qxquayviks0za2n7acyp66r")
  ]

  override func viewDidLoad() {
      super.viewDidLoad()
      println("Starting Manager")
      startDeviceCollectionView()
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func startDeviceCollectionView(){
    let frame = CGRect(x: 0, y: 60, width: self.view.bounds.width, height: self.view.bounds.height - 60)
    let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    layout.itemSize = CGSize(width: 150, height: 100)
    deviceCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
    deviceCollectionView!.delegate = self
    deviceCollectionView!.dataSource = self
    deviceCollectionView!.backgroundColor = UIColor.whiteColor()
    deviceCollectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    
    self.view.addSubview(deviceCollectionView!)
    
    for device in devices {
      let userContentController = WKUserContentController()
      let handler = NotificationScriptMessageHandler()
      userContentController.addScriptMessageHandler(handler, name: "notification")
      let configuration = WKWebViewConfiguration()
      configuration.userContentController = userContentController
      let rect:CGRect = CGRectMake(0,0,0,0)
      let webView = DeviceView(frame: rect)
      webView.setDevice(device)
      self.view.addSubview(webView)
    }
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return devices.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = deviceCollectionView!.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
    cell.backgroundColor = UIColor.grayColor()
    return cell
  }
  
}


