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

class NobleManager: NSObject {
  var nobleWebsocketServer:NobleWebsocketServer!
  var deviceDiscoverer:DeviceDiscoverer!
  let controllerManager = ControllerManager()
  
  var scanningSockets = [PSWebSocket]()
  var serviceMap = [String:[PSWebSocket]]()
  var connectedSockets = [String:PSWebSocket]()
  
  override init() {
    super.init()
    self.deviceDiscoverer = DeviceDiscoverer(onDiscovery: self.onDiscovery, onEmit: self.onEmit)
  }
  
  func start(){
    self.nobleWebsocketServer = NobleWebsocketServer(onMessage: self.onNobleMessage, onStart: self.startNoble)
  }
  
  func startNoble(){
  }
  
  func disconnectAll() {
    deviceDiscoverer.disconnectAll()
  }
  
  func getDevices() -> [Device] {
    let deviceManager = controllerManager.getDeviceManager()
    return deviceManager.devices
  }
  
  func onNobleMessage(webSocket:PSWebSocket, message:String) {
    let data = message.dataUsingEncoding(NSUTF8StringEncoding)!
    let jsonResult = JSON(data: data)
    let action = jsonResult["action"].stringValue
    var peripheralUuid:String!
    if (jsonResult["peripheralUuid"] != nil) {
      peripheralUuid = jsonResult["peripheralUuid"].stringValue
    }
    
    var peripheralService:PeripheralService!
    if (peripheralUuid != nil) {
      peripheralService = deviceDiscoverer.peripherals[peripheralUuid]
    }
    switch action {
    case "startScanning":
      if !contains(self.scanningSockets, webSocket) {
        self.scanningSockets.append(webSocket)
      }
      var uuids:[String] = []
      for uuid in jsonResult["serviceUuids"].arrayValue {
        let uuidString = uuid.stringValue.lowercaseString
        uuids.append(uuidString)
        var services:[PSWebSocket]? = self.serviceMap[uuidString]
        if (services == nil) {
          self.serviceMap[uuidString] = [webSocket]
        } else {
          services!.append(webSocket)
        }
      }
      deviceDiscoverer.scanForServices(uuids)
      return
      
    case "stopScanning":
      self.scanningSockets = self.scanningSockets.filter { $0 != webSocket }
      if self.scanningSockets.count == 0 {
        deviceDiscoverer.stopScanning()
      }
      return
      
    case "connect":
      self.connectedSockets[peripheralUuid] = webSocket
      deviceDiscoverer.connect(peripheralUuid)
      return
      
    case "discoverServices":
      var uuids = [String]()
      for uuid in jsonResult["uuids"].arrayValue {
        let uuidString = uuid.stringValue.lowercaseString
        uuids.append(uuidString)
      }
      peripheralService.discoverServices(uuids)
      return
      
    case "discoverCharacteristics":
      var uuids = [String]()
      let serviceUuid = jsonResult["serviceUuid"].stringValue
      for uuid in jsonResult["characteristicUuids"].arrayValue {
        uuids.append(uuid.stringValue)
      }
      peripheralService.discoverCharacteristics(serviceUuid, characteristicUuids: uuids)
      return
      
    case "updateRssi":
      peripheralService.updateRssi()
      return
      
    case "write":
      let serviceUuid = jsonResult["serviceUuid"].stringValue
      let characteristicUuid = jsonResult["characteristicUuid"].stringValue
      
      let dataStr = jsonResult["data"].stringValue
      let ddata = dataStr.dataFromHexadecimalString()
      peripheralService.write(serviceUuid, characteristicUuid: characteristicUuid, data: ddata!)
      return
      
    case "notify":
      let serviceUuid = jsonResult["serviceUuid"].stringValue
      let characteristicUuid = jsonResult["characteristicUuid"].stringValue
      peripheralService.notify(serviceUuid, characteristicUuid: characteristicUuid, notify: jsonResult["notify"].boolValue)
      return
      
    default:
      println("I can't even \(action): \(message)")
    }
  }
  
  func onEmit(peripheralUuid: String, message: String) {
    let webSocket = self.connectedSockets[peripheralUuid]
    if (webSocket != nil) {
      webSocket!.send(message)
    }
    for device in getDevices() {
      device.wakeUp()
    }
  }
  
  func onDiscovery(data: [String:AnyObject]) {
    let message:JSON = [
      "type": "discover",
      "peripheralUuid": data["identifier"]!,
      "advertisement": [
        "localName": data["name"]!,
        "serviceUuids": data["services"]!
      ]
    ]
    println("Discovered: \(message)")
    for uuid in data["services"] as! [String] {
      var services = self.serviceMap[uuid] as [PSWebSocket]?
      if (services != nil) {
        for webSocket in services! {
          if contains(self.scanningSockets, webSocket) {
            webSocket.send(message.rawString())
          }
        }
      }
    }
  }
  
}
