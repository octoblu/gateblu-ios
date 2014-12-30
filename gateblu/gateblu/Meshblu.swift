//
//  Meshblu.swift
//  FlowYo
//
//  Created by Peter DeMartini on 11/4/14.
//  Copyright (c) 2014 Octoblu, Inc. All rights reserved.
//

import Foundation

class Meshblu {
  
  let meshbluUrl : String = "https://meshblu.octoblu.com"
  
  var uuid : String? = "uuid"
  var token : String? = "token"
  
  init(uuid: String?, token: String?){
    self.uuid = uuid
    self.token = token
  }

  func goOnline(){
    let parameters = [
      "online" : true
    ]
    self.makeRequest("PUT", path: "/devices/\(self.uuid!)", parameters: parameters, onResponse: { (response: AnyObject?) in
      NSLog("Houston going online")
    })
  }
  
  func goOffline(){
    let parameters = [
      "online" : false,
      "uuid" : self.uuid!,
      "token" : self.token!,
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
  
  func makeRequest(type: String, path : String, parameters : AnyObject, onResponse: (AnyObject?) -> ()){
    let manager :AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
    let url :String = self.meshbluUrl + path
    
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
