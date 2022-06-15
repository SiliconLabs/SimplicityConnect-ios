//
//  SILDiscoveredPeripheralIdentifierProvider.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21/04/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc
class SILDiscoveredPeripheralIdentifierProvider : NSObject {
    @objc(provideKeyForCBPeripheral:)
    static func provideKeyForCBPeripheral(_ peripheral: CBPeripheral) -> String {
        return peripheral.identifier.uuidString
    }
    
    @objc(provideKeyForCLBeacon:)
    static func provideKeyForCLBeacon(_ beacon: CLBeacon) -> String {
        let Dash = "-"
        var identityKey: String
        
        if #available(iOS 13.0, *) {
            identityKey = beacon.uuid.uuidString
        } else {
            identityKey = beacon.proximityUUID.uuidString
        }
        identityKey.append(Dash)
        identityKey.append(beacon.major.stringValue)
        identityKey.append(Dash)
        identityKey.append(beacon.minor.stringValue)
        return identityKey
    }
    
    static func provideUUIDFromSILDiscoveredPeripheralMap(_ mapping: SILDiscoveredPeripheral) -> NSUUID {
        // for example E2C56DB5-DFFB-48D2-B060-D0F5A71096E0 -> 36 characters
        let UUIDLength = 36
        let identityKey = mapping.identityKey
        let uuid = identityKey.prefix(UUIDLength)
        let uuidString = String(uuid)
        guard let nsuuid = NSUUID(uuidString: uuidString) else { return NSUUID() }
        return nsuuid
    }
}
