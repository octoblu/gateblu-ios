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
//    self.setUuidAndToken_test()
    println("UUID \(uuid) & Token \(token)")
  }
  
  func register(onSuccess: () -> ()){
    let meshblu = Meshblu(uuid: nil, token: nil)
    meshblu.register({ (uuid: String, token: String) -> () in
      println("Registered \(uuid) \(token)")
      self.setUuidAndToken(uuid, token: token)
      onSuccess()
    })
  }
  
  func setUuidAndToken_test(){
    self.uuid = "930e0016-76d6-4282-9ede-b555c8e74c02"
    self.token = "30c718cb326a636f28869081fb15c85c9d994bfb"
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