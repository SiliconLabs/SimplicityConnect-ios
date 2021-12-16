//
//  SILThunderboardPeripheralGATTDatabase.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 30/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct SILThunderboardPeripheralGATTDatabase {
    struct ThunderboardService {
        static let uuid = "0x1815"
        static let cbUUID = CBUUID(string: uuid)
        
        struct LightCharacteristic {
            static let uuid = "0x2A56"
            static let cbUUID = CBUUID(string: uuid)
            static let properties: CBCharacteristicProperties = [.read, .write]
            
            struct WriteValues {
                static let TurnOff = Data(bytes: [0x00], count: 1)
                static let TurnOn = Data(bytes: [0x01], count: 1)
            }
        }
        
        struct ReportButtonCharacteristic {
            static let uuid = "0x2A56"
            static let cbUUID = CBUUID(string: uuid)
            static let properties: CBCharacteristicProperties = [.read, .notify]
            
            struct ReadValues {
                static let Released = Data(bytes: [0x00], count: 1)
                static let Pressed = Data(bytes: [0x01], count: 1)
            }
        }
    }
    
    struct BatteryService {
        static let uuid = "0x180F"
        static let cbUUID = CBUUID(string: uuid)
        
        struct BatteryLevelCharacteristic {
            static let uuid = "0x2A19"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
    
    struct PowerSourceCustomService {
        static let uuid = "EC61A454-ED00-A5E8-B8F9-DE9EC026EC51"
        static let cbUUID = CBUUID(string: uuid)
        
        struct PowerSourceCustomCharacteristic {
            static let uuid = "EC61A454-ED01-A5E8-B8F9-DE9EC026EC51"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
    
    struct DeviceInformationService {
        static let uuid = "0x180A"
        static let cbUUID = CBUUID(string: uuid)
        
        struct FirmwareRevisionCharacteristic {
            static let uuid = "0x2A26"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
}
