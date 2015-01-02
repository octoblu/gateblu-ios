//
//  AppDelegate.swift
//  gateblu
//
//  Created by Koshin on 12/17/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var deviceManager:DeviceManager!
    var backgroundSecondsCounter = 0
    let lockQueue = dispatch_queue_create("com.octoblu.LockQueue", nil)

    func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
      return true
    }
    
    func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
      return true
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        NSLog("RISE UP FROM THE DEPTHS OF HELL!")
        if (deviceManager == nil) {
            deviceManager = DeviceManager()
        }
        if let options = launchOptions {
            self.backgroundSecondsCounter = 0
          if var centralManagerIdentifiers: NSArray = options[UIApplicationLaunchOptionsBluetoothCentralsKey] as? NSArray {
            // Awake as Bluetooth Central
            // No further logic here, will be handled by centralManager willRestoreState
            NSLog("_--_ Did Wake Central Manager -__-")
            return true
          }
        }
      
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//      goBackground()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
      NSLog("THE GATEBLU HAS BEGAN BACKGROUND ACTIVITY")
    }
    
    func goBackground() {
        var task = UIBackgroundTaskIdentifier()
        let app = UIApplication.sharedApplication()
        let backgroundTaskHandler = {
            () -> Void in
            app.endBackgroundTask(task)
            task = UIBackgroundTaskInvalid
        }
      task = app.beginBackgroundTaskWithExpirationHandler(backgroundTaskHandler)
      self.backgroundSecondsCounter = NSInteger.max
        bgLoop: while true {
            objc_sync_enter(self)
                self.backgroundSecondsCounter--
                if(self.backgroundSecondsCounter < 60 || self.backgroundSecondsCounter % 60 == 0) {
                    NSLog("Remaining background seconds: \(self.backgroundSecondsCounter)")
                }
                if (self.backgroundSecondsCounter <= 0){
                    NSLog("Quitting Background")
                    break bgLoop
                }
            objc_sync_exit(self)
            let fgFunc = {
                () -> Void in
                NSLog("IN UITHREAD")
                let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let controller = appDelegate.window?.rootViewController as ViewController
                let view = controller.view as UIView
                let newView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                view.addSubview(newView)
            }
            dispatch_sync(dispatch_get_main_queue(), fgFunc);
            NSThread.sleepForTimeInterval(1)
        }
        
        app.endBackgroundTask(task)
        task = UIBackgroundTaskInvalid
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        self.backgroundSecondsCounter = 0
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("BACK FROM THE DEAD")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.deviceManager.disconnectAll()
    }


}

