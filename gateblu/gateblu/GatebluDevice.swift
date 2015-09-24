//
//  MeshbluExample.swift
//  gateblu
//
//  Created by octoblu on 7/17/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation
import MeshbluKit
import SwiftyJSON

class GatebluDevice : AnyObject {
  var meshbluHttp: MeshbluHttp!

  init(meshbluConfig: [String: AnyObject]){
    print("GATEBLU DEVICE")
    self.meshbluHttp = MeshbluHttp(meshbluConfig: meshbluConfig)
    let uuid = meshbluConfig["uuid"] as? String
    let token = meshbluConfig["token"] as? String
    if uuid != nil && token != nil {
      self.meshbluHttp.setCredentials(uuid!, token: token!)
    }
  }
  
  init(meshbluHttp: MeshbluHttp) {
    print("GATEBLU DEVICE")
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
      case .Failure(_):
        print("Failed to register")
      case let .Success(json):
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
    let message : [String: AnyObject] = [
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
      case .Failure(_):
        print("Failed to generate token")
      case let .Success(json):
        print("Generated token")
        let json = json
        let token = json["token"].stringValue
        
        onSuccess(token: token)
      }
    }
  }
 
}
