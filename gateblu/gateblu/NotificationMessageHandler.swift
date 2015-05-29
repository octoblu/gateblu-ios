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
    let action: String? = message.body
    if action == nil {
      println("No Action for Webkit Debug \(message.body)")
      return
    }
    switch action! {
      case "debug":
        println("DEBUG: \(message.body)")
    }
  }
}