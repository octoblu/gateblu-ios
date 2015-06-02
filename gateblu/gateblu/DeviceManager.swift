//
//  DeviceManager.swift
//  gateblu
//
//  Created by Jade Meskill on 12/22/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import WebKit
import PocketSocket
import SwiftyJSON
import SVProgressHUD

class DeviceManager: NSObject {
  var gatebluWebsocketServer:GatebluWebsocketServer!
  var nobleManager:NobleManager!
  var deviceBackgroundService:DeviceBackgroundService!
  var deviceChange: (() -> ())?
  
  var devices = [Device]()
  var deviceManagerView : DeviceManagerView!
  
  var connecting = false
  
  override init() {
    super.init()
    self.deviceBackgroundService = DeviceBackgroundService()
    self.nobleManager = NobleManager()
  }
  
  func start(){
    self.gatebluWebsocketServer = GatebluWebsocketServer(onMessage: self.onGatebluMessage, onStart: self.startGateblu)
    self.nobleManager.start()
  }
  
  func startGateblu(){
    let authController = ControllerManager().getAuthController()
    if !authController.isAuthenticated() {
      authController.register(startDeviceManagerView)
      return
    }
    authController.setFromDefaults()
    startDeviceManagerView()
  }
  
  func startDeviceManagerView(){
    println("Starting Device Manager View")
    self.deviceManagerView = DeviceManagerView()
    self.deviceManagerView.startWebView()
  }
  
  func disconnectAll() {
    nobleManager.disconnectAll()
  }
  
  func setOnDevicesChange(deviceChange: () -> ()) {
    self.deviceChange = deviceChange
  }
  
  func onGatebluMessage(webSocket:PSWebSocket, message:String) {
    println("onGatebluMesssage: \(message)")
    let data = message.dataUsingEncoding(NSUTF8StringEncoding)!
    let jsonResult = JSON(data: data)
    let action = jsonResult["action"].stringValue
    let id = jsonResult["id"].stringValue
    let dataResult = jsonResult["data"]
    var responseMessage = ["id": id]
    
    switch action {
    case "stopDevice":
      println("[Stopping Device]")
      self.findAndStopDevice(dataResult)
    case "startDevice":
      println("[Starting Device]")
      self.findAndStartDevice(dataResult)
    case "removeDevice":
      println("[Removing Device]")
      self.removeDevice(dataResult)
    case "addDevice":
      println("[Adding Device]")
      let device = Device(json: dataResult)
      self.addDevice(device)
    case "ready":
      println("[Gateblu Ready]")
      updateDevices()
    default:
      println("I can't even: \(action)")
    }
    let jsonResponse = JSON(responseMessage)
    gatebluWebsocketServer.send(webSocket, message: jsonResponse.rawString())
  }
  
  func addDevice(device: Device){
    self.devices.append(device)
    updateDevices()
  }
  
  func findAndStartDevice(json: JSON){
    let uuidToStart = json["uuid"].stringValue
    var found = false
    for device in devices {
      if device.uuid == uuidToStart  {
        found = true
        startDevice(device)
      }
    }
    if found == false {
      let device = Device(json: json)
      addDevice(device)
    }
    updateDevices()
  }
  
  func findAndStopDevice(json: JSON) {
    let uuidToStop = json["uuid"].stringValue
    for device in devices {
      if device.uuid == uuidToStop {
        stopDevice(device)
      }
    }
    updateDevices()
  }
  
  func startDevice(device: Device){
    if let name = device.name {
      println("Starting Device \(name)...")
    }
    device.wakeUp()
  }
  
  func removeDevice(json:JSON) {
    let uuidToRempve = json["uuid"].stringValue
    for var index = 0; index < devices.count; ++index {
      let device = devices[index]
      if device.uuid == uuidToRempve  {
        self.devices.removeAtIndex(index)
      }
    }
    updateDevices()
  }
  
  func stopDevice(device: Device){
    device.stop()
    updateDevices()
  }
  
  func updateDevices(){
    if self.deviceChange != nil {
      self.deviceChange!()
      return
    }
  }
  
  func deviceExists(device : JSON, completionHandler: (JSON?, NSError?) -> ()){
    let uuid = device["uuid"].stringValue
    let token = device["token"].stringValue
    let meshblu = Meshblu(uuid: uuid, token: token)
    meshblu.whoami({ (device: Dictionary<String, AnyObject>?) in
      let deviceJSON = (device == nil) ? nil : JSON(device!)
      completionHandler(deviceJSON, nil)
    })
  }
  
  func backgroundDevices() {
    deviceBackgroundService.doUpdate({
      self.wakeDevices()
    })
  }
  
  func stopBackgroundDevices() {
    deviceBackgroundService.clearTimeout()
  }
  
  func wakeDevices() {
    for device in self.devices {
      device.wakeUp()
    }
  }
  
  func compact(collection: [Any]) -> [JSON] {
    var filteredArray : [JSON] = []
    for item in collection {
      let itemJSON = item as! JSON
      if let i = (itemJSON)["uuid"].string {
        filteredArray.append(itemJSON)
      }
    }
    return filteredArray
  }
}
