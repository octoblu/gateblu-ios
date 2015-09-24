//
//  LoginController.swift
//  gateblu
//
//  Created by Peter DeMartini on 6/2/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation

class AuthController : NSObject {
  var uuid : String?
  var token : String?
  var userDefaults: NSUserDefaults
  var onReady: (() -> ())?
  var gatebluDevice : GatebluDevice?
  
  override init(){
    userDefaults = NSUserDefaults.standardUserDefaults()
    super.init()
  }
  
  func isAuthenticated() -> Bool {
    let uuid = userDefaults.stringForKey("uuid")
    let token = userDefaults.stringForKey("token")
    
    return uuid != nil && token != nil
  }
  
  func setFromDefaults() {
    self.setUuidAndToken(userDefaults.stringForKey("uuid")!, token: userDefaults.stringForKey("token")!)
    if onReady != nil {
      onReady!()
    }
    print("UUID \(uuid) & Token \(token)")
  }
  
  func register(onSuccess: () -> ()){
    let meshblu = getGatebluDevice()
    meshblu.register({ (uuid: String, token: String) -> () in
      print("Registered \(uuid) \(token)")
      self.setUuidAndToken(uuid, token: token)
      if self.onReady != nil {
        self.onReady!()
      }
      onSuccess()
    })
  }
  
  func onDeviceAuth(onReady: ()->()){
    self.onReady = onReady
  }
  
  func getGatebluDevice() -> GatebluDevice {
    if self.gatebluDevice == nil {
      if !isAuthenticated() {
        self.gatebluDevice = GatebluDevice(meshbluConfig: [:])
      } else {
        let device = [
          "uuid" : self.uuid!,
          "token" : self.token!
        ]
        self.gatebluDevice = GatebluDevice(meshbluConfig: device)
      }
    }
    return self.gatebluDevice!
  }
  
  func setUuidAndToken(uuid: String, token: String) {
    self.uuid = uuid
    self.token = token
    userDefaults.setObject(uuid, forKey: "uuid")
    userDefaults.setObject(token, forKey: "token")
  }
  
  func reset(){
    self.uuid = nil
    self.token = nil
    userDefaults.removeObjectForKey("uuid")
    userDefaults.removeObjectForKey("token")
  }
}