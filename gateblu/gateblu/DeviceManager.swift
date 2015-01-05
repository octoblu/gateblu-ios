//
//  DeviceManager.swift
//  gateblu
//
//  Created by Jade Meskill on 12/22/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import WebKit


class DeviceManager: NSObject {
    var deviceDiscoverer:DeviceDiscoverer!
    var gatebluWebsocketServer:GatebluWebsocketServer!
    var nobleWebsocketServer:NobleWebsocketServer!
    var deviceBackgroundService:DeviceBackgroundService!
    var meshblu : Meshblu?
    
    var devices = [Device]()
    var scanningSockets = [PSWebSocket]()
    var serviceMap = [String:[PSWebSocket]]()
    var connectedSockets = [String:PSWebSocket]()
    var deviceManagerView : DeviceManagerView!
  
    override init() {
      super.init()
      self.gatebluWebsocketServer = GatebluWebsocketServer(onMessage: self.onGatebluMessage)
      self.nobleWebsocketServer = NobleWebsocketServer(onMessage: self.onNobleMessage)
      self.deviceBackgroundService = DeviceBackgroundService()
      self.deviceDiscoverer = DeviceDiscoverer(onDiscovery: self.onDiscovery, onEmit: self.onEmit)
      let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
      let controller = appDelegate.window?.rootViewController as ViewController
    
      self.deviceManagerView = DeviceManagerView()
//        startMeshblu({ (configuration : Dictionary<String, AnyObject>) in
//            var deviceConfigs : AnyObject? = configuration["devices"]
//            if deviceConfigs == nil {
//              deviceConfigs = []
//            }
//          
//            self.devices = self.parseDevices(deviceConfigs as [AnyObject]);
//            var deviceResponseCount = 0
//            for device in self.devices {
//                self.meshblu!.getDevice(device.uuid, token: device.token, onSuccess: { (response : Dictionary<String, AnyObject>) in
//                    device.update(response)
//                    deviceResponseCount++
//                    if deviceResponseCount == self.devices.count {
//                        controller.deviceCollectionView!.reloadData();
//                    }
//                })
//            }
//        })
    }
  
    func start(){
      self.deviceManagerView.startWebView()
    }
    
    func disconnectAll() {
        deviceDiscoverer.disconnectAll()
    }
  
    func onGatebluMessage(webSocket:PSWebSocket, message:String) {
      NSLog("onGatebluMesssage: \(message)")
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
            if !self.scanningSockets.contains(webSocket) {
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
        let webSocket = self.connectedSockets[peripheralUuid]?
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
        for uuid in data["services"] as [String] {
            var services = self.serviceMap[uuid] as [PSWebSocket]?
            if (services != nil) {
                for webSocket in services! {
                    if self.scanningSockets.contains(webSocket) {
                        webSocket.send(message.rawString())
                    }
                }
            }
        }
    }
  
    func startMeshblu(onConfiguration : (configuration : Dictionary<String, AnyObject>) -> ()){
      let userDefaults = NSUserDefaults.standardUserDefaults()
      let uuid : String? = userDefaults.stringForKey("uuid")
      let token : String? = userDefaults.stringForKey("token")
      
      self.meshblu = Meshblu(uuid: uuid, token: token)
      self.meshblu!.connect()
      if uuid == nil || token == nil {
          self.meshblu!.register({ (uuid: String, token : String) in
              NSLog("Registered uuid: \(uuid), token: \(token)")
              userDefaults.setObject(uuid, forKey: "uuid")
              userDefaults.setObject(token, forKey: "token")
              self.meshblu!.whoami(onConfiguration)
          })
      }else{
          NSLog("Already Registered")
          self.meshblu!.whoami(onConfiguration)
          self.meshblu!.goOnline()
      }
    }
  
    func parseDevices(rawDevices : Array<AnyObject>) -> Array<Device> {
      var devices = [Device]()
  
      for rawDevice in rawDevices {
        devices.append(Device(device: rawDevice as Dictionary<String, AnyObject>))
      }
  
      return devices
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
}
