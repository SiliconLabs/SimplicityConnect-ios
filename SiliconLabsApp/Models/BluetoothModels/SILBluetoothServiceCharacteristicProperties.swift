//
//  SILBluetoothServiceCharacteristicProperties.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 15/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILBluetoothServiceCharacteristicProperty: String {
    case Read
    case Write
    case WriteWithoutResponse
    case SignedWrite
    case ReliableWrite
    case Notify
    case Indicate
    case WritableAuxiliaries
    case Broadcast
}

enum SILBluetoothServiceCharacteristicPropertyType: String {
    case Mandatory
    case Optional
    case Excluded
}

@objcMembers
class SILBluetoothServiceCharacteristicProperties: NSObject {
    
    let propertyMap: [SILBluetoothServiceCharacteristicProperty: SILBluetoothServiceCharacteristicPropertyType]
    
    lazy var mandatoryProperties: [SILBluetoothServiceCharacteristicProperty] = {
        var properties: [SILBluetoothServiceCharacteristicProperty] = []
        for propertyPair in propertyMap {
            if propertyPair.value != .Excluded {
                properties.append(propertyPair.key)
            }
        }
        return properties
    }()
    
    init(propertyDict: NSDictionary) {
        var properties: [SILBluetoothServiceCharacteristicProperty: SILBluetoothServiceCharacteristicPropertyType] = [:]
        for key in propertyDict.allKeys {
            if let keyString = key as? String, let property = SILBluetoothServiceCharacteristicProperty(rawValue: keyString) {
                let propertyTypeString = propertyDict[key] as! String
                if let propertyType = SILBluetoothServiceCharacteristicPropertyType(rawValue: propertyTypeString) {
                    properties[property] = propertyType
                } else if propertyTypeString.uppercased() == "C3" {
                    properties[property] = .Optional
                } else {
                    properties[property] = .Excluded
                }
            }
        }
        self.propertyMap = properties 
    }
}
