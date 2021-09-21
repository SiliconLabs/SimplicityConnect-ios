//
//  SILServiceMandatoryRequirementsSupplier.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 15/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILServiceMandatoryRequirementsSupplier {
    
    private let bluetoothModelManager = SILBluetoothModelManager.shared()
    
    private let uuidsOfDescriptorsCreatedByCoreBluetooth = ["2900", "2902", "2904"]
    
    func getMandatoryCharacteristics(serviceUuid uuid: String) -> [SILGattConfigurationCharacteristicEntity] {
        let uuid = uuid.hasPrefix("0x") ? String(uuid.dropFirst(2)) : uuid
        var result: [SILGattConfigurationCharacteristicEntity] = []
        if let serviceModel = bluetoothModelManager?.serviceModel(forUUIDString: uuid), let characteristicModels = serviceModel.serviceCharacteristics as? [SILBluetoothServiceCharacteristicModel] {
            
            for characteristicModel in characteristicModels {
                if let characteristicUuid = getCharacteristicUuid(fromType: characteristicModel.type) {
                    let characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.cbuuidString = characteristicUuid
                    characteristic.name = characteristicModel.name
                    characteristic.properties = createProperties(forCharacteristicModel: characteristicModel)
                    createDescriptors(forCharacteristic: characteristic, model: characteristicModel)
                    SILDefaultDescriptorsHelper.addDefaultIosDescriptorsIfNeeded(forCharacteristic: characteristic)
                    result.append(characteristic)
                    debugPrint("added characteristic: ", characteristicModel.type, " uuid: ", characteristicUuid)
                }
                else {
                    print("not found: ", characteristicModel.type)
                }
            }
        }
        return result
    }
    
    private func createDescriptors(forCharacteristic characteristic: SILGattConfigurationCharacteristicEntity, model: SILBluetoothServiceCharacteristicModel) {
        for descriptorModel in model.descriptors ?? [] {
            if let descriptorUuid = getDescriptorUuid(fromType: descriptorModel.type), uuidsOfDescriptorsCreatedByCoreBluetooth.contains(descriptorUuid) {
                let descriptor = SILGattConfigurationDescriptorEntity()
                descriptor.cbuuidString = descriptorUuid
                descriptor.name = descriptorModel.name
                descriptor.properties = createProperties(forDescriptorModel: descriptorModel)
                descriptor.initialValueType = .text
                descriptor.initialValue = "N/A - managed by system"
                descriptor.canBeModified = false
                characteristic.descriptors.append(descriptor)
            }
        }
    }
    
    private func getCharacteristicUuid(fromType type: String) -> String? {
        return bluetoothModelManager?.characteristicModel(forName: type)?.uuidString
    }
    
    private func getDescriptorUuid(fromType type: String) -> String? {
        return bluetoothModelManager?.descriptorModel(forName: type)?.uuidString
    }
    
    private func createProperties(forCharacteristicModel characteristicModel: SILBluetoothServiceCharacteristicModel) -> [SILGattConfigurationProperty] {
        var properties: [SILGattConfigurationProperty] = []
        for property in characteristicModel.properties.mandatoryProperties {
            switch property {
            case .Write, .ReliableWrite, .SignedWrite:
                properties.append(SILGattConfigurationProperty(type: .write, permission: .none))
            case .WriteWithoutResponse:
                properties.append(SILGattConfigurationProperty(type: .writeWithoutResponse, permission: .none))
            case .Read:
                properties.append(SILGattConfigurationProperty(type: .read, permission: .none))
            case .Notify:
                properties.append(SILGattConfigurationProperty(type: .notify, permission: .none))
            case .Indicate:
                properties.append(SILGattConfigurationProperty(type: .indicate, permission: .none))
            default:
                continue
            }
        }
        return properties
    }
    
    private func createProperties(forDescriptorModel descriptorModel: SILBluetoothServiceDescriptorModel) -> [SILGattConfigurationProperty] {
        var properties: [SILGattConfigurationProperty] = []
        for property in descriptorModel.properties.mandatoryProperties {
            switch property {
            case .Read:
                properties.append(SILGattConfigurationProperty(type: .read, permission: .none))
            case .Write:
                properties.append(SILGattConfigurationProperty(type: .write, permission: .none))
            }
        }
        return properties
    }
}
