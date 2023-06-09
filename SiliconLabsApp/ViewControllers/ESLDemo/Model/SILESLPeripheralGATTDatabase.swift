//
//  SILESLPeripheralGATTDatabase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 20.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

struct SILESLPeripheralGATTDatabase {
    struct ESLDemoService {
        static let uuid = "35100001-4B1D-B16B-00B1-35018BADF00D"
        static let cbUUID = CBUUID(string: uuid)

        struct ESLControlPoint {
            static let uuid = "35100002-4B1D-B16B-00B1-35018BADF00D"
            static let cbUUID = CBUUID(string: uuid)
        }
        
        struct ESLTransferImage {
            static let uuid = "C40B5253-18B6-47BB-A6CC-52A4AC4C6FC3"
            static let cbUUID = CBUUID(string: uuid)
        }
    }
}

struct SILESLPeripheralGATTReferences {
    var eslDemoService: CBService?
    var eslControlPoint: CBCharacteristic?
    var eslTransferImage: CBCharacteristic?
}
