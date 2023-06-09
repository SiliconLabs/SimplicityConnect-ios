//
//  SILESLTag.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

enum SILESLTagSensor: RawRepresentable, Equatable {
    typealias RawValue = String
    
    case batteryState
    case temperature
    case unknown(id: String)
    
    init?(rawValue: String) {
        if rawValue == "0x0054" {
            self = .batteryState
            return
        } else if rawValue == "0x0059" {
            self = .temperature
            return
        } else if rawValue != "0x0000" {
            self = .unknown(id: rawValue)
            return
        }
        
        return nil
    }
    
    var rawValue: String {
        switch self {
        case .batteryState:
            return "0x0054 - Present Input Voltage"
            
        case .temperature:
            return "0x0059 - Present Device Operating Temperature"
            
        case .unknown(id: let id):
            return "\(id) - Unknown sensor"
        }
    }
}

class SILESLTag: SILESLResponseData, Equatable {
    let btAddress: SILBluetoothAddress
    let eslId: SILESLIdAddress
    let maxImageIndex: UInt
    let displaysNumber: UInt
    let sensors: [SILESLTagSensor]
    var ledState: SILESLLedState = .off
    var knownImages: [URL?] = [nil, nil]
    
    init(btAddress: SILBluetoothAddress,
         eslId: SILESLIdAddress,
         maxImageIndex: UInt,
         displaysNumber: UInt,
         sensors: [SILESLTagSensor]) {
        self.btAddress = btAddress
        self.eslId = eslId
        self.maxImageIndex = maxImageIndex
        self.displaysNumber = displaysNumber
        self.sensors = sensors
    }
    
    static func == (lhs: SILESLTag, rhs: SILESLTag) -> Bool {
        return lhs.btAddress == rhs.btAddress
            && lhs.eslId == rhs.eslId
            && lhs.maxImageIndex == rhs.maxImageIndex
            && lhs.displaysNumber == rhs.displaysNumber
            && lhs.sensors == rhs.sensors
            && lhs.ledState == rhs.ledState
            && lhs.knownImages == rhs.knownImages
    }
}

extension Array<SILESLTag>: SILESLResponseData { }

class SILESLTagDecoder {
    func decodeTag(from data: [UInt8]) -> SILESLTag? {
        let btAddressLength = 17
        let dataBeforeBtAddress = 3
        let sensorDataLength = 2
        
        guard data.count >= dataBeforeBtAddress else {
            return nil
        }
        
        let eslAddress = UInt(data[0])
        var maxImageIndex = Int(data[1]) - 1
        if maxImageIndex < 0 {
            maxImageIndex = 0
        }
        let displaysNumber = UInt(data[2])
        
        let valueStartingFromBtAddress = data.dropFirst(dataBeforeBtAddress)
        let btAddressValue = valueStartingFromBtAddress.prefix(btAddressLength)
        
        guard btAddressValue.count == btAddressLength else {
            return nil
        }
        
        var btAddress = String()
        for byte in btAddressValue {
            btAddress.append(String(format: "%c", byte))
        }
        
        var sensors = valueStartingFromBtAddress.dropFirst(btAddressLength)
        
        let numberOfSensors = sensors.count / sensorDataLength
        var iteratorIndex = dataBeforeBtAddress + btAddressLength
        var eslTagSensors = [SILESLTagSensor]()
        for _ in 0..<numberOfSensors {
            let sensorId = getSensorId(firstByte: sensors[iteratorIndex + 1], secondByte: sensors[iteratorIndex])
            if let tagSensor = SILESLTagSensor(rawValue: sensorId) {
                eslTagSensors.append(tagSensor)
            }
            
            iteratorIndex += 2
            sensors = sensors.dropFirst(sensorDataLength)
        }
        
        return SILESLTag(btAddress: SILBluetoothAddress(address: btAddress, addressType: .public),
                         eslId: .unicast(id: eslAddress),
                         maxImageIndex: UInt(maxImageIndex),
                         displaysNumber: displaysNumber,
                         sensors: eslTagSensors)
    }
    
    private func getSensorId(firstByte: UInt8, secondByte: UInt8) -> String {
        return String(format: "0x%02X%02X", firstByte, secondByte)
    }
}
