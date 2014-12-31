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
    let peripheralQueue = dispatch_queue_create("com.octoblu.gateblu.peripheral", DISPATCH_QUEUE_SERIAL)
    
    init(identifier:String, peripheral: CBPeripheral, centralManager: CBCentralManager, onEmit: (data: NSData!) -> (NSData!)) {
        self.identifier = identifier
        self.peripheral = peripheral
        self.centralManager = centralManager
        self.onEmit = onEmit
        super.init()
        self.peripheral.delegate = self
    }
    
    func connect() {
        NSLog("Connecting to: \(identifier)")
        centralManager.connectPeripheral(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ])
    }
    
    func emit(data: NSData!){
        onEmit(data: data)
    }
    
    func discoverServices(serviceUuids: Array<String>) {
        var cbServices = Array<CBUUID>()
        for uuid in serviceUuids {
            cbServices.append(CBUUID(string: uuid.derosenthal()))
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
        emit(data.rawData())
    }
    
    func updateRssi() {
        NSLog("Reading RSSI")
        peripheral.readRSSI()
    }
    
    func peripheralDidUpdateRSSI(peripheral: CBPeripheral!, error: NSError!) {
        NSLog("Error: \(error)")
        let data:JSON = [
            "type": "rssiUpdate",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "rssi" : peripheral.RSSI
        ]
        emit(data.rawData())
    }
    
    func peripheral(peripheral:CBPeripheral, didReadRSSI RSSI:NSNumber, error:NSError) {
        let data:JSON = [
            "type": "rssiUpdate",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "rssi" : RSSI
        ]
        emit(data.rawData())
    }
    
    func discoverCharacteristics(serviceUuid: String, characteristicUuids: Array<String>) {
        var foundService:CBService!
        for service in peripheral.services as Array<CBService> {
            if service.UUID.UUIDString == serviceUuid.derosenthal() {
                foundService = service
            }
        }
        
        var cbUuids = Array<CBUUID>()
        for uuid in characteristicUuids {
            cbUuids.append(CBUUID(string: uuid.derosenthal()))
        }
        if foundService != nil {
            peripheral.discoverCharacteristics(cbUuids, forService: foundService)
        }
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
        emit(data.rawData())
    }
    
    
    func write(serviceUuid: String, characteristicUuid: String, data: NSData) {
        var foundService:CBService!
        for service in peripheral.services {
            let s = service as CBService
            if s.UUID.UUIDString == serviceUuid.derosenthal() {
                foundService = s
            }
        }
        
        var foundCharacteristic:CBCharacteristic!
        for characteristic in foundService.characteristics {
            let c = characteristic as CBCharacteristic
            if c.UUID.UUIDString == characteristicUuid.derosenthal() {
                foundCharacteristic = c
            }
        }
        
        peripheral.writeValue(data, forCharacteristic: foundCharacteristic, type: CBCharacteristicWriteType(rawValue: 1)!)
    }
    
    func notify(serviceUuid: String, characteristicUuid: String, notify: Bool) {
        var foundService:CBService!
        for service in peripheral.services {
            let s = service as CBService
            if s.UUID.UUIDString == serviceUuid.derosenthal() {
                foundService = s
            }
        }
        
        var foundCharacteristic:CBCharacteristic!
        for characteristic in foundService.characteristics {
            let c = characteristic as CBCharacteristic
            if c.UUID.UUIDString == characteristicUuid.derosenthal() {
                foundCharacteristic = c
            }
        }
        NSLog("notified \(notify)")
        peripheral.setNotifyValue(notify, forCharacteristic: foundCharacteristic)
        
        var data:JSON = [
            "type": "notify",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "serviceUuid": foundService.UUID.UUIDString,
            "characteristicUuid": foundCharacteristic.UUID.UUIDString,
            "state": notify
        ]
        emit(data.rawData())
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        peripheral.readValueForCharacteristic(characteristic)
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        NSLog("Peripheral UUID \(peripheral.identifier.UUIDString)")
        NSLog("Service UUID: \(characteristic.service.UUID.UUIDString)")
        NSLog("Characteristic UUID: \(characteristic.UUID.UUIDString)")
        NSLog("Charactistic HexString \(characteristic.value.hexString())")
        var data:JSON = [
            "type": "read",
            "peripheralUuid": peripheral.identifier.UUIDString,
            "serviceUuid": characteristic.service.UUID.UUIDString,
            "characteristicUuid": characteristic.UUID.UUIDString,
            "data": characteristic.value.hexString(),
            "isNotification": true
        ]
        emit(data.rawData())
    }
}