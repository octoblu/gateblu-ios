//
//  Meshblu.swift
//  FlowYo
//
//  Created by Peter DeMartini on 11/4/14.
//  Copyright (c) 2014 Octoblu, Inc. All rights reserved.
//

import Foundation

class Meshblu {
  
  let MESHBLU_URL = "https://meshblu.octoblu.com"
  let MESHBLU_PORT = 443
  var socket : SIOSocket!
  var uuid : String? = "uuid"
  var token : String? = "token"
  

  init(uuid: String?, token: String?){
    self.uuid = uuid
    self.token = token
  }
  
  func connect() {
    NSLog("connecting to \(MESHBLU_URL):\(MESHBLU_PORT)")
    SIOSocket.socketWithHost("\(MESHBLU_URL):\(MESHBLU_PORT)") { (socket: SIOSocket!) in
      NSLog("Socket Connected")
      self.socket = socket
      
      var identityMessage = Dictionary<String, AnyObject>()
      identityMessage["uuid"] = self.uuid
      identityMessage["token"] = self.token
//      identityMessage["socketid"] = self.socket.
      socket.emit("identity", args: [identityMessage])
      
      self.socket.on("identify", self.identify);
    }
  }
  
  func identify(message : [AnyObject]!) {
    NSLog("Message \(message)")
  }

  func goOnline(){
    let parameters = [
      "online" : "true",
      "uuid" : self.uuid!,
      "token" : self.token!
    ]
    self.makeRequest("PUT", path: "/devices/\(self.uuid!)", parameters: parameters, onResponse: { (response: AnyObject?) in
      NSLog("Houston going online")
    })
  }
  
  func goOffline(){
    let parameters = [
      "online" : "false",
      "uuid" : self.uuid!,
      "token" : self.token!
    ]
    self.makeRequest("PUT", path: "/devices/\(self.uuid!)", parameters: parameters, onResponse: { (response: AnyObject?) in
      NSLog("Houston going offline")
    })
  }
  
  func register(onSuccess: (uuid: String, token: String) -> ()){
    var parameters = Dictionary<String, AnyObject>()
    parameters["type"] = "device:gateblu:ios"
    parameters["devices"] = []
    parameters["online"] = true
    self.makeRequest("POST", path: "/devices", parameters: parameters, onResponse: { (response : AnyObject?) in
      if response == nil {
        NSLog("Registration response invalid")
        return
      }
      let responseDict = response as Dictionary<String, AnyObject>
      self.uuid = responseDict["uuid"] as String!
      self.token = responseDict["token"] as String!
      onSuccess(uuid: self.uuid!, token: self.token!)
    })
  }

  func whoami(onSuccess : (device: Dictionary<String, AnyObject>) -> ()){
    NSLog("Requesting device object from God")
    self.makeRequest("GET", path: "/devices/\(self.uuid!)", parameters: [], onResponse: { (response : AnyObject?) in
      if response == nil {
        NSLog("WHOAMI? response invalid")
        return
      }
      let responseDict = response as Dictionary<String, AnyObject>
      let deviceArray = responseDict["devices"] as Array<AnyObject>
      onSuccess(device: deviceArray[0] as Dictionary<String, AnyObject>)
      
    })
  }
  
  func getDevice(uuid: String, token: String, onSuccess : (device: Dictionary<String, AnyObject>) -> ()){
    let parameters = ["uuid": uuid, "token": token]
    self.makeRequest("GET", path: "/devices/\(uuid)", parameters: parameters, onResponse: { (response : AnyObject?) in
      if response == nil {
        NSLog("Get Device? response invalid")
        return
      }
      let responseDict = response as Dictionary<String, AnyObject>
      let deviceArray = responseDict["devices"] as Array<AnyObject>
      onSuccess(device: deviceArray[0] as Dictionary<String, AnyObject>)
    })
  }

  
  func makeRequest(type: String, path : String, parameters : AnyObject, onResponse: (AnyObject?) -> ()){
    let manager :AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
    let url :String = self.MESHBLU_URL + path
    
    // Request Success
    let requestSuccess = {
      (operation :AFHTTPRequestOperation!, responseObject :AnyObject!) -> Void in
      onResponse(responseObject);
    }
    
    // Request Failure
    let requestFailure = {
      (operation :AFHTTPRequestOperation!, error :NSError!) -> Void in
      
      onResponse(nil);
      NSLog("requestFailure: \(error)")
    }
    
    // Set Headers
    manager.requestSerializer.setValue(self.uuid, forHTTPHeaderField: "skynet_auth_uuid")
    manager.requestSerializer.setValue(self.token, forHTTPHeaderField: "skynet_auth_token")
    switch type {
    case "GET":
      manager.GET(url, parameters: parameters, success: requestSuccess, failure: requestFailure)
    case "POST":
      manager.POST(url, parameters: parameters, success: requestSuccess, failure: requestFailure)
    case "PUT":
      manager.PUT(url, parameters: parameters, success: requestSuccess, failure: requestFailure)
    default:
      NSLog("No Type Specified")
    }
  }
}
