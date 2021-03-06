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
  var serviceUuids : [CBUUID] = []

  init(onDiscovery:([String:AnyObject]) -> (), onEmit:(String,String) -> ()) {
    super.init()
    self.onDiscovery = onDiscovery
    self.emit = onEmit
    self.centralManager = CBCentralManager(delegate: self, queue: self.centralQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: "Gateblu"])
  }
  
  func scanForServices(uuids:[String]) {
    var cbuuids:[CBUUID] = []
    for uuid in uuids {
      let upperUuid = uuid.uppercaseString
      cbuuids.append(CBUUID(string: upperUuid))
    }
    serviceUuids = cbuuids

    print("Scanning for services, \(uuids)")
    
    self.centralManager.scanForPeripheralsWithServices(serviceUuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
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
    let peripherals = self.centralManager.retrieveConnectedPeripheralsWithServices(serviceUuids)
    for peripheral in peripherals {
      self.centralManager.cancelPeripheralConnection(peripheral)
    }
  }

  // Protocol
  
  func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
    if let _:[CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as! [CBPeripheral]! {
      NSLog("willRestoreState")
    }
  }
  
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    let peripheralUuid = peripheral.identifier.UUIDString.lowercaseString
    let data:JSON = [
      "type": "connect",
      "peripheralUuid": peripheralUuid
    ]
    let dataString = data.rawString()!
    print("Connect Response \(dataString)")
    self.emit(peripheralUuid, dataString)
  }
  
  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
    let peripheralUuid = peripheral.identifier.UUIDString.lowercaseString
    print("Discovered \(peripheralUuid)")
    let peripheralEmit = {
      (message:String) in
      self.emit(peripheralUuid, message)
    }
    self.peripherals[peripheralUuid] = PeripheralService(peripheral: peripheral, onEmit: peripheralEmit)
    
    var uuids = [String]()
    for cbuuid in advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID] {
      uuids.append(cbuuid.UUIDString.lowercaseString)
    }
    
    var data = [String:AnyObject]()
    data["identifier"] = peripheralUuid
    data["name"] = peripheral.name
    data["services"] = uuids
    onDiscovery(data)
  }

  func centralManagerDidUpdateState(central: CBCentralManager) {
    print("checking state")
    switch (central.state) {
    case .PoweredOff:
      print("CoreBluetooth BLE hardware is powered off")
        
    case .PoweredOn:
      print("CoreBluetooth BLE hardware is powered on and ready")
      blueToothReady = true;
        
    case .Resetting:
      print("CoreBluetooth BLE hardware is resetting")
        
    case .Unauthorized:
      print("CoreBluetooth BLE state is unauthorized")
        
    case .Unknown:
      print("CoreBluetooth BLE state is unknown");
        
    case .Unsupported:
      print("CoreBluetooth BLE hardware is unsupported on this platform");
        
    }
  }
}