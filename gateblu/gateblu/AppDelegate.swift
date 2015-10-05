//
//  AppDelegate.swift
//  gateblu
//
//  Created by Koshin on 12/17/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import UIKit
import LNRSimpleNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  var deviceManager:DeviceManager!
  var authController: AuthController!

  func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
    return true
  }
  
  func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
    return true
  }

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
    UIApplication.sharedApplication().statusBarStyle = .LightContent
    if (deviceManager == nil) {
      deviceManager = DeviceManager()
    }
    if authController == nil {
      authController = AuthController()
    }
    LNRSimpleNotifications.sharedNotificationManager.notificationsPosition = LNRNotificationPosition.Bottom
    LNRSimpleNotifications.sharedNotificationManager.notificationsBackgroundColor = UIColor.darkGrayColor()
    LNRSimpleNotifications.sharedNotificationManager.notificationsTitleTextColor = UIColor.whiteColor()
    LNRSimpleNotifications.sharedNotificationManager.notificationsBodyTextColor = UIColor.whiteColor()
    LNRSimpleNotifications.sharedNotificationManager.notificationsSeperatorColor = UIColor.grayColor()
    
    if let options = launchOptions {
      if var _: NSArray = options[UIApplicationLaunchOptionsBluetoothCentralsKey] as? NSArray {
        // Awake as Bluetooth Central
        // No further logic here, will be handled by centralManager willRestoreState
        print("_--_ Did Wake Central Manager -__-")
        return true
      }
    }
    
    return true
  }
  
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    self.deviceManager.backgroundDevices()
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    print("THE GATEBLU HAS BEGAN BACKGROUND ACTIVITY")
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
      
    self.deviceManager.stopBackgroundDevices()
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    self.deviceManager.disconnectAll()
  }
  
}

