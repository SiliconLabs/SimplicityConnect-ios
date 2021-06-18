//
//  SILThroughputPeripheral.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 26.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct SILThroughputPeripheralGATTDatabase {
    struct ThroughputService {
        static let uuid = "BBB99E70-FFF7-46CF-ABC7-2D32C71820F2"
        static let cbUUID = CBUUID(string: uuid)

        struct ThroughputIndications {
            static let uuid = "6109B631-A643-4A51-83D2-2059700AD49F"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct ThroughputNotifications {
            static let uuid = "47B73DD6-DEE3-4DA1-9BE0-F5C539A9A4BE"
            static let cbUUID = CBUUID(string: uuid)
        }
            
        struct TransmissionOn {
            static let uuid = "BE6B6BE1-CD8A-4106-9181-5FFE2BC67718"
            static let cbUUID = CBUUID(string: uuid)
            
            struct WriteValues {
                static let disable = Data(bytes: [0x00], count: 1)
                static let active = Data(bytes: [0x01], count: 1)
            }
        }
        
        struct ThroughputResult {
            static let uuid = "ADF32227-B00F-400C-9EEB-B903A6CC291B"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
    
    struct ThroughputInformationService {
        static let uuid = "ba1e0e9f-4d81-bae3-f748-3ad55da38b46"
        static let cbUUID = CBUUID(string: uuid)

        struct PHYStatus {
            static let uuid = "00A82B93-0FEB-2739-72BE-ABDA1F5993D0"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct ConnectionInterval {
            static let uuid = "0A32F5A6-0A6C-4954-F413-A698FAF2C664"
            static let cbUUID = CBUUID(string: uuid)
        }
            
        struct SlaveLatency {
            static let uuid = "ff629b92-332b-e7f7-975f-0e535872ddae"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct SupervisionTimeout {
            static let uuid = "67E2C4F2-2F50-914C-A611-ADB3727B056D"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct PDUSize {
            static let uuid = "30CC364A-0739-268C-4926-36F112631E0C"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct MTUSize {
            static let uuid = "3816DF2F-D974-D915-D26E-78300F25E86E"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
}

struct SILThroughputPeripheralGATTReferences {
    var throughputService: CBService?
    var throughputIndications: CBCharacteristic?
    var throughputNotifications: CBCharacteristic?
    var throughputTransmissionOn: CBCharacteristic?
    var throughputResult: CBCharacteristic?
    
    var throughputInformationService: CBService?
    var phyStatus: CBCharacteristic?
    var connectionInterval: CBCharacteristic?
    var slaveLatency: CBCharacteristic?
    var supervisionTimeout: CBCharacteristic?
    var pduSize: CBCharacteristic?
    var mtuSize: CBCharacteristic?
}
