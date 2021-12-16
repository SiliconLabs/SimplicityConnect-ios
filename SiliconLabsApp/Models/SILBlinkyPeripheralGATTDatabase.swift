//
//  SILBlinkyPeripheralGATTDatabase.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 30/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct SILBlinkyPeripheralGATTDatabase {
    struct BlinkyService {
        static let uuid = "de8a5aac-a99b-c315-0c80-60d4cbb51224"
        static let cbUUID = CBUUID(string: uuid)
        
        struct LightCharacteristic {
            static let uuid = "5b026510-4088-c297-46d8-be6c736a087a"
            static let cbUUID = CBUUID(string: uuid)
            
            struct WriteValues {
                static let TurnOff = Data(bytes: [0x00], count: 1)
                static let TurnOn = Data(bytes: [0x01], count: 1)
            }
        }
        
        struct ReportButtonCharacteristic {
            static let uuid = "61a885a4-41c3-60d0-9a53-6d652a70d29c"
            static let cbUUID = CBUUID(string: uuid)
            
            struct ReadValues {
                static let Released = Data(bytes: [0x00], count: 1)
                static let Pressed = Data(bytes: [0x01], count: 1)
            }
        }
    }
}
