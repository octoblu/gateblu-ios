//
//  GatebluService.swift
//  gateblu
//
//  Created by Jade Meskill on 12/19/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import CoreBluetooth

class GatebluService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var blueToothReady = false
    var centralManager:CBCentralManager!
    var foundPeripherals = Dictionary<String,CBPeripheral>()
    var scanning = false
    var websocketServer = GatebluWebsocketServer()
    
    override init() {
        super.init()
        startUpCentralManager()
        startWebsocketServer()
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
                self.connectToDevice(jsonResult["peripheralUuid"].stringValue)
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
    
    func connectToDevice(identifier: NSString) {
        println("connecting to device")
        centralManager.connectPeripheral(self.foundPeripherals[identifier], options: nil)
    }
    
    func discoverServices(identifier: NSString, services: Array<String>) {
        let peripheral:CBPeripheral = self.foundPeripherals[identifier]!
        var cbServices = Array<CBUUID>()
        for service in services {
            cbServices.append(CBUUID(string: service))
        }
        peripheral.discoverServices(cbServices);
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        var services = Array<String>()
        for service in peripheral.services {
            let s = service as CBService
            services.append(s.UUID.UUIDString)
        }
        let data:JSON = [
            "type": "servicesDiscover",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "serviceUuids" : services
        ]
        println(data)
        self.websocketServer.pushToAll(data.rawData());
    }
    
    func updateRssi(identifier: NSString) {
        let peripheral:CBPeripheral = self.foundPeripherals[identifier]!
        println("Reading RSSI")
        peripheral.readRSSI()
    }
    
    func peripheralDidUpdateRSSI(peripheral: CBPeripheral!, error: NSError!) {
        println("Error: \(error)")
        let data:JSON = [
            "type": "rssiUpdate",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "rssi" : peripheral.RSSI
        ]
        println(data)
        self.websocketServer.pushToAll(data.rawData());
    }
    
    func peripheral(peripheral:CBPeripheral, didReadRSSI RSSI:NSNumber, error:NSError) {
        let data:JSON = [
            "type": "rssiUpdate",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "rssi" : RSSI
        ]
        println(data)
        self.websocketServer.pushToAll(data.rawData());
    }
    
    func discoverCharacteristics(identifier: NSString, serviceUuid: NSString, characteristicUuids: Array<String>) {
        let peripheral:CBPeripheral = self.foundPeripherals[identifier]!
        var foundService:CBService!
        for service in peripheral.services {
            let s = service as CBService
            if s.UUID.UUIDString == serviceUuid {
                foundService = s
            }
        }
        
        var cbUuids = Array<CBUUID>()
        for uuid in characteristicUuids {
            cbUuids.append(CBUUID(string: uuid))
        }
        peripheral.discoverCharacteristics(cbUuids, forService: foundService)
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        
        var characteristics = Array<AnyObject>()
        
        for characteristic in service.characteristics {
            let c = characteristic as CBCharacteristic
            var properties = Array<String>()
            
            var descriptors = c.descriptors
            if c.descriptors == nil {
                descriptors = Array<CBDescriptor>()
            }
            
            for descriptor in descriptors {
                let d = descriptor as CBDescriptor
                properties.append(d.description)
            }
            
            let ddata = [
                "uuid":c.UUID.UUIDString,
                "properties": properties
            ]
            characteristics.append(ddata);
        }
        
        var data:JSON = [
            "type": "characteristicsDiscover",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "serviceUuid" : service.UUID.UUIDString,
            "characteristics": characteristics
        ]
        
        
        println(data)
        self.websocketServer.pushToAll(data.rawData());
    }
    
    
    func write(identifier: NSString, serviceUuid: NSString, characteristicUuid: NSString, data: NSData) {
        let peripheral:CBPeripheral = self.foundPeripherals[identifier]!
        
        var foundService:CBService!
        for service in peripheral.services {
            let s = service as CBService
            if s.UUID.UUIDString == serviceUuid {
                foundService = s
            }
        }
        
        var foundCharacteristic:CBCharacteristic!
        for characteristic in foundService.characteristics {
            let c = characteristic as CBCharacteristic
            if c.UUID.UUIDString == characteristicUuid {
                foundCharacteristic = c
            }
        }
        
        peripheral.writeValue(data, forCharacteristic: foundCharacteristic, type: CBCharacteristicWriteType(rawValue: 1)!)
    }
    
    func notify(identifier: NSString, serviceUuid: NSString, characteristicUuid: NSString, notify: Bool) {
        let peripheral:CBPeripheral = self.foundPeripherals[identifier]!
        
        var foundService:CBService!
        for service in peripheral.services {
            let s = service as CBService
            if s.UUID.UUIDString == serviceUuid {
                foundService = s
            }
        }
        
        var foundCharacteristic:CBCharacteristic!
        for characteristic in foundService.characteristics {
            let c = characteristic as CBCharacteristic
            if c.UUID.UUIDString == characteristicUuid {
                foundCharacteristic = c
            }
        }
        println("notified \(notify)")
        peripheral.setNotifyValue(notify, forCharacteristic: foundCharacteristic)
        
        var data:JSON = [
            "type": "notify",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "serviceUuid": foundService.UUID.UUIDString,
            "characteristicUuid": foundCharacteristic.UUID.UUIDString,
            "state": notify
        ]
        println(data)
        self.websocketServer.pushToAll(data.rawData());
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        peripheral.delegate = self
        if peripheral.name != nil {
            let identifier = peripheral.identifier.UUIDString
            println("Discovered \(peripheral.name) \(identifier)")
            self.foundPeripherals[identifier] = peripheral
            
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
    
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        peripheral.readValueForCharacteristic(characteristic)
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        var data:JSON = [
            "type": "read",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "serviceUuid": characteristic.service.UUID.UUIDString,
            "characteristicUuid": characteristic.UUID.UUIDString,
            "data": characteristic.value.hexString(),
            "isNotification": true
        ]
        println(data)
        self.websocketServer.pushToAll(data.rawData());
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
