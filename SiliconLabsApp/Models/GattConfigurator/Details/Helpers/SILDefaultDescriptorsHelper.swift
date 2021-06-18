//
//  SILDefaultDescriptorsHelper.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 06/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILDefaultDescriptorsHelper {
    
    class func addDefaultIosDescriptorsIfNeeded(forCharacteristic characteristic: SILGattConfigurationCharacteristicEntity) {
        for property in characteristic.properties {
            switch property.type {
            case .write, .writeWithoutResponse:
                if !characteristic.descriptors.contains(where: { descriptor in
                    descriptor.cbuuidString == "2900"
                }) {
                    let descriptor = createDefaultDescriptor(withUuid: "2900", name: "Characteristic Extended Properties", propertyTypes: [.read, .write])
                    characteristic.descriptors.append(descriptor)
                }
            case .indicate, .notify:
                if !characteristic.descriptors.contains(where: { descriptor in
                    descriptor.cbuuidString == "2902"
                }) {
                    let descriptor = createDefaultDescriptor(withUuid: "2902", name: "Characteristic Characteristic Configuration", propertyTypes: [.read, .write])
                    characteristic.descriptors.append(descriptor)
                }
            default:
                break
            }
        }
    }
    
    private class func createDefaultDescriptor(withUuid cbuuidString: String, name: String, propertyTypes: [SILGattConfigurationPropertyType]) -> SILGattConfigurationDescriptorEntity {
        let descriptor = SILGattConfigurationDescriptorEntity()
        descriptor.cbuuidString = cbuuidString
        descriptor.name = name
        var properties: [SILGattConfigurationProperty] = []
        for propertyType in propertyTypes {
            properties.append(SILGattConfigurationProperty(type: propertyType, permission: .none))
        }
        descriptor.properties = properties
        descriptor.initialValueType = .text
        descriptor.initialValue = "N/A - managed by system"
        descriptor.canBeModified = false
        return descriptor
    }
}
