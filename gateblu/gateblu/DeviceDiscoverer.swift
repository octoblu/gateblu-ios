//
//  DeviceDiscoverer.swift
//  gateblu
//
//  Created by Jade Meskill on 1/3/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation
import CoreBluetooth
import SwiftyJSON

class DeviceDiscoverer: NSObject, CBCentralManagerDelegate {
    var blueToothReady = false
    var centralManager:CBCentralManager!
    let centralQueue = dispatch_queue_create("com.octoblu.gateblu.main", DISPATCH_QUEUE_SERIAL)
    var onDiscovery:(([String:AnyObject]) -> ())!
    var peripherals = [String:PeripheralService]()
    var emit:((String,String) -> ())!

    init(onDiscovery:([String:AnyObject]) -> (), onEmit:(String,String) -> ()) {
        super.init()
        self.onDiscovery = onDiscovery
        self.emit = onEmit
        self.centralManager = CBCentralManager(delegate: self, queue: self.centralQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: "Gateblu"])
    }
    
    func scanForServices(uuids:[String]) {
        var cbuuids:[CBUUID] = []
        for uuid in uuids {
            cbuuids.append(CBUUID(string: uuid))
        }
        println("Scanning for services, \(uuids)")
        
        self.centralManager.scanForPeripheralsWithServices(cbuuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

    }
    
    func stopScanning() {
        self.centralManager.stopScan()
    }
    
    func connect(uuid:String) {
        let service:PeripheralService? = self.peripherals[uuid]
        if (service == nil) {
            return
        }

        self.centralManager!.connectPeripheral(service!.peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ])
    }
    
    func disconnectAll() {
        var peripherals = self.centralManager.retrieveConnectedPeripheralsWithServices(nil)
        for peripheral in peripherals as! [CBPeripheral] {
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    // Protocol
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        if let peripherals:[CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as! [CBPeripheral]! {
            NSLog("willRestoreState")
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        let data:JSON = [
            "type": "connect",
            "peripheralUuid": peripheral.identifier.UUIDString
        ]
        self.emit(peripheral.identifier.UUIDString, data.rawString()!)
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("Discovered \(peripheral.identifier)")
        var peripheralEmit = {
            (message:String) in
            self.emit(peripheral.identifier.UUIDString, message)
        }
        self.peripherals[peripheral.identifier.UUIDString] = PeripheralService(peripheral: peripheral, onEmit: peripheralEmit)
        
        var uuids = [String]()
        for cbuuid in advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID] {
            uuids.append(cbuuid.UUIDString)
        }
        
        var data = [String:AnyObject]()
        data["identifier"] = peripheral.identifier.UUIDString
        data["name"] = peripheral.name
        data["services"] = uuids
        onDiscovery(data)
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