//
//  ViewController.swift
//  gateblu
//
//  Created by Koshin on 12/17/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import UIKit
import CoreBluetooth
import WebKit

class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler {
  func userContentController(_userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    println(message.body)
  }
}

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIWebViewDelegate {
  
  var centralManager:CBCentralManager!
  var blueToothReady = false
  var webView:WKWebView!
  var foundPeripherals = Dictionary<String,CBPeripheral>()
  var server = BLWebSocketsServer.sharedInstance()
  @IBOutlet var deviceCollectionView : UICollectionView?
  
  var devices : [Device] = []

  override func viewDidLoad() {
      super.viewDidLoad()
      println("Starting Manager")
      startDeviceCollectionView()
      startWebsocketServer()
      startUpCentralManager()
      startWebView()
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func startDeviceCollectionView(){
    for i in 1...10 {
        devices.append(Device())
    }
    let frame = CGRect(x: 0, y: 60, width: self.view.bounds.width, height: self.view.bounds.height - 60)
    let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    layout.itemSize = CGSize(width: 150, height: 100)
    deviceCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
    deviceCollectionView!.delegate = self
    deviceCollectionView!.dataSource = self
    deviceCollectionView!.backgroundColor = UIColor.whiteColor()
    deviceCollectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    self.view.addSubview(deviceCollectionView!)
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return devices.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = deviceCollectionView!.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
    cell.backgroundColor = UIColor.grayColor()
    return cell
  }
  
  func derosenthal(uuid: String) -> String {
    let regex = NSRegularExpression(pattern: "(\\w{8})(\\w{4})(\\w{4})(\\w{4})(\\w{12})", options: nil, error: nil)
    var muuid = NSMutableString(string: uuid)
    if countElements(uuid) <= 36 {
      regex?.replaceMatchesInString(muuid, options: nil, range: NSMakeRange(0, countElements(uuid)), withTemplate: "$1-$2-$3-$4-$5")
    }
    return NSString(string: muuid).uppercaseString;
  }
  
  func startWebsocketServer() {
    let onCompletion = { (error: NSError!) -> Void in
      if ((error?) != nil) {
        println("Starting Websocket Server")
      }
    }
    
    let handleRequest = { (data: NSData!) -> NSData! in
      let jsonResult = JSON(data: data)
      println("Imma gonna \(jsonResult)")
      let action = jsonResult["action"].stringValue
      
      switch action {
        case "startScanning":
          if self.blueToothReady {
            var serviceUUIDs = Array<String>()
            for uuid in jsonResult["serviceUuids"].arrayValue {
              serviceUUIDs.append(uuid.stringValue)
            }
            self.discoverDevices(serviceUUIDs)
          }

          return data;
        
        case "stopScanning":
          self.stopDiscoveringDevices()
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
          let ddata = NSData(base64EncodedString: jsonResult["data"].stringValue, options: nil)!
          self.write(jsonResult["peripheralUuid"].stringValue, serviceUuid: self.derosenthal(jsonResult["serviceUuid"].stringValue), characteristicUuid: self.derosenthal(jsonResult["characteristicUuid"].stringValue), data: ddata)
          return data
        
        default:
          println("I can't even \(action) with \(jsonResult)")
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
  
  func startWebView() {
    println("Initializing WebView")
    let userContentController = WKUserContentController()
    let handler = NotificationScriptMessageHandler()
    userContentController.addScriptMessageHandler(handler, name: "notification")
    let configuration = WKWebViewConfiguration()
    configuration.userContentController = userContentController
    let rect:CGRect = CGRectMake(0,0,0,0)
    webView = WKWebView(frame: rect, configuration: configuration)
    let htmlString = "<html>" +
    "<head>" +
      "<script src=\"http://gateblu.s3.amazonaws.com/javascript/meshblu-bean.js\"></script>" +
    "</head>" +
    "<body>" +
      "<h1>HELLO!!!!!</h1>" +
      "<script>" +
          "console.error = function(error) { window.webkit.messageHandlers.notification.postMessage({body:error}); };" +
          "console.log = console.error;" +
          "window.connector = new Connector({" +
            "server: \"meshblu.octoblu.com\"," +
            "port: 80," +
            "uuid: \"920e6261-5f0c-11e4-b71e-c1e4be219849\"," +
            "token: \"e2emvhdmsi7ctyb9dzvv7zzmrgnfjemi\"" +
          "});" +
      "</script>" +
    "</body>" +
    "</html>"
    
    webView.loadHTMLString(htmlString, baseURL: NSURL(string: "http://app.octoblu.com"))
    webView.frame = CGRectMake(0, 0, 0, 0)
    view.addSubview(webView)
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
    self.server.pushToAll(data.rawData());
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
    self.server.pushToAll(data.rawData());
  }
  
  func updateRssi(identifier: NSString) {
    let peripheral:CBPeripheral = self.foundPeripherals[identifier]!
    println("Reading RSSI")
    peripheral.readRSSI()
  }
  
  func peripheralDidUpdateRSSI(peripheral: CBPeripheral!, error: NSError!) {
    let data:JSON = [
      "type": "rssiUpdate",
      "peripheralUuid": peripheral.identifier.UUIDString,
      "rssi" : peripheral.RSSI
    ]
    println(data)
    self.server.pushToAll(data.rawData());
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
    self.server.pushToAll(data.rawData());
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
      self.server.pushToAll(data.rawData());
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


