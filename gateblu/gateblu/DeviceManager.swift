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

class DeviceManager: NSObject {
  var deviceDiscoverer:DeviceDiscoverer!
  var gatebluWebsocketServer:GatebluWebsocketServer!
  var nobleWebsocketServer:NobleWebsocketServer!
  var deviceBackgroundService:DeviceBackgroundService!
  
  var devices = [Device]()
  var scanningSockets = [PSWebSocket]()
  var serviceMap = [String:[PSWebSocket]]()
  var connectedSockets = [String:PSWebSocket]()
  var deviceManagerView : DeviceManagerView!
  var onDeviceChangeListeners : [() -> ()] = []
  var uuid: String?
  var token: String?
  
  var connecting = false
  
  override init() {
    super.init()
    self.gatebluWebsocketServer = GatebluWebsocketServer(onMessage: self.onGatebluMessage)
    self.nobleWebsocketServer = NobleWebsocketServer(onMessage: self.onNobleMessage)
    self.deviceBackgroundService = DeviceBackgroundService()
    self.deviceDiscoverer = DeviceDiscoverer(onDiscovery: self.onDiscovery, onEmit: self.onEmit)
  }
  
  func start(){
    self.deviceManagerView = DeviceManagerView()
    self.setUuidAndToken()
    self.deviceManagerView.startWebView()
  }
  
  func disconnectAll() {
    deviceDiscoverer.disconnectAll()
  }
  
  func setUuidAndToken() {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    self.uuid = nil // userDefaults.stringForKey("uuid")
    self.token = nil // userDefaults.stringForKey("token")
    
    if uuid == nil || token == nil {
      println("Sorry bro, can't start without a uuid or token")
      self.uuid = "eaed33d7-c723-47dd-9f9a-e70fb45b55d8"
      self.token = "588e19e90143c8ecf990c0c843f3a811a829dea4"
      println("Just kidding, added it for you...")
    }
    NSLog("UUID: \(uuid!) Token: \(token!)")
  }
  
  func onGatebluMessage(webSocket:PSWebSocket, message:String) {
    NSLog("onGatebluMesssage: \(message)")
    let data = message.dataUsingEncoding(NSUTF8StringEncoding)!
    let jsonResult = JSON(data: data)
    let action = jsonResult["action"].stringValue
    let id = jsonResult["id"].stringValue
    
    switch action {
    case "stopDevice":
      println("Stopping Device")
      return;
    case "startDevice":
      println("Starting Device")
      return
    case "removeDevice":
      println("Removing Device")
      return;
    case "addDevice":
      println("Adding Device")
      return;
    default:
      NSLog("I can't even: \(action)")
      return;
    }
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
        let uuidString = uuid.stringValue.derosenthal()
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
        let uuidString = uuid.stringValue.derosenthal()
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
    for device in self.devices {
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
  
  func setOnDevicesChange(onDeviceChange: () -> ()) {
    self.onDeviceChangeListeners.append(onDeviceChange)
  }
  
  func setTheDevices(devices:[Device]){
    self.devices = devices
    for listener in self.onDeviceChangeListeners {
      listener()
    }
  }
  
  func sendDevices(webSocket : PSWebSocket, id : String, devices: Array<JSON>) {
    var tasks : [((Any?, NSError?) -> ()) -> ()] = []
    for device in devices {
      tasks.append(Async.bind { self.deviceExists(device, completionHandler: $0)})
    }
    Async.parallel(tasks) { (results, error) in
      let filteredResults = self.compact(results! as [Any])
      let devices = Device.fromJSONArray(filteredResults)
      self.setTheDevices(devices)
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
