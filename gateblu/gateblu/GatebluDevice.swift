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
import LNRSimpleNotifications


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
      "platform": "ios",
      "online" : "true"
    ]
    
    self.meshbluHttp.register(device) { (result) -> () in
      switch result {
      case let .Failure(error):
        print("Failed to register \(error)")
        self.startNotification("Unable to Register Gateblu", body: "")
      case let .Success(json):
        let uuid = json["uuid"].stringValue
        let token = json["token"].stringValue
        
        self.meshbluHttp.setCredentials(uuid, token: token)
        onSuccess(uuid: uuid, token: token)
      }
    }
  }
  
  func updateDefaults(onSuccess: () -> ()) {
    let properties = [
      "platform": "ios"
    ]
    
    self.meshbluHttp.update(properties) { (result) -> () in
      onSuccess()
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
        self.startNotification("Unable to Generate Token", body: "")
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
    let meshbluMessage : [String: AnyObject] = [
      "devices" : [GATEBLU_LOGGER_UUID, self.uuid!],
      "topic": "gateblu_log",
      "payload": payload
    ]
    sendMessage(meshbluMessage) {
      (result) in
      switch result {
      case .Failure(_):
        print("Failed to send log message")
      case .Success(_):
        print("Successfully logged message")
      }
    }
    if state == "error" {
      startNotification("\(device.getName()) Error", body: message)
    }
  }
  
  func startNotification(title: String, body: String){
    LNRSimpleNotifications.sharedNotificationManager.showNotification(title, body: body, callback: { () -> Void in
      NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: Selector("endNotification"), userInfo: nil, repeats: false)
    })
  }

  func endNotification(){
    LNRSimpleNotifications.sharedNotificationManager.dismissActiveNotification({ () -> Void in
      print("Notification dismissed")
    })
  }
}
