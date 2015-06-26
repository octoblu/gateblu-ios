//
//  DevicesWebsocketServer.swift
//  gateblu
//
//  Created by Jade Meskill on 12/19/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import PocketSocket
import SwiftyJSON

class NobleWebsocketServer: NSObject, PSWebSocketServerDelegate {
  var server:PSWebSocketServer!
  var onMessage:((PSWebSocket, String) -> ())!
  var onStart: (() -> ())!

  init(onMessage: (PSWebSocket, String) -> (), onStart: () -> ()) {
    self.onMessage = onMessage
    self.onStart = onStart
    super.init()
    self.server = PSWebSocketServer(host: nil, port: 0xb1e)
    self.server.delegate = self
    self.server.start()
  }
  
  func pushToAll(data:NSData!) {
      
  }
  
  func send(webSocket: PSWebSocket, message:String) {
    webSocket.send(message)
  }
  
  func serverDidStart(server:PSWebSocketServer!) {
    println("NobleWebsocketServer starting")
    onStart()
  }
  
  func serverDidStop(server:PSWebSocketServer!) {
    println("NobleWebsocketServer stopping")
  }
  
  func server(server:PSWebSocketServer!, acceptWebSocketWithRequest request:NSURLRequest) -> (Bool) {
    println("NobleWebsocketServer should accept request: \(request)")
    return true
  }
  
  func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didReceiveMessage message:AnyObject) {
    println("NobleWebsocketServer websocket did receive message: \(message)")
    onMessage(webSocket, "\(message)")
  }
  
  func server(server:PSWebSocketServer!, webSocketDidOpen webSocket:PSWebSocket!) {
    println("NobleWebsocketServer websocket did open \(webSocket)")
    println("SENDING STATE!!!!!!! AHHHH!!!")
    let data:JSON = [
      "type": "stateChange",
      "state": "poweredOn"
    ]
    webSocket.send(data.rawString()!)
  }
  
  func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didCloseWithCode code:NSInteger, reason:String, wasClean:Bool) {
    println("NobleWebsocketServer websocket did close with code: \(code), reason: \(reason), wasClean: \(wasClean)")
  }

  func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didFailWithError error:NSError) {
    println("NobleWebsocketServer websocket did fail with error: \(error)")
  }
}