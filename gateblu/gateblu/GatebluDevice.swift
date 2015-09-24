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
import SwiftyUUID


class GatebluDevice : AnyObject {
  var meshbluHttp: MeshbluHttp!
  let GATEBLU_LOGGER_UUID = "4dd6d1a8-0d11-49aa-a9da-d2687e8f9caf"
  var uuid : String? = nil
  var token : String? = nil
  var deploymentUuids : [String: String] = [:]

  init(meshbluConfig: [String: AnyObject]){
    print("initializing device from meshblu config")
    self.meshbluHttp = MeshbluHttp(meshbluConfig: meshbluConfig)
    uuid = meshbluConfig["uuid"] as? String
    token = meshbluConfig["token"] as? String
    if uuid != nil && token != nil {
      self.meshbluHttp.setCredentials(uuid!, token: token!)
    }
  }
  
  init(meshbluHttp: MeshbluHttp) {
    print("initializing device from meshbluHttp")
    self.meshbluHttp = meshbluHttp
  }
  
  func getMeshbluClient() -> MeshbluHttp {
    return self.meshbluHttp
  }
  
  func register(onSuccess: (uuid: String, token: String) -> ()) {
    let device = [
      "type": "device:gateblu", // Set your own device type
      "online" : "true"
    ]
    
    self.meshbluHttp.register(device) { (result) -> () in
      switch result {
      case let .Failure(error):
        print("Failed to register \(error)")
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
  
  func broadcastMessage(payload: [String: AnyObject], handler: (Result<JSON, NSError>) -> ()){
    let message : [String: AnyObject] = [
      "devices" : ["*"],
      "payload" : payload,
      "topic" : "some-topic"
    ]
    
    self.sendMessage(message, handler: handler)
  }
  
  func sendMessage(message: [String: AnyObject], handler: (Result<JSON, NSError>) -> ()){
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
        let token = json["token"].stringValue
        
        onSuccess(token: token)
      }
    }
  }
  
  func sendLogMessage(workflow: String, state: String, device: Device, message: String){
    var deploymentUuid: String = "unknown"
    if deploymentUuids[device.uuid] == nil {
      deploymentUuid = UUID().CanonicalString()
      deploymentUuids[device.uuid] = deploymentUuid
    }else{
      deploymentUuid = deploymentUuids[device.uuid]!
    }
    let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
    let payload : [String: String] = [
      "application": "gateblu-ios",
      "deploymentUuid": deploymentUuid,
      "gatebluUuid": self.uuid!,
      "deviceUuid": device.uuid,
      "connector": device.connector!,
      "state": state,
      "workflow": workflow,
      "message": message,
      "platform": "ios",
      "gatebluVersion": version
    ]
    let message : [String: AnyObject] = [
      "devices" : [GATEBLU_LOGGER_UUID, self.uuid!],
      "topic": "gateblu_log",
      "payload": payload
    ]
    sendMessage(message) {
      (result) in
      switch result {
      case .Failure(_):
        print("Failed to send log message")
      case .Success(_):
        print("Successfully logged message")
      }
    }
  }
 
}