//
//  SILManufacturerData.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 10/01/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

extension Data {
    func checkManufacturerData(manufacturerIdentifier: Int, manufacturerData expected: [UInt8], manufacturerDataMask mask: [UInt8]? = nil) -> Bool {
        let length = self.bytes.count
        guard length > 2 else {
            return false
        }
        let idBytes = Data(bytes: self.bytes[0...1])
        guard idBytes.integerValueFromData() == manufacturerIdentifier else {
            return false
        }
        
        let data = Data(bytes: self.bytes[2...(length - 1)])
        guard data.bytes.count == expected.count else {
            return false
        }
        
        let mask = mask ?? Array(repeating: 1, count: expected.count)
        let zipped = Array(zip(expected, mask))
        for (ind, (expectedByte, maskByte)) in zipped.enumerated() {
            if maskByte != 0 && data.bytes[ind] != expectedByte {
                return false
            }
        }
        return true
    }
}
