//
//  SILAdTypeCBPeripheralDecoder.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 15/05/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdTypeCBPeripheralDecoder : NSObject {
    private let peripheral: SILDiscoveredPeripheral
    
    @objc
    init(peripheral: SILDiscoveredPeripheral) {
        self.peripheral = peripheral
    }
    
    @objc
    func decode() -> [SILAdvertisementDataModel] {
        var advertisementDataModels = [SILAdvertisementDataModel]()
        
        if peripheral.advertisedServiceUUIDs != nil {
            advertisementDataModels += decodeAdvertisedSericeUUIDs()
        }
        
        if peripheral.solicitedServiceUUIDs != nil {
            advertisementDataModels += decodeSolicitedServiceUUIDs()
        }
        
        if peripheral.txPowerLevel != nil {
            if let txPowerLevelModel = SILAdvertisementDataModel(value: decodeTXPowerLevel(), type: .txPowerLevel) {
                advertisementDataModels.append(txPowerLevelModel)
            }
        }
        
        if peripheral.advertisedLocalName != nil {
            if let advertisementLocalNameModel = SILAdvertisementDataModel(value: decodeAdvertisementLocalName(), type: .completeLocalName) {
                advertisementDataModels.append(advertisementLocalNameModel)
            }
        }
        
        if peripheral.manufacturerData != nil {
            if let manufacturerDataModel = SILAdvertisementDataModel(value: decodeManufacturerData(), type: .manufacturerData) {
                advertisementDataModels.append(manufacturerDataModel)
            }
        }
        
        if peripheral.dataServiceData != nil {
            if let dataServiceDataModel = SILAdvertisementDataModel(value: decodeDataServiceData(), type: .dataServiceData) {
                advertisementDataModels.append(dataServiceDataModel)
            }
        }
        
        if peripheral.beacon.type == .altBeacon {
            if let altBeaconDataModel = SILAdvertisementDataModel(value: decodeAltBeaconData(), type: .altBeacon) {
                advertisementDataModels.append(altBeaconDataModel)
            }
        }
        
        if peripheral.beacon.type == .eddystone {
            let eddystoneDecoder = SILAdTypeEddystoneDecoder(eddystoneData: peripheral.beacon.eddystoneData)
            let eddystoneDataModel = eddystoneDecoder.decode()
            advertisementDataModels.append(eddystoneDataModel)
        }
        
        return advertisementDataModels
    }
    
    private func decodeAdvertisedSericeUUIDs() -> [SILAdvertisementDataModel] {
        var advertisedServicesDataModels = [SILAdvertisementDataModel]()
        let splitServicesArray = splitServices(services: peripheral.advertisedServiceUUIDs)
        
        if !splitServicesArray[0].isEmpty {
            if let advertisedServiceUUIDsModel = SILAdvertisementDataModel(value: decodeAdvertisedServiceUUIDs16Bit(services16Bit: splitServicesArray[0]), type: .advertisedServiceUUIDs16Bit) {
                advertisedServicesDataModels.append(advertisedServiceUUIDsModel)
            }
        }
        
        if !splitServicesArray[1].isEmpty {
            if let advertisedServiceUUIDsModel = SILAdvertisementDataModel(value: decodeAdvertisedServiceUUIDs32Bit(services32Bit: splitServicesArray[1]), type: .advertisedServiceUUIDs32Bit) {
                advertisedServicesDataModels.append(advertisedServiceUUIDsModel)
            }
        }
        
        if !splitServicesArray[2].isEmpty {
            if let advertisedServiceUUIDsModel = SILAdvertisementDataModel(value: decodeAdvertisedServiceUUIDs128Bit(services128Bit: splitServicesArray[2]), type: .advertisedServiceUUIDs128Bit) {
                advertisedServicesDataModels.append(advertisedServiceUUIDsModel)
            }
        }
        
        return advertisedServicesDataModels
    }
    
    
    private func decodeAdvertisedServiceUUIDs16Bit(services16Bit: [CBUUID]) -> String {
        var advertisedServices = ""
        var isFirst = true
        for service in services16Bit {
            if isFirst {
                isFirst = false
            } else {
                advertisedServices += "\n"
            }
            
            let bluetoothModel = SILBluetoothModelManager.shared()?.serviceModel(forUUIDString: service.uuidString)
            
            advertisedServices += "0x"
            advertisedServices += service.uuidString
            advertisedServices += " - "
            advertisedServices += bluetoothModel?.name ?? "Unknown Service UUID"
        }
        
        return advertisedServices
    }
    
    private func decodeAdvertisedServiceUUIDs32Bit(services32Bit: [CBUUID]) -> String {
        return decodeServicesUsingHex(services32Bit)
    }
    
    private func decodeAdvertisedServiceUUIDs128Bit(services128Bit: [CBUUID]) -> String {
        return decode128BitServices(services128Bit)
    }
    
    private func decodeSolicitedServiceUUIDs() -> [SILAdvertisementDataModel] {
        var solicitedServiceDataModels = [SILAdvertisementDataModel]()
        let splitServicesArray = splitServices(services: peripheral.solicitedServiceUUIDs)
        
        if !splitServicesArray[0].isEmpty {
            if let solicitedServiceUUIDsModel = SILAdvertisementDataModel(value: decodeSolicitedServiceUUIDs16Bit(services16Bit: splitServicesArray[0]), type: .solicitedServiceUUIDs16Bit) {
                solicitedServiceDataModels.append(solicitedServiceUUIDsModel)
            }
        }
        
        if !splitServicesArray[2].isEmpty {
            if let solicitedServiceUUIDsModel = SILAdvertisementDataModel(value: decodeSolicitedServiceUUIDs128Bit(services128Bit: splitServicesArray[2]), type: .solicitedServiceUUIDs128Bit) {
                solicitedServiceDataModels.append(solicitedServiceUUIDsModel)
            }
        }
        
        return solicitedServiceDataModels
    }
    
    private func decodeSolicitedServiceUUIDs16Bit(services16Bit: [CBUUID]) -> String {
        return decodeServicesUsingHex(services16Bit)
    }
    
    private func decodeSolicitedServiceUUIDs128Bit(services128Bit: [CBUUID]) -> String {
        return decode128BitServices(services128Bit)
    }
    
    private func decodeTXPowerLevel() -> String {
        return self.peripheral.txPowerLevel.stringValue
    }
    
    private func decodeAdvertisementLocalName() -> String {
        return peripheral.advertisedLocalName
    }
    
    private func decodeManufacturerData() -> String {
        var manufacturerDataString = ""
        
        let parsedBytes = hexEncodedString(data: self.peripheral.manufacturerData)
        
        if parsedBytes.count < 4 {
            manufacturerDataString += "PARSING ERROR: "
            manufacturerDataString += parsedBytes
            return manufacturerDataString
        }
        
        let companyCodeIndex = parsedBytes.index(parsedBytes.startIndex, offsetBy: 4)
        let companyCodeBytes = parsedBytes.prefix(upTo: companyCodeIndex)
        let companyCodeSecondByteIndex = companyCodeBytes.index(companyCodeBytes.startIndex, offsetBy: 2)
        let companyCodeSecondByte = companyCodeBytes.prefix(upTo: companyCodeSecondByteIndex)
        let companyCodeFirstByte = companyCodeBytes.suffix(from: companyCodeSecondByteIndex)
        
        manufacturerDataString += "Company Code: 0x"
        manufacturerDataString += companyCodeFirstByte
        manufacturerDataString += companyCodeSecondByte
        
        if parsedBytes.count == 4 {
            return manufacturerDataString
        }
        
        let data = parsedBytes.suffix(from: companyCodeIndex)
        
        manufacturerDataString += "\nData: 0x"
        manufacturerDataString += data
        
        return manufacturerDataString
    }
        
    private func decodeDataServiceData() -> String {
        var dataServiceData = ""
        var isFirst = true
        for (_, data) in self.peripheral.dataServiceData.enumerated() {
            if isFirst {
                isFirst = false
            } else {
                dataServiceData += "\n"
            }
            
            dataServiceData += "UUID: 0x"
            dataServiceData += data.key.uuidString
            
            let parsedBytes = hexEncodedString(data: data.value)
            
            if parsedBytes.count > 0 {
                dataServiceData += " Data: 0x"
                dataServiceData += parsedBytes
            }
        }
        
        return dataServiceData
    }
    
    private func decodeAltBeaconData() -> String {
        var altBeaconData = ""
        let altBeacon = self.peripheral.beacon
        var isFirst = true
        
        if let beaconID = altBeacon?.uuidString {
            altBeaconData += "Beacon ID: "
            altBeaconData += beaconID
            isFirst = false
        }
        
        if let manufacturerID = altBeacon?.manufacturerID {
            if isFirst {
                isFirst = false
            } else {
                altBeaconData += "\n"
            }
            
            altBeaconData += "Manufacturer ID: "
            altBeaconData += manufacturerID
        }
        
        if let referenceRSSI = altBeacon?.refRSSI {
            if isFirst {
                isFirst = false
            } else {
                altBeaconData += "\n"
            }
            
            altBeaconData += "Reference RSSI: "
            altBeaconData += String(Int(truncating: referenceRSSI))
            altBeaconData += " dBm"
        }
        
        return altBeaconData
    }
    
    fileprivate func hexEncodedString(data: Data) -> String {
        let format = "%02hhX"
        return data.map { String(format: format, $0) }.joined()
    }
    
    fileprivate func splitServices(services: [CBUUID]) -> [[CBUUID]] {
        var services16bit = [CBUUID]()
        var services32bit = [CBUUID]()
        var services128bit = [CBUUID]()
        
        for service in services {
            switch service.data.count {
            case 2:
                services16bit.append(service)
            case 4:
                services32bit.append(service)
            case 16:
                services128bit.append(service)
            default:
                break
            }
        }
        
        return [services16bit, services32bit, services128bit]
    }
    
    fileprivate func decodeServicesUsingHex(_ services: [CBUUID]) -> String {
        var servicesWithHexString = ""
        var isFirst = true
        
        for service in services {
            if isFirst {
                isFirst = false
            } else {
                servicesWithHexString += ", "
            }
            
            servicesWithHexString += "0x"
            servicesWithHexString += service.uuidString
        }
        
        return servicesWithHexString
    }
    
    fileprivate func decode128BitServices(_ services: [CBUUID]) -> String {
        var services128BitString = ""
        var isFirst = true
        
        for service in services {
            if isFirst {
                isFirst = false
            } else {
                services128BitString += ", "
            }
                        
            services128BitString += service.uuidString
        }
        
        return services128BitString
    }
}

