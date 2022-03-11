//
//  SILRangeTestCharacteristic.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 05.07.2018.
//  Copyright © 2018 SiliconLabs. All rights reserved.
//

import Foundation

enum SILRangeTestServices {
    case deviceInformation
    case rangeTest
}

enum SILDeviceInformationServiceCharacteristics {
    case manufacturerName
    case modelNumber
    case systemId
}

enum SILRangeTestServiceCharacteristics {
    case per
    case ma
    case packetsSent
    case packetsCount
    case packetsReceived
    case packetsRequired
    case channel
    case radioMode
    case frequency
    case phyConfigList
    case phyConfig
    case txPower
    case destinationId
    case sourceId
    case payload
    case maSize
    case log
    case isRunning
}

class SILRangeTestCharacteristic {
    let uuid: CBUUID
    let serviceUuid: CBUUID
    let supportsNotifications: Bool
    
    private(set) var valueData: Data? = nil
    private(set) var minValueData: Data? = nil
    private(set) var maxValueData: Data? = nil
    
    convenience init(_ characteristic: SILDeviceInformationServiceCharacteristics) {
        let characteristicUuid = SILRangeTestCharacteristic.deviceInformationServiceCharacteristics[characteristic]!
        let serviceUuid = SILRangeTestCharacteristic.services[.deviceInformation]!
        let supportsNotifications = SILRangeTestCharacteristic.doesSupportNotifications(characteristic)
        
        self.init(characteristicUuid, serviceUuid, supportsNotifications)
    }
    
    convenience init(_ characteristic: SILRangeTestServiceCharacteristics) {
        let characteristicUuid = SILRangeTestCharacteristic.rangeTestServiceCharacteristics[characteristic]!
        let serviceUuid = SILRangeTestCharacteristic.services[.rangeTest]!
        let supportsNotifications = SILRangeTestCharacteristic.doesSupportNotifications(characteristic)
        
        self.init(characteristicUuid, serviceUuid, supportsNotifications)
    }
    
    private init(_ characteristicUuid: String, _ serviceUuid: String, _ supportsNotifications: Bool) {
        self.uuid = CBUUID(string: characteristicUuid)
        self.serviceUuid = CBUUID(string: serviceUuid)
        self.supportsNotifications = supportsNotifications
    }
    
    func value<T>() -> T? {
        return convert(data: self.valueData)
    }
    
    func value() -> String? {
        return convertToString(data: self.valueData)
    }
    
    func minValue<T>() -> T? {
        return convert(data: self.minValueData)
    }
    
    func minValue() -> String? {
        return convertToString(data: self.minValueData)
    }
    
    func maxValue<T>() -> T? {
        return convert(data: self.maxValueData)
    }
    
    func maxValue() -> String? {
        return convertToString(data: self.maxValueData)
    }
    
    func update(withCharacteristic characteristic: CBCharacteristic) -> Bool {
        if self.valueData == characteristic.value {
            return false
        }
        
        self.valueData = characteristic.value
        return true
    }
    
    func update(withDescriptor descriptor: CBDescriptor) -> Bool {
        guard let descriptorData = descriptor.value as? Data,
            descriptorData.count > 0 && descriptorData.count % 2 == 0 else {
            return false
        }
        
        let dataLength = descriptorData.count
        let newMinValueData = descriptorData.subdata(in: 0..<dataLength/2)
        let newMaxValueData = descriptorData.subdata(in: dataLength/2..<dataLength)
        
        if self.minValueData == newMinValueData && self.maxValueData == newMaxValueData {
            return false
        }
        
        self.minValueData = newMinValueData
        self.maxValueData = newMaxValueData
        
        return true
    }
    
    private func convertToString(data: Data?) -> String? {
        guard let actualData = data else {
            return nil
        }
        
        return String(data: actualData, encoding: .utf8)
    }
    
    private func convert<ValueType>(data: Data?) -> ValueType? {
        return data?.withUnsafeBytes({ (pointer: UnsafePointer<ValueType>) -> ValueType in
            return pointer.pointee
        })
    }
}

//MARK: - Static values
extension SILRangeTestCharacteristic {
    static let services: [SILRangeTestServices: String] = [
        .deviceInformation  : "180A",
        .rangeTest          : SILServiceNumberRangeTest,
        ]
    
    static let deviceInformationServiceCharacteristics: [SILDeviceInformationServiceCharacteristics: String] = [
        .manufacturerName   : "2A29",
        .modelNumber        : "2A24",
        .systemId           : "2A23",
        ]
    
    static let rangeTestServiceCharacteristics: [SILRangeTestServiceCharacteristics: String] = [
        .per                : "d1e93c9c-62e0-4962-9cb3-df86d419b5da",
        .ma                 : "cde92958-3f56-4bc6-9e6b-11b5c551e903",
        .packetsSent        : "eb2438fe-a09e-4015-b511-91f52b581639",
        .packetsCount       : "d6781c5d-9a48-4c97-80b8-f8082030ca5d",
        .packetsReceived    : "6c19509b-f0d1-4f0e-84ce-464dba7c573a",
        .packetsRequired    : "6defa84c-75e1-4b5f-8729-140cdfaee745",
        .channel            : "e8811f97-f736-4e52-a9f8-4b771792c114",
        .radioMode          : "660b91bd-1a4c-428a-9e7e-27ce8a945618",
        .frequency          : "3a5404eb-299b-4a3c-a76c-71bf52af1457",
        .phyConfigList      : "05dca698-76e2-4c30-8e22-2ce22e81b968",
        .phyConfig          : "8a354244-c1ff-4318-8834-0e86efac1067",
        .txPower            : "16be0ebf-5b8d-45d8-8128-d1abb4b71788",
        .destinationId      : "41ded549-4298-4911-8c16-3088a7e41d5f",
        .sourceId           : "9438acdf-42f5-463d-9c73-c5a3427fa731",
        .payload            : "0212cda0-4ae2-471a-9743-a318374f14de",
        .maSize             : "b9c9bc5a-f218-4e44-b632-743880e8c7c1",
        .log                : "d05bd818-6000-489f-8cc0-aa4b93a5edaf",
        .isRunning          : "3d28d0e4-2669-4784-a80a-ed8722a563c6",
        ]
    
    static func doesSupportNotifications(_ characteristic: SILDeviceInformationServiceCharacteristics) -> Bool {
        return false
    }
    
    static func doesSupportNotifications(_ characteristic: SILRangeTestServiceCharacteristics) -> Bool {
        switch characteristic {
        case .txPower,
             .packetsSent,
             .packetsRequired,
             .maSize,
             .channel,
             .phyConfig,
             .destinationId,
             .sourceId,
             .isRunning,
             .payload,
             .log:
            return true
        default:
            return false
        }
    }
    
    func getServiceCharacteristicEnum() -> SILRangeTestServiceCharacteristics? {
        return SILRangeTestCharacteristic.rangeTestServiceCharacteristics.first(where: { $1 == self.uuid.uuidString.lowercased() })?.key
    }
}
