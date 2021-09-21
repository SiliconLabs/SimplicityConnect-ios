//
//  SILDefaultDescriptorsHelper.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 06/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILDefaultDescriptorsHelper {
    
    private static let characteristicExtendedPropertiesCbuuid = "2900"
    private static let clientCharacteristicConfigurationCbuuid = "2902"
    
    private class func removeDefaultDescriptors(forCharacteristic characteristic: SILGattConfigurationCharacteristicEntity) {
        [characteristicExtendedPropertiesCbuuid, clientCharacteristicConfigurationCbuuid]
            .forEach { cbuuidString in
                if let index = characteristic.descriptors.firstIndex(where: { $0.cbuuidString == cbuuidString }) {
                    characteristic.descriptors.remove(at: index)
                }
            }
    }
    
    class func addDefaultIosDescriptorsIfNeeded(forCharacteristic characteristic: SILGattConfigurationCharacteristicEntity, isImportActive: Bool = false) {
        if !isImportActive {
            removeDefaultDescriptors(forCharacteristic: characteristic)
        }
        for property in characteristic.properties {
            switch property.type {
            case .write, .writeWithoutResponse:
                if !characteristic.descriptors.contains(where: { descriptor in
                    descriptor.cbuuidString == characteristicExtendedPropertiesCbuuid
                }) {
                    let descriptor = createDefaultDescriptor(withUuid: characteristicExtendedPropertiesCbuuid, name: "Characteristic Extended Properties", propertyTypes: [.read, .write])
                    characteristic.descriptors.append(descriptor)
                }
            case .indicate, .notify:
                if !characteristic.descriptors.contains(where: { descriptor in
                    descriptor.cbuuidString == clientCharacteristicConfigurationCbuuid
                }) {
                    let descriptor = createDefaultDescriptor(withUuid: clientCharacteristicConfigurationCbuuid, name: "Client Characteristic Configuration", propertyTypes: [.read, .write])
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
