//
//  DeviceManager.swift
//  gateblu
//
//  Created by Jade Meskill on 12/22/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation
import WebKit
import CoreBluetooth

class MockDeviceManager {
    var gatebluService = GatebluService()
    
    var devices : [Device] = [
        Device(uuid: "920e6261-5f0c-11e4-b71e-c1e4be219849", token: "e2emvhdmsi7ctyb9dzvv7zzmrgnfjemi", name : "Bean 1"),
        Device(uuid: "d58749e0-87d3-11e4-94c5-ab09a6c94ef5", token: "02ui6u933qxquayviks0za2n7acyp66r", name : "Bean 2")
    ]
    
    func start() {
        
    }
}
