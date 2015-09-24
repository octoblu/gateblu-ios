//
//  NotificationMessageHandler.swift
//  gateblu
//
//  Created by Jade Meskill on 1/7/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation
import WebKit

class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler {

  func userContentController(_userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    let name = message.name
    switch name {
      case "deviceConfig":
        print("ONCONFIG: \(message.body)")
        let responseObject = message.body as! Dictionary<String, AnyObject>
        if let device: AnyObject = responseObject["device"] {
          self.updateDevice(device as! Dictionary<String, AnyObject>)
        }
      case "managerConfig":
        print("MANAGER_DEBUG: \(message.body)")
      case "connectorNotification":
        print("CONNECTOR_DEBUG: \(message.body)")
      default:
        print("SOME_DEBUG: \(message.body)")
    }
  }
  
  func updateDevice(deviceDictionary: Dictionary<String, AnyObject>){
    let deviceManager = ControllerManager().getDeviceManager()
    let uuid = deviceDictionary["uuid"] as! String
    let name = deviceDictionary["name"] as! String?
    let type = deviceDictionary["type"] as! String?
    let logo = deviceDictionary["logo"] as! String?
    let initializing = deviceDictionary["initializing"] as! Bool
    let online = deviceDictionary["online"] as! Bool
    deviceManager.updateDeviceByUuid(uuid, name: name, logo: logo, type: type, initializing: initializing, online: online)
  }
}