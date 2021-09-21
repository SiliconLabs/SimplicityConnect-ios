//
//  SILGattConfiguratorServiceHelper.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 09/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILGattConfiguratorServiceHelperType : class {
    var configuration: SILGattConfigurationEntity! { get set }
    init(configuration: SILGattConfigurationEntity)
}

class SILGattConfiguratorServiceHelper: SILGattConfiguratorServiceHelperType {
    
    var configuration: SILGattConfigurationEntity!
    var services: [CBMutableService] = []
    var advertisementData: [String: Any] = [:]
    private var characteristicMap: [CBUUID: [CBUUID: CBMutableCharacteristic]] = [:]
    private var repository = SILGattConfigurationRepository.shared
    
    required init(configuration: SILGattConfigurationEntity) {
        self.configuration = SILGattConfigurationEntity(value: configuration)
        createServices()
        createAdvertisementData()
    }
    
    private func createAdvertisementData() {
        var advertisementData: [String: Any] = [:]
        advertisementData[CBAdvertisementDataLocalNameKey] = configuration.name
        var uuids: [CBUUID] = []
        for service in services {
            uuids.append(service.uuid)
        }
        advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids
        self.advertisementData = advertisementData
    }
    
    private func createServices() {
        var services: [CBMutableService] = []
        for service in configuration.services {
            let cbuuid = CBUUID(string: service.cbuuidString)
            let newService = CBMutableService(type: cbuuid, primary: service.isPrimary)
            newService.characteristics = createCharacteristics(from: service)
            debugPrint("created Service: ", newService )
            services.append(newService)
        }
        self.services = services
    }
    
    private func createCharacteristics(from service: SILGattConfigurationServiceEntity) -> [CBMutableCharacteristic] {
        let serviceCbuuid = CBUUID(string: service.cbuuidString)
        self.characteristicMap[serviceCbuuid] = [:]
        var characteristics: [CBMutableCharacteristic] = []
        for characteristic in service.characteristics {
            let characteristicCbuuid = CBUUID(string: characteristic.cbuuidString)
            let result = createPropertiesAndPermissions(from: characteristic.properties)
            let properties = result.0
            let permissions = result.1
            let newCharacteristic = CBMutableCharacteristic(type: characteristicCbuuid, properties: properties, value: nil, permissions: permissions)
            newCharacteristic.descriptors = createDescriptors(fromCharateristic: characteristic)
            characteristics.append(newCharacteristic)
            self.characteristicMap[serviceCbuuid]?[characteristicCbuuid] = newCharacteristic
        }
        return characteristics
    }
    
    private func createPropertiesAndPermissions(from properties: [SILGattConfigurationProperty]) -> (CBCharacteristicProperties, CBAttributePermissions) {
        var _properties: CBCharacteristicProperties = []
        var _permissions: CBAttributePermissions = []
        for property in properties {
            switch property.type {
            case .read:
                _properties.insert(.read)
                if property.permission == .none {
                    _permissions.insert(.readable)
                } else {
                    _permissions.insert(.readEncryptionRequired)
                }
            case .write:
                _properties.insert(.write)
                if property.permission == .none {
                    _permissions.insert(.writeable)
                } else {
                    _permissions.insert(.writeEncryptionRequired)
                }
            case .writeWithoutResponse:
                _properties.insert(.writeWithoutResponse)
                if property.permission == .none {
                    _permissions.insert(.writeable)
                } else {
                    _permissions.insert(.writeEncryptionRequired)
                }
            case .notify:
                if property.permission == .none {
                    _properties.insert(.notify)
                } else {
                    _properties.insert(.notifyEncryptionRequired)
                }
            case .indicate:
                if property.permission == .none {
                    _properties.insert(.indicate)
                } else {
                    _properties.insert(.indicateEncryptionRequired)
                }
            }
        }
        return (_properties, _permissions)
    }
    
    func createDescriptors(fromCharateristic characteristic: SILGattConfigurationCharacteristicEntity) -> [CBMutableDescriptor] {
        var descriptors: [CBMutableDescriptor] = []
        for descriptor in characteristic.descriptors {
            if descriptor.cbuuidString == "2904", descriptor.initialValueType == .hex, let value = descriptor.initialValue {
                let cbuuid = CBUUID(string: descriptor.cbuuidString)
                descriptors.append(CBMutableDescriptor(type: cbuuid, value: Data(hexString: value)))
            } else if descriptor.cbuuidString == "2901", descriptor.initialValueType == .text, let value = descriptor.initialValue {
                let cbuuid = CBUUID(string: descriptor.cbuuidString)
                descriptors.append(CBMutableDescriptor(type: cbuuid, value: value))
            } else if isUUID128Right(uuid: descriptor.cbuuidString) {
                let cbuuid = CBUUID(string: descriptor.cbuuidString)
                switch descriptor.initialValueType {
                case .none:
                    continue
                case .text:
                    descriptors.append(CBMutableDescriptor(type: cbuuid, value: descriptor.initialValue!.data(using: .utf8)))
                case .hex:
                    descriptors.append(CBMutableDescriptor(type: cbuuid, value: Data(hexString: descriptor.initialValue!)))
                }
            }
        }
        return descriptors
    }
    
    private func isUUID128Right(uuid: String) -> Bool {
        let hexRegex = "[0-9a-f]"
        let uuid128Regex = try! NSRegularExpression(pattern: "\(hexRegex){8}-\(hexRegex){4}-\(hexRegex){4}-\(hexRegex){4}-\(hexRegex){12}")
        return checkRegex(regex: uuid128Regex, text: uuid)
    }
    
    private func checkRegex(regex: NSRegularExpression, text: String) -> Bool {
        let lowercaseText = text.lowercased()
        
        let textRange = NSRange(location: 0, length: lowercaseText.utf16.count)
        
        if regex.firstMatch(in: lowercaseText, options: [], range: textRange) != nil {
            return true
        }
        return false
    }
    
    func setCharacteristicValues() {
        for service in configuration.services {
            let serviceCbuuid = CBUUID(string: service.cbuuidString)
            for characteristic in service.characteristics {
                if characteristic.initialValueType == .none {
                    continue
                }
                let characteristicCbuuid = CBUUID(string: characteristic.cbuuidString)
                let mutableCharacteristic = self.characteristicMap[serviceCbuuid]?[characteristicCbuuid]
                setInitialValue(forCharacteristic: mutableCharacteristic, entity: characteristic)
            }
        }
    }
    
    private func setInitialValue(forCharacteristic characteristic: CBMutableCharacteristic?, entity: SILGattConfigurationCharacteristicEntity) {
        let value = entity.initialValue!
        if entity.initialValueType == .hex {
            characteristic?.value = Data(hexString: value)
        } else {
            characteristic?.value = value.data(using: .ascii)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if let characteristic = self.characteristicMap[request.characteristic.service.uuid]?[request.characteristic.uuid], let value = characteristic.value {
            if request.offset > characteristic.value?.count ?? 0 {
                peripheral.respond(to: request, withResult: .invalidOffset)
                return
            }
            let range = Range(NSRange(location: request.offset, length: value.count - request.offset))!
            request.value = value.subdata(in: range)
            peripheral.respond(to: request, withResult: .success)
            print(characteristic.value?.hexString ?? "none")
            return
        }
        peripheral.respond(to: request, withResult: .attributeNotFound)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let characteristic = self.characteristicMap[request.characteristic.service.uuid]?[request.characteristic.uuid] {
                if request.offset > characteristic.value?.count ?? 0  {
                    peripheral.respond(to: request, withResult: .invalidOffset)
                    return
                }
                characteristic.value = request.value
            } else {
                peripheral.respond(to: request, withResult: .attributeNotFound)
                return
            }
        }
        peripheral.respond(to: requests.first!, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        if let characteristic = self.characteristicMap[characteristic.service.uuid]?[characteristic.uuid] {
            if let value = characteristic.value {
                peripheral.updateValue(value, for: characteristic, onSubscribedCentrals: [central])
            }
            print("Subscribed centrals of characteristic after subscription ", characteristic.subscribedCentrals ?? "")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if let characteristic = self.characteristicMap[characteristic.service.uuid]?[characteristic.uuid] {
            print("Subscribed centrals of characteristic after unsubscription ", characteristic.subscribedCentrals ?? "")
        }
    }
    
    func writeToLocalCharacteristic(data: Data, service: CBService, characteristic: CBCharacteristic) {
        if let characteristic = self.characteristicMap[service.uuid]?[characteristic.uuid] {
            characteristic.value = data
            updateInitialValue(data: data, service: service, characteristic: characteristic)
            print("Writing to local characteristic value")
        }
    }
    
    func updateLocalCharacteristicValue(peripheral: CBPeripheralManager?, data: Data, service: CBService, characteristic: CBCharacteristic) {
        if let characteristic = self.characteristicMap[service.uuid]?[characteristic.uuid], let peripheral = peripheral {
            characteristic.value = data
            peripheral.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
            updateInitialValue(data: data, service: service, characteristic: characteristic)
            print("Updating local characteristic value")
        }
    }
    
    private func updateInitialValue(data: Data, service: CBService, characteristic: CBCharacteristic) {
        if let serviceEntity = configuration.services.first(where: { serviceEntity in
            return CBUUID(string: serviceEntity.cbuuidString) == service.uuid
        }) {
            if let characteristicEntity = serviceEntity.characteristics.first(where: { characteristicEntity in
                return CBUUID(string: characteristicEntity.cbuuidString) == characteristic.uuid
            }) {
                let characteristicEntity = SILGattConfigurationCharacteristicEntity(value: characteristicEntity)
                if let dataString = String(data: data, encoding: .utf8) {
                    characteristicEntity.initialValue = dataString
                    characteristicEntity.initialValueType = .text
                } else {
                    characteristicEntity.initialValue = data.hexString
                    characteristicEntity.initialValueType = .hex
                }
                repository.update(characteristic: characteristicEntity)
            }
        }
    }
}

extension Data {
    private static let hexRegex = try! NSRegularExpression(pattern: "^([a-fA-F0-9][a-fA-F0-9])*$", options: [])

    init?(hexString: String) {
        if Data.hexRegex.matches(in: hexString, range: NSMakeRange(0, hexString.count)).isEmpty {
            return nil 
        }

        let chars = Array(hexString)

        let bytes: [UInt8] =
            stride(from: 0, to: chars.count, by: 2)
                .map {UInt8(String([chars[$0], chars[$0+1]]), radix: 16)}
                .compactMap{$0}

        self = Data(bytes)
    }

    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
