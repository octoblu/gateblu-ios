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
    var scanning = false
    var websocketServer = GatebluWebsocketServer()
    var deviceServices = Dictionary<String, GatebluDeviceService>()
    
    override init() {
        startUpCentralManager()
        startWebsocketServer()
        super.init()
    }
    
    func startWebsocketServer() {
        let onCompletion = { (error: NSError!) -> Void in
            if ((error?) != nil) {
                println("Starting Websocket Server")
            }
        }
        
        let handleRequest = { (data: NSData!) -> NSData! in
            let jsonResult = JSON(data: data)
            //      println("Imma gonna \(jsonResult)")
            let action = jsonResult["action"].stringValue
            
            switch action {
            case "startScanning":
                if self.blueToothReady && !self.scanning {
                    self.scanning = true
                    var serviceUUIDs = Array<String>()
                    for uuid in jsonResult["serviceUuids"].arrayValue {
                        serviceUUIDs.append(uuid.stringValue)
                    }
                    self.discoverDevices(serviceUUIDs)
                }
                
                return data;
                
            case "stopScanning":
                self.stopDiscoveringDevices()
                let timer = NSTimer(timeInterval: 5000, target: self, selector: Selector("setStopScanning"), userInfo: nil, repeats: false)
                return data
                
            case "connect":
                let deviceService = self.deviceServices[jsonResult["peripheralUuid"].stringValue]!
                deviceService.connect()
                return data
                
            case "discoverServices":
                var services = Array<String>()
                for uuid in jsonResult["uuids"].arrayValue {
                    services.append(self.derosenthal(uuid.stringValue))
                }
                self.discoverServices(jsonResult["peripheralUuid"].stringValue, services: services)
                return data
                
            case "discoverCharacteristics":
                var characteristicUuids = Array<String>()
                for uuid in jsonResult["characteristicUuids"].arrayValue {
                    characteristicUuids.append(self.derosenthal(uuid.stringValue))
                }
                
                self.discoverCharacteristics(jsonResult["peripheralUuid"].stringValue, serviceUuid: self.derosenthal(jsonResult["serviceUuid"].stringValue), characteristicUuids: characteristicUuids)
                return data
                
            case "updateRssi":
                self.updateRssi(jsonResult["peripheralUuid"].stringValue)
                return data
                
            case "write":
                let dataStr = jsonResult["data"].stringValue
                let ddata = dataStr.dataFromHexadecimalString()
                
                self.write(jsonResult["peripheralUuid"].stringValue, serviceUuid: self.derosenthal(jsonResult["serviceUuid"].stringValue), characteristicUuid: self.derosenthal(jsonResult["characteristicUuid"].stringValue), data: ddata!)
                return data
                
            case "notify":
                self.notify(jsonResult["peripheralUuid"].stringValue, serviceUuid: self.derosenthal(jsonResult["serviceUuid"].stringValue), characteristicUuid: self.derosenthal(jsonResult["characteristicUuid"].stringValue), notify: jsonResult["notify"].boolValue)
                return data
                
            default:
                println("I can't even \(action) with \(jsonResult)")
                return data
            }
        }
        
        websocketServer.start(handleRequest, onCompletion)
    }
    
    func derosenthal(uuid: String) -> String {
        let regex = NSRegularExpression(pattern: "(\\w{8})(\\w{4})(\\w{4})(\\w{4})(\\w{12})", options: nil, error: nil)
        var muuid = NSMutableString(string: uuid)
        if countElements(uuid) <= 36 {
            regex?.replaceMatchesInString(muuid, options: nil, range: NSMakeRange(0, countElements(uuid)), withTemplate: "$1-$2-$3-$4-$5")
        }
        return NSString(string: muuid).uppercaseString;
    }
    
    func setStopScanning() {
        self.scanning = false
    }
    
    
    func startUpCentralManager() {
        println("Initializing central manager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func discoverDevices(serviceUUIDs: Array<String>) {
        println("discovering devices")
        var uuids = Array<CBUUID>()
        for uuid in serviceUUIDs {
            uuids.append(CBUUID(string: self.derosenthal(uuid)))
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
        println("stopping discovery")
        centralManager.stopScan()
    }
    
    func discoverServices(identifier: NSString, services: Array<String>) {
        let peripheral:CBPeripheral = self.foundPeripherals[identifier]!
        var cbServices = Array<CBUUID>()
        for service in services {
            cbServices.append(CBUUID(string: service))
        }
        peripheral.discoverServices(cbServices);
    }
    
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if peripheral.name != nil {
            let identifier = peripheral.identifier.UUIDString
            println("Discovered \(peripheral.name) \(identifier)")
            self.foundPeripherals[identifier] = peripheral
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
        println("checking state")
        switch (central.state) {
        case .PoweredOff:
            println("CoreBluetooth BLE hardware is powered off")
            
        case .PoweredOn:
            println("CoreBluetooth BLE hardware is powered on and ready")
            blueToothReady = true;
            
        case .Resetting:
            println("CoreBluetooth BLE hardware is resetting")
            
        case .Unauthorized:
            println("CoreBluetooth BLE state is unauthorized")
            
        case .Unknown:
            println("CoreBluetooth BLE state is unknown");
            
        case .Unsupported:
            println("CoreBluetooth BLE hardware is unsupported on this platform");
            
        }
    }
}
