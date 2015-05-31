//
//  ViewController.swift
//  gateblu
//
//  Created by Koshin on 12/17/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import UIKit
import CoreBluetooth
import WebKit


class DeviceViewController: NSObject {
  let controllerManager = ControllerManager()
  
  var device:Device!
  var view:WKWebView!
  var lastAwoke:NSDate = NSDate()
  
  init(_ device: Device) {
    super.init()
    let userContentController = WKUserContentController()
    let handler = NotificationScriptMessageHandler()
    userContentController.addScriptMessageHandler(handler, name: "connectorNotification")
    userContentController.addScriptMessageHandler(handler, name: "deviceConfig")
    let configuration = WKWebViewConfiguration()
    configuration.userContentController = userContentController
    let rect:CGRect = CGRectMake(0,0,0,0)
    self.view = WKWebView(frame: rect, configuration: configuration)
    self.device = device
    startWebView()
  }
  
  func reload() {
    self.view.loadHTMLString(self.getJavascript(), baseURL: NSURL(string: "http://app.octoblu.com"))
  }
  
  func startWebView() {
    reload()
    let controller = controllerManager.getViewController()
    let parentView = controller.view as UIView
    parentView.addSubview(self.view)
    println("Started Device View!!!")
  }

  func getJavascript() -> String {
    let uuid = device.uuid
    let token = device.token
    let connector = device.connector!
    var htmlFilePath = NSBundle.mainBundle().pathForResource("connector", ofType:"html")!
    var htmlString = String(contentsOfFile: htmlFilePath, encoding: NSUTF8StringEncoding, error: nil)
    htmlString = htmlString!.stringByReplacingOccurrencesOfString("{{uuid}}", withString: uuid, options: nil, range: nil)
    htmlString = htmlString!.stringByReplacingOccurrencesOfString("{{token}}", withString: token, options: nil, range: nil)
    htmlString = htmlString!.stringByReplacingOccurrencesOfString("{{connector}}", withString: connector, options: nil, range: nil)
    return htmlString!
  }
  
  func wakeIfNotRecentlyAwoken() {
    let interval = self.lastAwoke.timeIntervalSinceNow
    if interval < 1 {
      wake()
    }
  }
  
  func wake() {
    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
      dispatch_async(dispatch_get_main_queue(), {
          self.view.evaluateJavaScript("function(){}()", completionHandler: nil)
      })
    }
    self.lastAwoke = NSDate()
  }
    
}


