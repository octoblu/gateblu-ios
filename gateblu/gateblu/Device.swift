//
//  Device.swift
//  gateblu
//
//  Created by Koshin on 12/18/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import WebKit
import SwiftyJSON

class Device {
  var uuid:String
  var token:String
  var name:String?
  var online:Bool
  var type:String?
  var connector:String?
  var logo:String?
  var initializing:Bool
  var webViewController:DeviceViewController!
  let notSoSmartRobots : [String] = ["robot1", "robot2", "robot3", "robot4", "robot5", "robot6"]
  let soSmartDevices : [String] = ["blink1", "bean", "hue", "generic"]
  
  init(uuid: String, token: String, online: Bool, initializing: Bool, name: String?, type: String?, connector: String?, logo: String?) {
    self.uuid = uuid
    self.token = token
    self.name = name
    self.type = type
    self.online = online
    self.connector = connector
    self.initializing = initializing
    self.logo = logo
    self.setDefaults()
    self.webViewController = DeviceViewController(self)
  }
  
  init(json: JSON) {
    self.uuid = json["uuid"].stringValue
    self.token = json["token"].stringValue
    self.online = json["online"].boolValue
    self.initializing = json["initializing"].boolValue
    self.name = json["name"].string
    self.type = json["type"].string
    self.connector = json["connector"].string
    self.logo = json["logo"].string
    self.setDefaults()
    self.webViewController = DeviceViewController(self)
  }
  
  func update(device: Dictionary<String, AnyObject>){
    self.uuid = device["uuid"] as! String
    self.name = device["name"] as! String?
    let online = device["online"] as! Bool?
    self.online = online == true
    let initializing = device["initializing"] as! Bool?
    self.initializing = initializing == true
    self.type = device["type"] as! String?
    setDefaults()
    self.start()
  }
  
  func setName(name:String?){
    if name == nil || name == "" {
      self.name = "Unkown Name"
    }else{
      self.name = name
    }
  }
  
  func getName() -> String {
    if self.initializing {
      return "[Initializing]"
    }
    if name == nil || name == "" {
      return "[Unknown Name]"
    }
    return name!
  }
  
  func setDefaults(){
    if self.name == nil {
      self.name = self.connector
    }
    if self.connector == nil {
      self.connector = ""
    }
    if self.logo == nil {
      self.logo = getRemoteImageUrl()
    }
  }
  
  func start() {
    self.webViewController.reload()
  }
  
  func stop() {
    let view = self.webViewController.view
    view.removeFromSuperview()
  }
  
  func getImagePath() -> String {
    let parsedType = self.type!.componentsSeparatedByString(":")
    _ = parsedType[0]
    let file = parsedType[1]
    if soSmartDevices.contains(file) {
      return file + ".png"
    } else {
      let randomIndex = abs(self.type!.hash) % notSoSmartRobots.count
      return notSoSmartRobots[randomIndex];
    }
  }
  
  func getRemoteImageUrl() -> String {
    if self.logo != nil {
      return self.logo!
    }
    let parsedType = self.type!.componentsSeparatedByString(":")
    let folder = parsedType[0]
    let file = parsedType[1]
    let urlString = "https://ds78apnml6was.cloudfront.net/\(folder)/\(file).svg"
  
    return urlString
  }
  
  func wakeUp() {
    self.webViewController.wakeIfNotRecentlyAwoken()
  }
  
}