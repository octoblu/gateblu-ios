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

extension String {
  
  /// Create NSData from hexadecimal string representation
  ///
  /// This takes a hexadecimal representation and creates a NSData object. Note, if the string has any spaces, those are removed. Also if the string started with a '<' or ended with a '>', those are removed, too. This does no validation of the string to ensure it's a valid hexadecimal string
  ///
  /// The use of `strtoul` inspired by Martin R at http://stackoverflow.com/a/26284562/1271826
  ///
  /// :returns: NSData represented by this hexadecimal string. Returns nil if string contains characters outside the 0-9 and a-f range.
  
  func dataFromHexadecimalString() -> NSData? {
    let trimmedString = self.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> ")).stringByReplacingOccurrencesOfString(" ", withString: "")
    
    // make sure the cleaned up string consists solely of hex digits, and that we have even number of them
    
    var error: NSError?
    let regex = NSRegularExpression(pattern: "^[0-9a-f]*$", options: .CaseInsensitive, error: &error)
    let found = regex?.firstMatchInString(trimmedString, options: nil, range: NSMakeRange(0, countElements(trimmedString)))
    if found == nil || found?.range.location == NSNotFound || countElements(trimmedString) % 2 != 0 {
      return nil
    }
    
    // everything ok, so now let's build NSData
    
    let data = NSMutableData(capacity: countElements(trimmedString) / 2)
    
    for var index = trimmedString.startIndex; index < trimmedString.endIndex; index = index.successor().successor() {
      let byteString = trimmedString.substringWithRange(Range<String.Index>(start: index, end: index.successor().successor()))
      let num = Byte(byteString.withCString { strtoul($0, nil, 16) })
      data?.appendBytes([num] as [Byte], length: 1)
    }
    
    return data
  }
}

extension NSData {
  func hexString() -> NSString {
    var str = NSMutableString()
    let bytes = UnsafeBufferPointer<UInt8>(start: UnsafePointer(self.bytes), count:self.length)
    for byte in bytes {
      str.appendFormat("%02hhx", byte)
    }
    return str
  }
}



class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler {
  func userContentController(_userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    println(message.body)
  }
}

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIWebViewDelegate {
  
  var gatebluService = GatebluService()
  var webView:WKWebView!
  @IBOutlet var deviceCollectionView : UICollectionView?
  
  var devices : [Device] = []

  override func viewDidLoad() {
      super.viewDidLoad()
      println("Starting Manager")
      startDeviceCollectionView()
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
  
}


