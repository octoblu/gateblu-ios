//
//  Device.swift
//  gateblu
//
//  Created by Koshin on 12/18/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import WebKit

class Device {
  var uuid:String
  var token:String
  var name:String?
  var online:Bool
  var type:String?
  var connector:String?
  var webViewController:DeviceViewController!
  let notSoSmartRobots : [String] = ["robot1", "robot2", "robot3", "robot4", "robot5", "robot6"]
  let soSmartDevices : [String] = ["blink1", "bean", "hue", "generic"]
  
  init(device : Dictionary<String, AnyObject>) {
    self.uuid = device["uuid"] as String
    self.token = device["token"] as String
    self.name = device["name"] as String?
    var online = device["online"] as Bool?
    self.online = online == true
    self.type = device["type"] as String?
    self.connector = device["connector"] as String?
    setDefaults()
    self.webViewController = DeviceViewController(self)
  }
  
  init(uuid: String, token: String, online: Bool, name: String?, type: String?, connector: String?) {
    self.uuid = uuid
    self.token = token
    self.name = name
    self.type = type
    self.online = online
    self.connector = connector
  }
  
  func update(device: Dictionary<String, AnyObject>){
    self.uuid = device["uuid"] as String
    self.name = device["name"] as String?
    var online = device["online"] as Bool?
    self.online = online == true
    self.type = device["type"] as String?
    setDefaults()
    self.webViewController.reload()
  }
  
  func setDefaults(){
    if self.name == nil {
      self.name = self.connector
    }
    if self.connector == nil {
      self.connector = ""
    }
  }
  
  func getImagePath() -> String {
    let parsedType = split(self.type!) {$0 == ":"}
    let folder = parsedType[0]
    let file = parsedType[1]
    if contains(soSmartDevices, file) {
      return file + ".png"
    } else {
      var randomIndex = abs(self.type!.hash) % notSoSmartRobots.count
      return notSoSmartRobots[randomIndex];
    }
  }
  
  func wakeUp() {
    self.webViewController.wakeIfNotRecentlyAwoken()
  }
  
  class func fromJSONArray(devicesJSON: [JSON]) -> [Device] {
    return devicesJSON.map({ self.fromJSON($0) })
  }
  
  class func fromJSON(deviceJSON: JSON) -> Device {
    return Device(
      uuid: deviceJSON["uuid"].stringValue,
      token: deviceJSON["token"].stringValue,
      online: deviceJSON["online"].boolValue,
      name: deviceJSON["name"].string,
      type: deviceJSON["type"].string,
      connector: deviceJSON["connector"].string)
  }
}