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


class DeviceView: WKWebView, UIWebViewDelegate {
    var device:Device!
    var lastAwoke:NSDate = NSDate()
    
    func setDevice(device:Device) {
        self.device = device
        startWebView()
    }
    
    func startWebView() {
        let uuid = device.uuid
        let token = device.token
        let connector = device.connector!
        println("Initializing WebView for connector \(connector)")
        let htmlString = "<html>" +
            "<head>" +
            "<script>" +
            "console.error = function(error) { window.webkit.messageHandlers.notification.postMessage({body:error}); };" +
            "console.log = console.error;" +
            "</script>" +
            "<script src=\"http://gateblu.s3.amazonaws.com/javascript/" + connector + ".js\"></script>" +
            "</head>" +
            "<body>" +
            "<h1>HELLO!!!!!</h1>" +
            "<script>" +
            "window.connector = new Connector({" +
            "server: \"meshblu.octoblu.com\"," +
            "port: 80," +
            "uuid: \"" + uuid + "\"," +
            "token: \"" + token + "\"" +
            "});" +
            "</script>" +
            "</body>" +
        "</html>"
        
        self.loadHTMLString(htmlString, baseURL: NSURL(string: "http://app.octoblu.com"))
    }
    
    func wakeIfNotRecentlyAwoken() {
        let interval = self.lastAwoke.timeIntervalSinceNow
        if interval < 1 {
            wake()
        }
    }
    
    func wake() {
        self.evaluateJavaScript("function(){}()", completionHandler: nil)
        self.lastAwoke = NSDate()
    }
    
}


