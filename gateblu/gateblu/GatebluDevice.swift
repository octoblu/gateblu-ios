//
//  MeshbluExample.swift
//  gateblu
//
//  Created by octoblu on 7/17/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation
import MeshbluKit
import Result
import SwiftyJSON

class GatebluDevice : AnyObject {
  var meshbluHttp: MeshbluHttp!

  init(meshbluConfig: [String: AnyObject]){
    println("GATEBLU DEVICE")
    self.meshbluHttp = MeshbluHttp(meshbluConfig: meshbluConfig)
    let uuid = meshbluConfig["uuid"] as? String
    let token = meshbluConfig["token"] as? String
    if uuid != nil && token != nil {
      self.meshbluHttp.setCredentials(uuid!, token: token!)
    }
  }
  
  init(meshbluHttp: MeshbluHttp) {
    println("GATEBLU DEVICE")
    self.meshbluHttp = meshbluHttp
  }
  
  func getMeshbluClient() -> MeshbluHttp {
    return self.meshbluHttp
  }
  
  func register(onSuccess: (uuid: String, token: String) -> ()) {
    let device = [
      "type": "device:gateblu", // Set your own device type
      "devices": [],
      "online" : "true"
    ]
    
    self.meshbluHttp.register(device) { (result) -> () in
      switch result {
      case let .Failure(error):
        println("Failed to register")
      case let .Success(success):
        let json = success.value
        let uuid = json["uuid"].stringValue
        let token = json["token"].stringValue
        
        self.meshbluHttp.setCredentials(uuid, token: token)
        onSuccess(uuid: uuid, token: token)
      }
    }
  }
  
  func getDevice(handler: (Result<JSON, NSError>) -> ()){
    self.meshbluHttp.whoami() {
      (result) -> () in
      handler(result)
    }
  }
  
  func hasOwner(hasOwner: ()->(), noOwner: () -> ()){
  }
  
  func sendMessage(payload: [String: AnyObject], handler: (Result<JSON, NSError>) -> ()){
    var message : [String: AnyObject] = [
      "devices" : ["*"],
      "payload" : payload,
      "topic" : "some-topic"
    ]
    
    self.meshbluHttp.message(message) {
      (result) -> () in
      handler(result)
    }
  }
  
  func generateToken(uuid: String, onSuccess: (token: String) -> ()){
    self.meshbluHttp.generateToken(uuid) {
      (result) -> () in
      switch result {
      case let .Failure(error):
        println("Failed to generate token")
      case let .Success(success):
        println("Generated token")
        let json = success.value
        let token = json["token"].stringValue
        
        onSuccess(token: token)
      }
    }
  }
 
}
