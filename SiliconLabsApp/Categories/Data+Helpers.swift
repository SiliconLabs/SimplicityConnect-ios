//
//  Data+Helpers.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 20.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

extension Data {
    // Could make a more optimized one~
    func hexa(prefixed isPrefixed:Bool = true) -> String {
        return self.bytes.reduce(isPrefixed ? "0x" : "") { $0 + String(format: "%02X", $1) }
    }
    
    func integerValueFromData() -> Int {
        let dataArray = convertData(data: self)
        let value = integerFromBytesArray(bytesArray: dataArray)
        
        return value
    }
    
    fileprivate func convertData(data: Data) -> [UInt8] {
        return [UInt8](data)
    }
    
    fileprivate func integerFromBytesArray(bytesArray: [UInt8]) -> Int {
        var value = 0
        for (i, byteValue) in bytesArray.enumerated() {
            let shiftValue = pow(2.0, i * 8)
            let shiftValueInt = (shiftValue as NSDecimalNumber).intValue
            value += (Int(byteValue) * shiftValueInt)
        }
        return value
    }
    
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}
