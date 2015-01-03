//
//  GatebluService.swift
//  gateblu
//
//  Created by Jade Meskill on 12/19/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import CoreBluetooth

class GatebluService: NSObject, CBCentralManagerDelegate {
    var blueToothReady = false
    var centralManager:CBCentralManager!
    var foundPeripherals = Dictionary<String,CBPeripheral>()
    var scanCount = 0
    var websocketServer = GatebluWebsocketServer()
    var deviceServices = Dictionary<String, GatebluDeviceService>()
    let centralQueue = dispatch_queue_create("com.octoblu.gateblu.main", DISPATCH_QUEUE_SERIAL)
    let DEVICES_STORAGE_IDENTIFIER = "GATEBLU_CONNECTED_DEVICES"
    var onWake: ((Void) -> (Void))?
    
    init(onWake: (Void) -> (Void)) {
        super.init()
        self.onWake = onWake
        startUpCentralManager()
        startWebsocketServer()
    }
  
    func startWebsocketServer() {
        let onCompletion = { (error: NSError!) -> Void in
            if ((error?) != nil) {
                NSLog("Starting Websocket Server")
            }
        }
        
        let handleRequest = { (data: NSData!) -> NSData! in
            let jsonResult = JSON(data: data)
            let action = jsonResult["action"].stringValue
            let identifier:String = jsonResult["peripheralUuid"].stringValue
            
            var deviceService:GatebluDeviceService!
            
            if identifier != "" {
                deviceService = self.deviceServices[identifier]
                if deviceService == nil {
                    return data
                }
            }
            
            switch action {
            case "startScanning":
                self.scanCount++
                if self.blueToothReady {
                    NSLog("Imma scanning for ya: \(self.scanCount)")
                    var serviceUUIDs = Array<String>()
                    for uuid in jsonResult["serviceUuids"].arrayValue {
                        serviceUUIDs.append(uuid.stringValue)
                    }
                    self.discoverDevices(serviceUUIDs)
                }
                
                return data;
                
            case "stopScanning":
                self.scanCount--
                if self.scanCount < 0 {
                    self.scanCount = 0
                }
                if self.scanCount == 0 {
                    NSLog("Stop Scanning")
                    self.stopDiscoveringDevices()
                }
                return data
                
            case "connect":
                NSLog("I wanna hook up witchu: \(identifier)")
                deviceService.connect()
                return data
                
            case "discoverServices":
                var services = Array<String>()
                for uuid in jsonResult["uuids"].arrayValue {
                    services.append(uuid.stringValue)
                }
                deviceService.discoverServices(services)
                return data
                
            case "discoverCharacteristics":
                var characteristicUuids = Array<String>()
                for uuid in jsonResult["characteristicUuids"].arrayValue {
                    characteristicUuids.append(uuid.stringValue)
                }
                
                deviceService.discoverCharacteristics(jsonResult["serviceUuid"].stringValue, characteristicUuids: characteristicUuids)
                return data
                
            case "updateRssi":
                deviceService.updateRssi()
                return data
                
            case "write":
                let dataStr = jsonResult["data"].stringValue
                let ddata = dataStr.dataFromHexadecimalString()
                
                deviceService.write(jsonResult["serviceUuid"].stringValue, characteristicUuid: jsonResult["characteristicUuid"].stringValue, data: ddata!)
                return data
                
            case "notify":
                deviceService.notify(jsonResult["serviceUuid"].stringValue, characteristicUuid: jsonResult["characteristicUuid"].stringValue, notify: jsonResult["notify"].boolValue)
                return data
                
            default:
                NSLog("I can't even \(action) with \(jsonResult)")
                return data
            }
        }
        
        websocketServer.start(handleRequest, onCompletion)
    }
    
    func startUpCentralManager() {
        NSLog("Initializing central manager")
        centralManager = CBCentralManager(delegate: self, queue: self.centralQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: "Gateblu"])
    }
  
    func getConnectedDevices() -> Array<String>? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let peripheralUUIDs : AnyObject? = userDefaults.objectForKey(DEVICES_STORAGE_IDENTIFIER)
        if peripheralUUIDs == nil {
          return Array<String>()
        }
        return peripheralUUIDs as? Array<String>
    }
  
    func storeConnectedDevice(deviceUuid: String){
        var devicesUuids = getConnectedDevices()
        var userDefaults = NSUserDefaults.standardUserDefaults()
        if !contains(devicesUuids!, deviceUuid) {
          devicesUuids!.append(deviceUuid)
          userDefaults.setObject(devicesUuids!, forKey: DEVICES_STORAGE_IDENTIFIER)
          userDefaults.synchronize()
        }
    }

    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        if let peripherals:[CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as [CBPeripheral]! {
          NSLog("willRestoreState")
            for peripheral in peripherals {
                let identifier = peripheral.identifier.UUIDString

                self.foundPeripherals[identifier] = peripheral
            }
        }
    }
    
    func disconnectAll() {
        for (identifier,peripheral) in self.foundPeripherals {
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.foundPeripherals[identifier] = nil
        }
    }
    
    func discoverDevices(serviceUUIDs: Array<String>) {
        var uuids = Array<CBUUID>()
        for uuid in serviceUUIDs {
            uuids.append(CBUUID(string: uuid.derosenthal()))
        }
        NSLog("discovering devices, \(uuids)")
        
        centralManager.scanForPeripheralsWithServices(uuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
  
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        storeConnectedDevice(peripheral.identifier.UUIDString)
        
        let data:JSON = [
            "type": "connect",
            "peripheralUuid": peripheral.identifier.UUIDString
        ]
        NSLog("Connected \(data)")
        self.websocketServer.pushToAll(data.rawData());
    }
    
    func stopDiscoveringDevices() {
        NSLog("stopping discovery")
        centralManager.stopScan()
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if peripheral.name != nil {
            let identifier = peripheral.identifier.UUIDString
            NSLog("Discovered \(peripheral.name) \(identifier) \(advertisementData)")
            self.foundPeripherals[identifier] = peripheral
            let onDeviceEmit = {
                (data:NSData!) -> (NSData!) in
                self.websocketServer.pushToAll(data)
                self.onWake!()
                return data
            }
            var deviceService = GatebluDeviceService(identifier: identifier, peripheral: peripheral, centralManager: centralManager, onEmit: onDeviceEmit)
            self.deviceServices[identifier] = deviceService

            var services = Array<String>()
            for s in advertisementData["kCBAdvDataServiceUUIDs"]  as Array<CBUUID> {
                services.append(s.UUIDString)
            }
            let data:JSON = [
                "type": "discover",
                "peripheralUuid": identifier,
                "advertisement": [
                    "localName": peripheral.name,
                    "serviceUuids": services
                ]
            ]
            NSLog("data: \(data)")
            self.websocketServer.pushToAll(data.rawData());
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        NSLog("checking state")
        switch (central.state) {
        case .PoweredOff:
            NSLog("CoreBluetooth BLE hardware is powered off")
            
        case .PoweredOn:
            NSLog("CoreBluetooth BLE hardware is powered on and ready")
            blueToothReady = true;
            self.disconnectAll()
            let peripheralUuids : Array<String>? = getConnectedDevices()
            if peripheralUuids == nil {
              return
            }
            for peripheralUuid in peripheralUuids! {
              NSLog("CentralManager#retrievePeripheralsWithIdentifiers \(peripheralUuid)")
              let retrievedPeripherals = centralManager.retrievePeripheralsWithIdentifiers([CBUUID(string: peripheralUuid)])
              for peripheral in retrievedPeripherals as Array<CBPeripheral> {
                let identifier = peripheral.identifier.UUIDString
                NSLog("Recovered \(peripheral.name) \(identifier)")
                self.foundPeripherals[identifier] = peripheral
                return
              }
              NSLog("CentralManager#retrieveConnectedPeripheralsWithServices")
              let services = self.foundPeripherals[peripheralUuid]!.services as Array<String>
              var servicesCBUuids = Array<CBUUID>()
              for service in services {
                servicesCBUuids.append(CBUUID(string: service))
              }
              for p:AnyObject in centralManager.retrieveConnectedPeripheralsWithServices(servicesCBUuids) {
                if p is CBPeripheral {
                  NSLog("Peripheral Found with Services")
                  return
                }
              }
            }
          
        case .Resetting:
            NSLog("CoreBluetooth BLE hardware is resetting")
            
        case .Unauthorized:
            NSLog("CoreBluetooth BLE state is unauthorized")
            
        case .Unknown:
            NSLog("CoreBluetooth BLE state is unknown");
            
        case .Unsupported:
            NSLog("CoreBluetooth BLE hardware is unsupported on this platform");
            
        }
    }
}
