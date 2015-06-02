//
//  ControllerManager.swift
//  gateblu
//
//  Created by Octoblu on 5/28/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import UIKit
import Foundation


class ControllerManager: NSObject {

  var appDelegate : AppDelegate!
  
  override init() {
    super.init()
    self.appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  }
    
  func getViewController() -> ViewController {
    let window = appDelegate.window!
    return window.rootViewController as! ViewController
  }
  
  func getDeviceManager() -> DeviceManager {
    return appDelegate.deviceManager!
  }
  
  func getAuthController() -> AuthController {
    return appDelegate.authController!
  }
  
}