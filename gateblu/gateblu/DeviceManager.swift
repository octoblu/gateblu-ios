//
//  DeviceManager.swift
//  gateblu
//
//  Created by Jade Meskill on 12/22/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import WebKit


class DeviceManager {
    var gatebluService = GatebluService()
    var meshblu : Meshblu?
    
    var devices : [Device] = []
  
    init() {
      
    }
  
    func start() {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let controller = appDelegate.window?.rootViewController as ViewController
        let view = controller.view as UIView

        startMeshblu({ (configuration : Dictionary<String, AnyObject>) in
          var devices : AnyObject? = configuration["devices"]
          if devices == nil {
            devices = []
          }
          
          self.devices = self.parseDevices( devices as Array<AnyObject>);
          var deviceResponseCount = 0
          for device in self.devices {
            let userContentController = WKUserContentController()
            let handler = NotificationScriptMessageHandler()
            userContentController.addScriptMessageHandler(handler, name: "notification")
            let configuration = WKWebViewConfiguration()
            configuration.userContentController = userContentController
            let rect:CGRect = CGRectMake(0,0,0,0)
            let webView = DeviceView(frame: rect, configuration: configuration)
            webView.setDevice(device)
            view.addSubview(webView)
            
            self.meshblu!.getDevice(device.uuid, token: device.token, onSuccess: { (response : Dictionary<String, AnyObject>) in
              device.update(response)
              deviceResponseCount++
              if deviceResponseCount == self.devices.count {
                controller.deviceCollectionView!.reloadData();
              }
            })
            
          }
        })
      
    }
  
    func startMeshblu(onConfiguration : (configuration : Dictionary<String, AnyObject>) -> ()){
      let userDefaults = NSUserDefaults.standardUserDefaults()
      let uuid : String? = userDefaults.stringForKey("uuid")
      let token : String? = userDefaults.stringForKey("token")
      
      self.meshblu = Meshblu(uuid: uuid, token: token)
      
      if uuid == nil || token == nil {
        self.meshblu!.register({ (uuid: String, token : String) in
          NSLog("Registered uuid: \(uuid), token: \(token)")
          userDefaults.setObject(uuid, forKey: "uuid")
          userDefaults.setObject(token, forKey: "token")
          self.meshblu!.whoami(onConfiguration)
        })
      }else{
        NSLog("Already Registered")
        self.meshblu!.whoami(onConfiguration)
        self.meshblu!.goOnline()
      }
    }
  
  func parseDevices(rawDevices : Array<AnyObject>) -> Array<Device> {
    var devices = Array<Device>()
    
    for rawDevice in rawDevices {
      devices.append(Device(device: rawDevice as Dictionary<String, AnyObject>))
    }
    
    NSLog("devices from parseDevices: \(devices)")
    return devices
  }
}
