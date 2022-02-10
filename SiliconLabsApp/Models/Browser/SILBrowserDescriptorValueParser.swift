//
//  SILBrowserDescriptorValueParser.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 07/12/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

@objc
@objcMembers
class SILBrowserDescriptorValueParser: NSObject {
    
    let descriptor: CBDescriptor!
    
    init(withDescriptor descriptor: CBDescriptor!) {
        self.descriptor = descriptor
    }
    
    var valueLinesNumber: Int {
        get {
            let uuidType = SILDesciptorTypeUUID(rawValue: descriptor.uuid)
            if uuidType == .reportReference || uuidType == .validRange {
                return 2
            }
            return 1
        }
    }
    
    @objc
    func getFormattedValue() -> String {
        let uuid = descriptor.uuid
        let descriptorBytes = getBytesArray(fromDescriptorValue: descriptor.value)
        if descriptorBytes.count > 0 {
            switch (SILDesciptorTypeUUID(rawValue: uuid)) {
            case .environmentalSensingConfiguration:
                return getEnvironmentalSensingConfiguration(bytes: descriptorBytes)
            case .characteristicExtendedProperties:
                return getCharacteristicExtendedProperties(bytes: descriptorBytes)
            case .characteristicUserDescription:
                return getCharacteristicUserDescription(bytes: descriptorBytes)
            case .clientCharacteristicConfiguration:
                return getClientCharacteristicConfiguration(bytes: descriptorBytes)
            case .serverCharacteristicConfiguration:
                return getServerCharacteristicConfiguration(bytes: descriptorBytes)
            case .numberOfDigitals:
                return getNumberOfDigitals(bytes: descriptorBytes)
            case .reportReference:
                return getReportReference(bytes: descriptorBytes)
            case .validRange:
                return getValidRange(bytes: descriptorBytes)
            default:
                return "0x\(bytesToHexString(descriptorBytes))"
            }
        } else {
            return ""
        }
    }
    
    private func getBytesArray(fromDescriptorValue descriptorValue: Any?) -> [UInt8] {
        if let intValue = descriptorValue as? Int {
            return byteArray(from: intValue)
        } else if let nsNumberValue = descriptorValue as? NSNumber {
            return byteArray(from: nsNumberValue.intValue)
        } else if let dataValue = descriptorValue as? Data {
            return dataValue.bytes
        } else if let stringValue = descriptorValue as? String {
            return stringValue.bytes
        } else {
            return []
        }
    }
    
    func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
    
    private func getEnvironmentalSensingConfiguration(bytes: [UInt8]) -> String {
        let lastByte = uint8ToInt(bytes.last!)

        switch (lastByte) {
        case 0: return "Boolean AND"
        case 1: return "Boolean OR"
        default: return "Unknown value: 0x\(bytesToHexString(bytes))"
        }
    }

    private func getCharacteristicExtendedProperties(bytes: [UInt8]) -> String {
        let lastByte = bytes.last!
        var result = ""

        if lastByte & 0b0000_0001 == 1 {
            result.append("Reliable Write enabled, ")
        } else {
            result.append("Reliable Write disabled, ")
        }

        if lastByte & 0b0000_0010 == 2 {
            result.append("Writable Auxiliaries enabled, ")
        } else {
            result.append("Writable Auxiliaries disabled, ")
        }

        if result.hasSuffix(", ") {
            result.removeLast(2)
        }

        return result
    }

    private func getCharacteristicUserDescription(bytes: [UInt8]) -> String {
        return String(bytes: bytes, encoding: .utf8)!
    }

    private func getClientCharacteristicConfiguration(bytes: [UInt8]) -> String {
        let lastByte = bytes[bytes.count - 1]
        var result = ""

        if lastByte & 0b0000_0001 == 1 {
            result.append("Notifications enabled, ")
        } else {
            result.append("Notifications disabled, ")
        }
        
        if lastByte & 0b0000_0010 == 2 {
            result.append("Indications enabled, ")
        } else {
            result.append("Indications disabled, ")
        }
        
        if result.hasSuffix(", ") {
            result.removeLast(2)
        }

        return result
    }

    private func getServerCharacteristicConfiguration(bytes: [UInt8]) -> String {
        let lastByte = bytes.last!

        return lastByte & 0b0000_0001 == 1 ? "Broadcasts enabled" : "Broadcasts disabled"
    }

    private func getNumberOfDigitals(bytes: [UInt8]) -> String {
        let intValue = uint8ToInt(bytes.last!)
        return String(intValue)
    }

    private func getReportReference(bytes: [UInt8]) -> String {
        if bytes.count != 2 {
            return "Unknown value: 0x\(bytesToHexString(bytes))"
        } else {
            let reportId = bytes[0]
            let reportType = bytes[1]

            var result = ""
            result.append("Report ID: 0x\(byteToHexString(reportId))\n")
            result.append("Report Type: 0x\(byteToHexString(reportType))")

            return result
        }
    }

    private func getValidRange(bytes: [UInt8]) -> String {
        let size = bytes.count

        if size % 2 != 0 {
            return "Unknown value: 0x\(bytesToHexString(bytes))"
        } else {
            var result = ""
            
            result.append("Lower inclusive value: 0x")
            let halfSize = size / 2
            for i in 0..<halfSize{
                result.append(byteToHexString(bytes[i]))
            }

            result.append("\nUpper inclusive value: 0x")
            for i in halfSize..<size {
                result.append(byteToHexString(bytes[i]))
            }

            return result
        }
    }
    
    @objc
    func getDescriptorName() -> String {
        let uuid = descriptor.uuid
        switch (SILDesciptorTypeUUID(rawValue: uuid)) {
        case .environmentalSensingConfiguration: return "Environmental Sensing Configuration"
        case .environmentalSensingMeasurement: return "Environmental Sensing Measurement"
        case .environmentalSensingTriggerSetting: return "Environmental Sensing Trigger Setting"
        case .externalReportReference: return "External Report Reference"
        case .characteristicAggregateFormat: return "Characteristic Aggregate Format"
        case .characteristicExtendedProperties: return "Characteristic Extended Properties"
        case .characteristicPresentationFormat: return "Characteristic Presentation Format"
        case .characteristicUserDescription: return "Characteristic User Description"
        case .clientCharacteristicConfiguration: return "Client Characteristic Configuration"
        case .serverCharacteristicConfiguration: return "Server Characteristic Configuration"
        case .numberOfDigitals: return "Number of Digitals"
        case .reportReference: return "Report Reference"
        case .timeTriggerSetting: return "Time Trigger Setting"
        case .validRange: return "Valid Range"
        case .valueTriggerSetting: return "Value Trigger Setting"
        default: return "\(uuid)"
        }
    }
    
    // MARK: Value parsers
    
    func bytesToHexString(_ bytes: [UInt8], spacing: String = "") -> String {
        var hexString: String = ""
        var count = bytes.count
        for byte in bytes
        {
            hexString.append(byteToHexString(byte))
            count = count - 1
            if count > 0
            {
                hexString.append(spacing)
            }
        }
        return hexString
    }
    
    func byteToHexString(_ byte: UInt8) -> String{
        return String(format: "%02X", byte)
    }
    
    func uint8ToInt(_ source: UInt8) -> Int {
        var bytes = [UInt8](repeating: 0, count: 4)
        bytes[3] = source
        let bigEndianUInt32 = bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
        let value = CFByteOrderGetCurrent() == CFByteOrder(CFByteOrderLittleEndian.rawValue)
            ? UInt32(bigEndian: bigEndianUInt32)
            : bigEndianUInt32
        return Int(value)
    }
}

extension StringProtocol {
    var data: Data { .init(utf8) }
    var bytes: [UInt8] { .init(utf8) }
}

extension Data {
    var bytes: [UInt8] {
            var byteArray = [UInt8](repeating: 0, count: self.count)
            self.copyBytes(to: &byteArray, count: self.count)
            return byteArray
        }
}
