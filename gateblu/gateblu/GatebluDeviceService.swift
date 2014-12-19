//
//  GatebluDeviceService.swift
//  gateblu
//
//  Created by Jade Meskill on 12/19/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import CoreBluetooth

class GatebluDeviceService: NSObject, CBPeripheralDelegate {
    var identifier:String
    var peripheral:CBPeripheral
    var centralManager:CBCentralManager
    var onEmit:(data: NSData!) -> (NSData!)
    
    init(identifier:String, peripheral: CBPeripheral, centralManager: CBCentralManager, onEmit: (data: NSData!) -> (NSData!)) {
        self.identifier = identifier
        self.peripheral = peripheral
        self.centralManager = centralManager
        self.onEmit = onEmit
        super.init()
        self.peripheral.delegate = self
    }
    
    func connect() {
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func emit(data: NSData!){
        
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
        emit(data.rawData())
    }
    
    func updateRssi(identifier: NSString) {
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
        emit(data.rawData())
    }
    
    func peripheral(peripheral:CBPeripheral, didReadRSSI RSSI:NSNumber, error:NSError) {
        let data:JSON = [
            "type": "rssiUpdate",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "rssi" : RSSI
        ]
        println(data)
        emit(data.rawData())
    }
    
    func discoverCharacteristics(identifier: NSString, serviceUuid: NSString, characteristicUuids: Array<String>) {
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
        emit(data.rawData())
    }
    
    
    func write(identifier: NSString, serviceUuid: NSString, characteristicUuid: NSString, data: NSData) {
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
        emit(data.rawData())
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
        emit(data.rawData())
    }
}