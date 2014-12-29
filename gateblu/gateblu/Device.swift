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
  var name:String
  var online:Bool
  var type:String
  var connector:String
    
  init(uuid: String, token: String, name: String, online : Bool, type: String, connector: String) {
    self.uuid = uuid
    self.token = token
    self.name = name
    self.online = online
    self.type = type
    self.connector = connector
  }
  
  init(device : Dictionary<String, AnyObject>) {
    self.uuid = device["uuid"] as String
    self.token = device["token"] as String
    self.name = device["name"] as String
    self.online = device["online"] as Bool
    self.type = device["type"] as String
    self.connector = device["connector"] as String
  }
  
}