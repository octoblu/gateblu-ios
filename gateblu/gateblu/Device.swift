//
//  Device.swift
//  gateblu
//
//  Created by Koshin on 12/18/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation



class Device {
    
  var uuid:String
  var token:String
  var name:String?
  var online:Bool
  var type:String?
  var connector:String?
  let notSoSmartRobots : Array<String> = ["robot1", "robot2", "robot3", "robot4", "robot5", "robot6"]
  let soSmartDevices : Array<String> = ["blink1", "bean", "hue", "generic"]
    
  init(uuid: String, token: String, name: String, online : Bool, type: String, connector: String) {
    self.uuid = uuid
    self.token = token
    self.name = name
    self.online = online
    self.type = type
    self.connector = connector
    setDefaults()
  }
  
  init(device : Dictionary<String, AnyObject>) {
    self.uuid = device["uuid"] as String
    self.token = device["token"] as String
    self.name = device["name"] as String?
    var online = device["online"] as Bool?
    self.online = online == true
    self.type = device["type"] as String?
    self.connector = device["connector"] as String?
    setDefaults()
  }
  
  func update(device: Dictionary<String, AnyObject>){
    self.uuid = device["uuid"] as String
    self.name = device["name"] as String?
    var online = device["online"] as Bool?
    self.online = online == true
    self.type = device["type"] as String?
    setDefaults()
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
  
}