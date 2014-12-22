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
    
    override init() {
        super.init()
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
//            NSLog("Imma gonna \(jsonResult)")
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
                NSLog("Imma scanning for ya: \(self.scanCount)")
                self.scanCount++
                if self.blueToothReady {
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
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "Gateblu"])
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        NSLog("willRestoreState")
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey]
        NSLog("Perifs \(peripherals)")
    }
    
    func discoverDevices(serviceUUIDs: Array<String>) {
        NSLog("discovering devices")
        var uuids = Array<CBUUID>()
        for uuid in serviceUUIDs {
            uuids.append(CBUUID(string: uuid.derosenthal()))
        }
        
        centralManager.scanForPeripheralsWithServices(uuids, options: nil)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        let data:JSON = [
            "type": "connect",
            "peripheralUuid": peripheral.identifier.UUIDString
        ]
        self.websocketServer.pushToAll(data.rawData());
    }
    
    func stopDiscoveringDevices() {
        NSLog("stopping discovery")
        centralManager.stopScan()
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if peripheral.name != nil {
            let identifier = peripheral.identifier.UUIDString
            NSLog("Discovered \(peripheral.name) \(identifier)")
            self.foundPeripherals[identifier] = peripheral
            let onDeviceEmit = {
                (data:NSData!) -> (NSData!) in
                self.websocketServer.pushToAll(data)
                return data
            }
            var deviceService = GatebluDeviceService(identifier: identifier, peripheral: peripheral, centralManager: centralManager, onEmit: onDeviceEmit)
            self.deviceServices[identifier] = deviceService

            
            var services = peripheral.services
            if services == nil {
                services = []
            }
            let data:JSON = [
                "type": "discover",
                "peripheralUuid": identifier,
                "advertisement": [
                    "localName": peripheral.name,
                    "serviceUuids": services
                ]
            ]
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
