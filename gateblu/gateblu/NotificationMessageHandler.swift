//
//  NotificationMessageHandler.swift
//  gateblu
//
//  Created by Jade Meskill on 1/7/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation
import WebKit

class NotificationScriptMessageHandler: NSObject, WKScriptMessageHandler {

  func userContentController(_userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    let name = message.name
    switch name {
      case "deviceConfig":
        println("ONCONFIG: \(message.body)")
      case "managerConfig":
        println("MANAGER_DEBUG: \(message.body)")
      case "connectorNotification":
        println("CONNECTOR_DEBUG: \(message.body)")
      default:
        println("SOME_DEBUG: \(message.body)")
    }
  }
}