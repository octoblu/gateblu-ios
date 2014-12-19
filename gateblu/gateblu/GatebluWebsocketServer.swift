//
//  GatebluWebsocketServer.swift
//  gateblu
//
//  Created by Jade Meskill on 12/19/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation

class GatebluWebsocketServer {
    var server = BLWebSocketsServer.sharedInstance()

    func start(handleRequest: (data:NSData!) -> (NSData!), onCompletion: (error: NSError!)->()) {
        server.setHandleRequestBlock(handleRequest)
        server.startListeningOnPort(0xB1e, withProtocolName: nil, andCompletionBlock: onCompletion)
    }
    
    func pushToAll(data:NSData!){
//        println(NSString(data: data, encoding: NSUTF8StringEncoding))
        server.pushToAll(data)
    }
}