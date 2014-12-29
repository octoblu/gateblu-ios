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
    
    var devices : [Device] = [
        //Device(uuid: "920e6261-5f0c-11e4-b71e-c1e4be219849", token: "e2emvhdmsi7ctyb9dzvv7zzmrgnfjemi", name : "Bean 1"),
        //Device(uuid: "d58749e0-87d3-11e4-94c5-ab09a6c94ef5", token: "02ui6u933qxquayviks0za2n7acyp66r", name : "Bean 2")
       // Device(uuid: "b1af9aa1-8aca-11e4-b562-d165f522e099", token: "091lmzxlwwkd42t9s817hi3ou6z2gldi", name : "FINDME")
    ]
  
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
        for device in self.devices {
          let userContentController = WKUserContentController()
          let handler = NotificationScriptMessageHandler()
          userContentController.addScriptMessageHandler(handler, name: "notification")
          let configuration = WKWebViewConfiguration()
          configuration.userContentController = userContentController
          let rect:CGRect = CGRectMake(0,0,0,0)
          let webView = DeviceView(frame: rect)
          webView.setDevice(device)
          view.addSubview(webView)
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
      }
    }
  
  func parseDevices(rawDevices : Array<AnyObject>) -> Array<Device> {
    NSLog("parseDevices: \(rawDevices)")
    var devices = Array<Device>()
    
    for rawDevice in rawDevices {
      devices.append(Device(device: rawDevice as Dictionary<String, AnyObject>))
    }
    return devices
  }
}
