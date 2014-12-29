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
  
  func register(onSuccess: (uuid: String, token: String) -> ()){
    var parameters = Dictionary<String, String>()
    parameters["type"] = "device:gateblu:ios"
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
  
  func makeRequest(type: String, path : String, parameters : AnyObject, onResponse: (AnyObject?) -> ()){
    let manager :AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
    let url :String = self.meshbluUrl + path
    
    // Request Success
    let requestSuccess = {
      (operation :AFHTTPRequestOperation!, responseObject :AnyObject!) -> Void in
      onResponse(responseObject);
      NSLog("requestSuccess \(responseObject)")
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
    default:
      NSLog("No Type Specified")
    }
  }
}
