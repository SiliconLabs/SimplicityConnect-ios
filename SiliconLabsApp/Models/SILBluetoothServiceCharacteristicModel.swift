//
//  SILBluetoothServiceCharacteristicModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 15/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

@objcMembers
class SILBluetoothServiceCharacteristicModel : NSObject {
    let name: String
    let type: String
    let properties: SILBluetoothServiceCharacteristicProperties
    var descriptors: [SILBluetoothServiceDescriptorModel]?
    
    init(name: String, type: String, properties: SILBluetoothServiceCharacteristicProperties) {
        self.name = name
        self.type = type
        self.properties = properties
    }
}
