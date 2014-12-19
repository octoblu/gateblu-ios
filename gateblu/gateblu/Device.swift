//
//  Device.swift
//  gateblu
//
//  Created by Koshin on 12/18/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation

class Device {
    
    var uuid:String
    var token:String
    
    init(uuid: String, token: String) {
        self.uuid = uuid
        self.token = token
    }
    
}