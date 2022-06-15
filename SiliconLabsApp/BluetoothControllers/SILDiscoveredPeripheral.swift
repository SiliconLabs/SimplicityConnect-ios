//
//  SILDiscoveredPeripheral.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 09/03/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol SILDiscoveredPeripheralDelegate: class {
    func peripheral(_ peripheral: SILDiscoveredPeripheral, didUpdateWithAdvertisementData dictionary: [String: Any]?, andRSSI: NSNumber)
}

@objcMembers
class SILDiscoveredPeripheral: NSObject {
    
    fileprivate let RSSIAppendingString = " RSSI"
    fileprivate let EddystoneService = "FEAA"
    
    var identityKey: String
    var uuid: UUID
    var beacon: SILBeacon!
    var peripheral: CBPeripheral?
    var rssiMeasurementTable = SILRSSIMeasurementTable()
    
    var advertisedLocalName: String?
    var advertisedServiceUUIDs: [CBUUID]?
    var txPowerLevel: NSNumber?
    var manufacturerData: NSData?
    var solicitedServiceUUIDs: [CBUUID]?
    var dataServiceData: [CBUUID : NSData]?
    var advertisingInterval = 0.0
    weak var delegate: SILDiscoveredPeripheralDelegate?
    
    var isFavourite = false
    var isConnectable = false
    
    private var lastTimestamp = 0.0
    private var packetReceivedCount: Int64 = 0
    
    var isDMPConnectedLightConnect: Bool {
        return isContainService(SILServiceNumberConnectedLightingConnect)
    }

    var isDMPConnectedLightProprietary: Bool {
        return isContainService(SILServiceNumberConnectedLightingProprietary)
    }
    
    var isDMPConnectedLightThread: Bool {
        return isContainService(SILServiceNumberConnectedLightingThread)
    }
    
    var isDMPConnectedLightZigbee: Bool {
        return isContainService(SILServiceNumberConnectedLightingZigbee)
    }
    
    var isRangeTest: Bool {
        return isContainService(SILServiceNumberRangeTest)
    }
    
    var hasEddystoneService: Bool {
        return isContainService(EddystoneService)
    }
    
    @objc(initWithPeripheral:advertisementData:RSSI:andDiscoveringTimestamp:)
    init(peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber, andDiscoveringTimestamp timestamp: Double
    ) {
        identityKey = SILDiscoveredPeripheralIdentifierProvider.provideKeyForCBPeripheral(peripheral)
        uuid = peripheral.identifier
        super.init()
        self.peripheral = peripheral
        commonInit(timestamp: timestamp)
        update(withAdvertisementData: advertisementData, rssi: RSSI, andDiscoveringTimestamp: timestamp)
    }
    
    init(iBeacon: CLBeacon, andDiscoveringTimestamp timestamp: Double) {
        identityKey = SILDiscoveredPeripheralIdentifierProvider.provideKeyForCLBeacon(iBeacon)
        if #available(iOS 13.0, *) {
            uuid = iBeacon.uuid
        } else {
            uuid = iBeacon.proximityUUID
        }
        beacon = SILBeacon(iBeacon: iBeacon)
        beacon.name = SILBeaconIBeacon
        super.init()
        peripheral = nil
        commonInit(timestamp: timestamp)
        update(withIBeacon: iBeacon, andDiscoveringTimestamp: timestamp)
    }
    
    private func commonInit(timestamp: Double) {
        rssiMeasurementTable = SILRSSIMeasurementTable()
        advertisingInterval = 0
        packetReceivedCount = 0
        isConnectable = false
        lastTimestamp = timestamp
        advertisedLocalName = DefaultDeviceName
    }
    
    @objc(updateWithAdvertisementData:RSSI:andDiscoveringTimestamp:)
    func update(withAdvertisementData advertisementData: [String : Any],
        rssi RSSI: NSNumber,
        andDiscoveringTimestamp timestamp: Double
    ) {
        advertisedLocalName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral!.name
        advertisedServiceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        txPowerLevel = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
        if !isConnectable, let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber {
            self.isConnectable = isConnectable.boolValue
        }
        manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
        solicitedServiceUUIDs = advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
        dataServiceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: NSData]
        beacon = parseBeaconData(advertisementData)
        if isCorrectAdvertisingPacket(timestamp) {
            packetReceivedCount += 1
            calculateAdvertisingInterval(with: timestamp)
            lastTimestamp = timestamp
        }
        rssiMeasurementTable.addRSSIMeasurement(RSSI)
        delegate?.peripheral(self, didUpdateWithAdvertisementData: advertisementData, andRSSI: RSSI)
    }

    private func isCorrectAdvertisingPacket(_ currentTimestamp: Double) -> Bool {
        let currentInterval = currentTimestamp - lastTimestamp
        return currentInterval >= 0.005
    }
    
    private func calculateAdvertisingInterval(with currentTimestamp: Double) {
        let add3MsToInterval: Double = 0.003
        let multiplierForBegginingCalculating: Double = 0.0007
        let multiplierForAverageInterval: Double = 0.0014
        let reliableForCalculatingPacketAmount: Int64 = 29
        let minimumCount: Int64 = 10

        let currentInterval = currentTimestamp - lastTimestamp
        
        if currentInterval <= 0 {
            return
        }

        if advertisingInterval == 0 {
            advertisingInterval = currentInterval
        } else if (currentInterval < advertisingInterval * multiplierForBegginingCalculating) && packetReceivedCount < minimumCount {
            advertisingInterval = currentInterval
        } else if currentInterval < advertisingInterval + add3MsToInterval {
            let limitedCount = min(packetReceivedCount, minimumCount)
            advertisingInterval = (advertisingInterval * Double(limitedCount - 1) + currentInterval) / Double(limitedCount)
        } else if currentInterval < advertisingInterval * multiplierForAverageInterval {
            advertisingInterval = Double(advertisingInterval * Double(reliableForCalculatingPacketAmount) + currentInterval) / Double(reliableForCalculatingPacketAmount + 1)
        }
    }
    
    private func parseBeaconData(_ advertisement: [String : Any]?) -> SILBeacon {
        if let _ = manufacturerData, let beacon = try? SILBeacon(advertisment: advertisement, name: advertisedLocalName) {
            return beacon
        } else if hasEddystoneService, let dataServiceData = dataServiceData, let data = dataServiceData[CBUUID(string: EddystoneService)] as Data? {
            return SILBeacon(eddystone: data)
        }

        let unknownBeacon = SILBeacon()
        unknownBeacon.name = "Unspecified"
        unknownBeacon.type = .unspecified

        return unknownBeacon
    }
    
    func resetLastTimestampValue() {
        lastTimestamp = 0.0
    }

    func update(withIBeacon iBeacon: CLBeacon, andDiscoveringTimestamp timestamp: Double) {
        advertisedServiceUUIDs = nil
        txPowerLevel = nil
        isConnectable = false
        manufacturerData = nil
        if isCorrectAdvertisingPacket(timestamp) {
            packetReceivedCount += 1
            calculateAdvertisingInterval(with: timestamp)
            lastTimestamp = timestamp
        }
        let rssi = NSNumber(value: iBeacon.rssi)
        rssiMeasurementTable.addRSSIMeasurement(rssi)
        delegate?.peripheral(self, didUpdateWithAdvertisementData: nil, andRSSI: rssi)
    }
        
    private func isContainService(_ serviceUUID: String) -> Bool {
        let service = CBUUID(string: serviceUUID)
        guard let advertisedServiceUUIDs = advertisedServiceUUIDs else {
            return false
        }
        return advertisedServiceUUIDs.contains(service)
    }
    
    func rssiDescription() -> String {
        if let lastMeasurement = rssiMeasurementTable.lastRSSIMeasurement()?.stringValue {
            return lastMeasurement + RSSIAppendingString
        } else {
            return "N/A"
        }
    }

    func rssiValue() -> NSNumber? {
        return rssiMeasurementTable.lastRSSIMeasurement()
    }
}
