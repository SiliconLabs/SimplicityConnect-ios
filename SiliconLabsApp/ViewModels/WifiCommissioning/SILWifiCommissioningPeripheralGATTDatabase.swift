//
//  SILWifiCommissioningPeripheralGATTDatabase.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 06/12/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct SILWifiCommissioningPeripheralGATTDatabase {
    struct WifiCommissioningService {
        static let uuid = "AABB"
        static let cbUUID = CBUUID(string: uuid)
        
        struct WriteCharacteristic {
            static let uuid = "1AA1"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct ReadCharacteristic {
            static let uuid = "1BB1"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct NotifyCharacteristic {
            static let uuid = "1CC1"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
}
