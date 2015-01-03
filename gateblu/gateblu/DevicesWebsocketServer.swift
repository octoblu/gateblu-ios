//
//  DevicesWebsocketServer.swift
//  gateblu
//
//  Created by Jade Meskill on 12/19/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation

class DevicesWebsocketServer: NSObject, PSWebSocketServerDelegate {
    var server:PSWebSocketServer!
    var onMessage:((PSWebSocket, String) -> ())!
    
    init(onMessage: (PSWebSocket, String) -> ()) {
        super.init()
        self.onMessage = onMessage
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
        NSLog("Server starting")
    }
    
    func serverDidStop(server:PSWebSocketServer!) {
        NSLog("Server stopping")
    }
    
    func server(server:PSWebSocketServer!, acceptWebSocketWithRequest request:NSURLRequest) -> (Bool) {
        NSLog("Server should accept request: \(request)")
        return true
    }
    
    func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didReceiveMessage message:AnyObject) {
        NSLog("Server websocket did receive message: \(message)")
        onMessage(webSocket, "\(message)")
    }
    
    func server(server:PSWebSocketServer!, webSocketDidOpen webSocket:PSWebSocket!) {
        NSLog("Server websocket did open \(webSocket)")
    }
    
    func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didCloseWithCode code:NSInteger, reason:String, wasClean:Bool) {
        NSLog("Server websocket did close with code: \(code), reason: \(reason), wasClean: \(wasClean)")
    }
    func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didFailWithError error:NSError) {
        NSLog("Server websocket did fail with error: \(error)")
    }

 
}