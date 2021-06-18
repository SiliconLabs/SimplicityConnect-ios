//
//  SILBluetoothServiceDescriptorModel.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 15/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

@objcMembers
class SILBluetoothServiceDescriptorModel: NSObject {
    let name: String
    let type: String
    let properties: SILBluetoothServiceDescriptorProperties
    
    init(name: String, type: String, properties: SILBluetoothServiceDescriptorProperties) {
        self.name = name
        self.type = type
        self.properties = properties
    }
}
