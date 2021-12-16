//
//  BleManager+DiscoveryFiltering.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import CoreBluetooth

extension BleManager {
    
    func isThunderboard(_ peripheralName: String) -> Bool {
        return peripheralName.hasPrefix("Thunder") || peripheralName.hasPrefix("TBS")
    }
}
