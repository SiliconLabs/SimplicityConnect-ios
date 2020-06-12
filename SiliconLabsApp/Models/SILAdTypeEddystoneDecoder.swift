//
//  SILAdTypeEddystoneDecoder.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 18/05/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdTypeEddystoneDecoder {
    private let eddystoneData: [UInt8]
    
    private let EddystoneUIDLength = 18
    private let EddystoneURLMinimumLength = 4
    private let EddystoneTLMLength = (encrypted: 18, unencrypted: 14)
    private let EddystoneEIDLength = 10
    
    init(eddystoneData: Data) {
        self.eddystoneData = [UInt8](eddystoneData)
    }
    
    func decode() -> SILAdvertisementDataModel {
        let eddystoneDataString: String
        
        switch self.eddystoneData[0] {
        case 0x00:
            eddystoneDataString = decodeEddystoneUID()
        case 0x10:
            eddystoneDataString = decodeEddystoneURL()
        case 0x20:
            if self.eddystoneData[1] == 0x00 {
                eddystoneDataString = decodeEddystoneUnencryptedTLM()
            } else if self.eddystoneData[1] == 0x01 {
                eddystoneDataString = decodeEddystoneEncryptedTLM()
            } else {
                eddystoneDataString = "PARSING ERROR: Unknown type of Eddystone-TLM"
            }
        case 0x30:
            eddystoneDataString = decodeEddystoneEID()
        default:
            eddystoneDataString = "PARSING ERROR: Unknown type of Eddystone: 0x\(self.eddystoneData[0])"
        }
        
        return SILAdvertisementDataModel(value: eddystoneDataString, type: .eddystoneBeacon)
    }
    
    private func decodeEddystoneUID() -> String {
        var eddystoneUIDString = ""
        
        if eddystoneData.count < EddystoneUIDLength {
            return "PARSING ERROR: Incomplete data for Eddystone-UID"
        }
        
        eddystoneUIDString += "Calibrated Tx Power at 0 meters: "
        eddystoneUIDString += decodeCalibratedTxPowerLevel(self.eddystoneData[1])
        
        eddystoneUIDString += "\nUID Namespace: 0x"
        let namespaceBytes = eddystoneData[2...11]
        eddystoneUIDString += hexEncodedString(data: Array(namespaceBytes))
        
        eddystoneUIDString += "\nUID Instance: 0x"
        let instanceBytes = eddystoneData[12...17]
        eddystoneUIDString += hexEncodedString(data: Array(instanceBytes))
        
        return eddystoneUIDString
    }
    
    private func decodeEddystoneURL() -> String {
        var eddystoneURLString = ""
        
        if eddystoneData.count < EddystoneURLMinimumLength {
            return "PARSING ERROR: Incomplete data for Eddystone-URL"
        }
        
        eddystoneURLString += "Calibrated Tx Power at 0 meters: "
        eddystoneURLString += decodeCalibratedTxPowerLevel(self.eddystoneData[1])

        eddystoneURLString += "\nURL: "
        eddystoneURLString += decodeURLSchemePrefix(self.eddystoneData[2])
        
        for eddystoneByte in eddystoneData[3..<eddystoneData.count] {
            if eddystoneByte <= 0x0D {
                eddystoneURLString += decodeURLSchemeAppendix(eddystoneByte)
            } else {
                eddystoneURLString += String(bytes: [eddystoneByte], encoding: .ascii) ?? ""
            }
        }
        
        return eddystoneURLString
    }
    
    private func decodeEddystoneUnencryptedTLM() -> String {
        var eddystoneUnencryptedTMLString = ""
        
        if eddystoneData.count < EddystoneTLMLength.unencrypted {
            return "PARSING ERROR: Incomplete data for Unencrypted Eddystone-TLM"
        }
        
        eddystoneUnencryptedTMLString += "Version: Unencrypted TLM (0x00)"
        
        eddystoneUnencryptedTMLString += "\nBattery voltage: "
        let batteryVoltage = eddystoneData[2...3]
        eddystoneUnencryptedTMLString += decodeBatteryVoltageValue(Array(batteryVoltage))
        eddystoneUnencryptedTMLString += " V"
        
        eddystoneUnencryptedTMLString += "\nTemperature: "
        let beaconTemperature = eddystoneData[4...5]
        eddystoneUnencryptedTMLString += decodeBeaconTemperatureValue(Array(beaconTemperature))
        eddystoneUnencryptedTMLString += " °C"
        
        eddystoneUnencryptedTMLString += "\nAdvertising PDU Count: "
        let PDUCount = eddystoneData[6...9]
        eddystoneUnencryptedTMLString += decodePDUCountValue(Array(PDUCount))
        
        eddystoneUnencryptedTMLString += "\nUptime: "
        let uptimeData = eddystoneData[10...13]
        let calculatedUpTime = decodeUptime(Array(uptimeData))
        eddystoneUnencryptedTMLString += "\(calculatedUpTime.seconds) seconds (\(calculatedUpTime.days) days)"
        
        return eddystoneUnencryptedTMLString
    }
    
    private func decodeEddystoneEncryptedTLM() -> String {
        var eddystoneEncryptedTMLString = ""
        
        if eddystoneData.count < EddystoneTLMLength.encrypted {
            return "PARSING ERROR: Incomplete data for Encrypted Eddystone-TLM"
        }
    
        eddystoneEncryptedTMLString += "Version: Encrypted TLM (0x01)"
        
        eddystoneEncryptedTMLString += "\nEncrypted TLM Data: 0x"
        let encryptedTMLData = eddystoneData[2...13]
        eddystoneEncryptedTMLString += hexEncodedString(data: Array(encryptedTMLData))
        
        eddystoneEncryptedTMLString += "\nSalt: 0x"
        let saltData = eddystoneData[14...15]
        eddystoneEncryptedTMLString += hexEncodedString(data: Array(saltData))
        
        eddystoneEncryptedTMLString += "\nMessage Integrity Check: 0x"
        let messageIntegrityCheckData = eddystoneData[16...17]
        eddystoneEncryptedTMLString += hexEncodedString(data: Array(messageIntegrityCheckData))
        
        return eddystoneEncryptedTMLString
    }
    
    private func decodeEddystoneEID() -> String {
        var eddystoneEIDString = ""
        
        if eddystoneData.count < EddystoneEIDLength {
            return "PARSING ERROR: Incomplete data for Eddystone-EID"
        }
        
        eddystoneEIDString += "Calibrated Tx Power at 0 meters: "
        eddystoneEIDString += decodeCalibratedTxPowerLevel(self.eddystoneData[1])
        
        eddystoneEIDString += "\nEphemeral Identifier (EID): 0x"
        let ephemeralIDBytes = eddystoneData[2...9]
        eddystoneEIDString += hexEncodedString(data: Array(ephemeralIDBytes))
        
        return eddystoneEIDString
    }
    
    fileprivate func decodeCalibratedTxPowerLevel(_ txPowerLevelByte: UInt8) -> String {
        let DecodingFactorFromU2: UInt8 = 129
        var txPowerLevelString = ""
        var txPowerLevel = txPowerLevelByte
        if txPowerLevel > 20 {
            txPowerLevel = txPowerLevel - DecodingFactorFromU2
            txPowerLevelString += "-"
        }
        txPowerLevelString += String(txPowerLevel)
        txPowerLevelString += " dbm"
        return txPowerLevelString
    }
    
    fileprivate func decodeURLSchemePrefix(_ urlSchemePrefixByte: UInt8) -> String {
        switch urlSchemePrefixByte {
        case 0x00:
            return "http://www."
        case 0x01:
            return "https://www."
        case 0x02:
            return "http://"
        case 0x03:
            return "https://"
        default:
            return ""
        }
    }
    
    fileprivate func decodeURLSchemeAppendix(_ urlSchemeAppendixByte: UInt8) -> String {
        switch urlSchemeAppendixByte {
        case 0x00:
            return ".com/"
        case 0x01:
            return ".org/"
        case 0x02:
            return ".edu/"
        case 0x03:
            return ".net/"
        case 0x04:
            return ".info/"
        case 0x05:
            return ".biz/"
        case 0x06:
            return ".gov/"
        case 0x07:
            return ".com"
        case 0x08:
            return ".org"
        case 0x09:
            return ".edu"
        case 0x0A:
            return ".net"
        case 0x0B:
            return ".info"
        case 0x0C:
            return ".biz"
        case 0x0D:
            return ".gov"
        default:
            return ""
        }
    }
    
    fileprivate func hexEncodedString(data: [UInt8]) -> String {
        let format = "%02hhX"
        return data.map { String(format: format, $0) }.joined()
    }
    
    fileprivate func decodeBatteryVoltageValue(_ batteryVoltage: [UInt8]) -> String {
        let firstByteOfBatteryVoltage = Double(batteryVoltage[0])
        let secondByteOfBatteryVoltage = Double(batteryVoltage[1])
        let batteryVoltage = Double(firstByteOfBatteryVoltage * pow(16, 2) + secondByteOfBatteryVoltage) / pow(10, 3)
        return String(batteryVoltage)
    }
    
    fileprivate func decodeBeaconTemperatureValue(_ beaconTemperature: [UInt8]) -> String {
        let firstByteOfBeaconTemperature = Double(beaconTemperature[0])
        let secondByteOfBeaconTemperature = Double(beaconTemperature[1])
        let fractorialValue = Double(secondByteOfBeaconTemperature * pow(16, -2))
        return String(firstByteOfBeaconTemperature + fractorialValue)
    }
    
    fileprivate func decodePDUCountValue(_ PDUCount: [UInt8]) -> String {
        let firstByteOfPDUCount = Double(PDUCount[0]) * pow(16, 6)
        let secondByteOfPDUCount = Double(PDUCount[1]) * pow(16, 4)
        let thirdByteOfPDUCount = Double(PDUCount[2]) * pow(16, 2)
        let fourthByteOfPDUCount = Double(PDUCount[3])
        let PDUValue = Int(firstByteOfPDUCount + secondByteOfPDUCount + thirdByteOfPDUCount + fourthByteOfPDUCount)
        return String(PDUValue)
    }
    
    fileprivate func decodeUptime(_ uptimeData: [UInt8]) -> (seconds: String, days: String) {
        let firstByteOfUptimeData = Double(uptimeData[0]) * pow(16, 6)
        let secondByteOfUptimeData = Double(uptimeData[1]) * pow(16, 4)
        let thirdByteOfUptimeData = Double(uptimeData[2]) * pow(16, 2)
        let fourthByteOfUptimeData = Double(uptimeData[3])
        let uptimeDataValue = firstByteOfUptimeData + secondByteOfUptimeData + thirdByteOfUptimeData + fourthByteOfUptimeData
        let uptimeDataInSeconds = Int(uptimeDataValue / 10.0)
        let OneDayInSeconds = 60.0 * 60.0 * 24.0
        let uptimeDataInDays = Int(uptimeDataValue * ( 1.0 / (OneDayInSeconds * 10.0)))
        return (String(uptimeDataInSeconds), String(uptimeDataInDays))
    }
}
