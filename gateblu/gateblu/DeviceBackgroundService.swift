//
//  DeviceBackgroundService.swift
//  gateblu
//
//  Created by Jade Meskill on 1/3/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation

class DeviceBackgroundService: NSObject {
    var backgroundTimeout = 0
    
    func doUpdate (callback:()->()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.setMaxTimeout()
            let taskID = self.beginBackgroundUpdateTask()
            
            while true {
                println("Doing background stuff")
                objc_sync_enter(self)
                self.backgroundTimeout--
                objc_sync_exit(self)
                if self.backgroundTimeout <= 0 {
                    break
                }
                
                callback()
                NSThread.sleepForTimeInterval(1)
            }
            
            // Do something with the result
            
            self.endBackgroundUpdateTask(taskID)
            
        })
    }
    
    func clearTimeout() {
        objc_sync_enter(self)
        self.backgroundTimeout = 0
        objc_sync_exit(self)
    }
    
    func setMaxTimeout() {
        objc_sync_enter(self)
        self.backgroundTimeout = NSInteger.max
        objc_sync_exit(self)
    }
    
    func beginBackgroundUpdateTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
    }
    
    func endBackgroundUpdateTask(taskID: UIBackgroundTaskIdentifier) {
        UIApplication.sharedApplication().endBackgroundTask(taskID)
    }
    
}