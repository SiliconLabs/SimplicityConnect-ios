//
//  SILBluetoothServiceCharacteristicProperties.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 15/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILBluetoothServiceDescriptorProperty: String {
    case Read
    case Write
}

enum SILBluetoothServiceDescriptorPropertyType: String {
    case Mandatory
    case Optional
    case Excluded
}

@objcMembers
class SILBluetoothServiceDescriptorProperties: NSObject {
    
    let propertyMap: [SILBluetoothServiceDescriptorProperty: SILBluetoothServiceDescriptorPropertyType]
    
    lazy var mandatoryProperties: [SILBluetoothServiceDescriptorProperty] = {
        var properties: [SILBluetoothServiceDescriptorProperty] = []
        for propertyPair in propertyMap {
            if propertyPair.value != .Excluded {
                properties.append(propertyPair.key)
            }
        }
        return properties
    }()
    
    init(propertyDict: NSDictionary) {
        var properties: [SILBluetoothServiceDescriptorProperty: SILBluetoothServiceDescriptorPropertyType] = [:]
        for key in propertyDict.allKeys {
            if let keyString = key as? String, let property = SILBluetoothServiceDescriptorProperty(rawValue: keyString) {
                let propertyTypeString = propertyDict[key] as! String
                if let propertyType = SILBluetoothServiceDescriptorPropertyType(rawValue: propertyTypeString) {
                    properties[property] = propertyType
                } else {
                    properties[property] = .Excluded
                }
            }
        }
        self.propertyMap = properties 
    }
}
