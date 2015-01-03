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


class DeviceViewController: NSObject {
    var device:Device!
    var view:WKWebView!
    var lastAwoke:NSDate = NSDate()
    
    init(_ device: Device) {
        super.init()
        let userContentController = WKUserContentController()
        let handler = NotificationScriptMessageHandler()
        userContentController.addScriptMessageHandler(handler, name: "notification")
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        let rect:CGRect = CGRectMake(0,0,0,0)
        self.view = WKWebView(frame: rect, configuration: configuration)
        self.device = device
        startWebView()
    }
    
    func reload() {
        self.view.loadHTMLString(self.getJavascript(), baseURL: NSURL(string: "http://app.octoblu.com"))
    }
    
    func startWebView() {
        reload()
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let controller = appDelegate.window?.rootViewController as ViewController
        let parentView = controller.view as UIView
        parentView.addSubview(self.view)
    }

    func getJavascript() -> NSString {
        let uuid = device.uuid
        let token = device.token
        let connector = device.connector!
        var htmlString = "<html>" +
            "<head>" +
            "<script>" +
            "console.error = function(error) { window.webkit.messageHandlers.notification.postMessage({body:error}); };" +
            "console.log = console.error;" +
            "</script>" +
            "<script src=\"http://gateblu.s3.amazonaws.com/javascript/" + connector + ".js\"></script>" +
            "</head>" +
            "<body>" +
            "<h1>HELLO!!!!!</h1>"
        htmlString +=
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
        return htmlString
    }
    
    func wakeIfNotRecentlyAwoken() {
        let interval = self.lastAwoke.timeIntervalSinceNow
        if interval < 1 {
            wake()
        }
    }
    
    func wake() {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
            dispatch_async(dispatch_get_main_queue(), {
                self.view.evaluateJavaScript("function(){}()", completionHandler: nil)
            })
        }
        self.lastAwoke = NSDate()
    }
    
}


