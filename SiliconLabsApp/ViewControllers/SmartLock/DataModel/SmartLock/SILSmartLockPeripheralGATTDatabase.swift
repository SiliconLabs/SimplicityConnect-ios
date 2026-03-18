//
//  SILSmartLockPeripheralGATTDatabase.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 26/06/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation

struct SILSmartLockPeripheralGATTDatabase {
    struct SmartLockService {
        static let uuid = "0xAABB"
        static let cbUUID = CBUUID(string: uuid)
        
        struct SmartLockCharacteristic {
            static let uuid = "0x1AA1"
            static let cbUUID = CBUUID(string: uuid)
            
            struct WriteValues {
               // static let lock = Data(bytes: [0x3031], count: 2)
               // static let unlock = Data(bytes: [0x3131], count: 2)
                static let lock = Data(bytes: [0x01], count: 1)
                static let unlock = Data(bytes: [0x00], count: 1)

            }
        }
        
        struct SmartLockStateCharacteristic {
            static let uuid = "1CC1"
            static let cbUUID = CBUUID(string: uuid)
            
            struct WriteValues {
                static let stateReadQuery = Data(bytes: [0x39], count: 1)
            }
        }
    }
}
