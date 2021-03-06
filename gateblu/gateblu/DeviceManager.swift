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
  var stopped = false
  var connecting = false
  
  override init() {
    super.init()
    self.deviceBackgroundService = DeviceBackgroundService()
    self.gatebluWebsocketServer = GatebluWebsocketServer(onMessage: self.onGatebluMessage, onStart: self.startGateblu)
    self.nobleManager = NobleManager()
  }
  
  func start(){
    self.nobleManager.start()
  }
  
  func startGateblu(){
    self.stopped = false;
    let authController = ControllerManager().getAuthController()
    if !authController.isAuthenticated() {
      authController.register(startDeviceManagerView)
      return
    }
    authController.setFromDefaults()
    startDeviceManagerView()
  }
  
  func stopGateblu(){
    self.stopped = true
    self.murder()
    self.deviceManagerView.stopWebView()
    if self.deviceChange != nil {
      self.deviceChange!()
    }
  }
  
  func startDeviceManagerView(){
    print("Starting Device Manager View")
    self.deviceManagerView = DeviceManagerView()
    self.deviceManagerView.startWebView()
  }
  
  func disconnectAll() {
    nobleManager.disconnectAll()
  }
  
  func setOnDevicesChange(deviceChange: () -> ()) {
    self.deviceChange = deviceChange
  }
  
  func getGatebluDevice() -> GatebluDevice {
    let auth = ControllerManager().getAuthController()
    return auth.getGatebluDevice()
  }
  
  func onGatebluMessage(webSocket:PSWebSocket, message:String) {
    print("onGatebluMesssage: \(message)")
    let data = message.dataUsingEncoding(NSUTF8StringEncoding)!
    let jsonResult = JSON(data: data)
    let action = jsonResult["action"].stringValue
    let id = jsonResult["id"].stringValue
    let dataResult = jsonResult["data"]
    let responseMessage = ["id": id]

    
    switch action {
    case "stopDevice":
      print("[Stopping Device]")
      self.findAndStopDevice(dataResult)
    case "startDevice":
      print("[Starting Device]")
      self.findAndStartDevice(dataResult)
    case "removeDevice":
      print("[Removing Device]")
      self.removeDevice(dataResult)
    case "addDevice":
      print("[Adding Device]")
      let device = Device(json: dataResult)
      self.addDevice(device)
    case "ready":
      print("[Gateblu Ready]")
      updateDevices()
    default:
      print("I can't even: \(action)")
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
    if let device = findDevice(uuidToStart) {
      startDevice(device)
    }else{
      let device = Device(json: json)
      addDevice(device)
    }
    updateDevices()
  }
  
  func findDevice(uuid: String) -> Device? {
    for device in devices {
      if device.uuid == uuid {
        return device
      }
    }
    return nil
  }
  
  func findAndStopDevice(json: JSON) {
    let uuidToStop = json["uuid"].stringValue
    if let device = findDevice(uuidToStop) {
      stopDevice(device)
    }
    updateDevices()
  }
  
  func startDevice(device: Device){
    self.getGatebluDevice().sendLogMessage("start-device", state: "begin", device: device, message: "")
    if let name = device.name {
      print("Starting Device \(name)...")
    }
    device.wakeUp()
  }
  
  func removeDevice(json:JSON) {
    let uuidToRemove = json["uuid"].stringValue
    for var index = 0; index < devices.count; ++index {
      let device = devices[index]
      if device.uuid == uuidToRemove  {
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
  
  func updateDeviceByUuid(uuid: String, name: String?, logo: String?, type: String?, initializing: Bool, online: Bool){
    for device in self.devices {
      if device.uuid == uuid {
        device.setName(name)
        device.logo = logo
        device.online = online
        device.initializing = initializing
        device.type = type
      }
    }
    self.updateDevices()
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
  
  func murder(){
    for device in devices {
      device.stop()
    }
    self.devices = []
  }
  
  func compact(collection: [Any]) -> [JSON] {
    var filteredArray : [JSON] = []
    for item in collection {
      let itemJSON = item as! JSON
      if let _ = (itemJSON)["uuid"].string {
        filteredArray.append(itemJSON)
      }
    }
    return filteredArray
  }
}
