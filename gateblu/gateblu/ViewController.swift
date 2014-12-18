//
//  ViewController.swift
//  gateblu
//
//  Created by Koshin on 12/17/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate {
  
  var centralManager:CBCentralManager!
  var blueToothReady = false
  var webViewController:CDVViewController!
  var server = BLWebSocketsServer.sharedInstance()

    override func viewDidLoad() {
        super.viewDidLoad()
        println("Starting Manager")
        startWebsocketServer()
        startUpCentralManager()
        startCordovaView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
  func startWebsocketServer() {
    let onCompletion = { (error: NSError!) -> Void in
      if ((error?) != nil) {
        println("Starting Websocket Server")
      }
    }
    
    let handleRequest = { (data: NSData!) -> NSData! in
      var err: NSError?
      var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as NSDictionary
      let action = jsonResult["action"] as NSString;

    
      switch action {
        case "startScanning":
          if self.blueToothReady {
            self.discoverDevices(jsonResult["serviceUuids"]!)
          }

          return data;
        
        case "stopScanning":
          self.stopDiscoveringDevices()
          return data;
        
        default:
          return data
      }
    }
    
    server.setHandleRequestBlock(handleRequest)
    
    server.startListeningOnPort(0xB1e, withProtocolName: nil, andCompletionBlock: onCompletion)
    
  }

  
  func startUpCentralManager() {
    println("Initializing central manager")
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }
  
  func startCordovaView() {
    println("Initializing cordova")
    webViewController = CDVViewController()
    webViewController.view.frame = CGRectMake(0, 0, 0, 0)
    view.addSubview(webViewController.view)
  }
  
  func discoverDevices(uuids: AnyObject) {
    println("discovering devices")
    centralManager.scanForPeripheralsWithServices(nil, options: nil)
  }
  
  func stopDiscoveringDevices() {
    println("stopping discovery")
//    centralManager.stopScan()
  }
  
  func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
    if peripheral.name != nil {
    let data:JSON = [
      "uuid":peripheral.identifier,
      "type":"discover",
      "localName":peripheral.name
    ]
    self.server.pushToAll(data.rawData());
    }

    println("Discovered \(peripheral.name) \(peripheral.identifier)")
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


