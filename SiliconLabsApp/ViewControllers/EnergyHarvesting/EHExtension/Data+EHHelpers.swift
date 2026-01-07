//
//  Data+EHHelpers.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 29/09/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation
extension Data {
 func decodeManufacturerDataForEnergyHarvesting() -> String {
        var manufacturerDataString = ""
        var voltageValueString: String = ""
     let parsedBytes = hexEncodedString(data: self)
        
        if parsedBytes.count < 4 {
            manufacturerDataString += "PARSING ERROR: "
            manufacturerDataString += parsedBytes
            return manufacturerDataString
        }
        
        let companyCodeIndex = parsedBytes.index(parsedBytes.startIndex, offsetBy: 4)
        let companyCodeBytes = parsedBytes.prefix(upTo: companyCodeIndex)
        let companyCodeSecondByteIndex = companyCodeBytes.index(companyCodeBytes.startIndex, offsetBy: 2)
        let companyCodeSecondByte = companyCodeBytes.prefix(upTo: companyCodeSecondByteIndex)
        let companyCodeFirstByte = companyCodeBytes.suffix(from: companyCodeSecondByteIndex)
        
        manufacturerDataString += "Company Code: 0x"
        manufacturerDataString += companyCodeFirstByte
        manufacturerDataString += companyCodeSecondByte
        
        if parsedBytes.count == 4 {
            return manufacturerDataString
        }
        
        let data = parsedBytes.suffix(from: companyCodeIndex)
        
        manufacturerDataString += "\nData: 0x"
        manufacturerDataString += data
        print(manufacturerDataString)
        voltageValueString = "0x\(data)"
        return voltageValueString
    }
    
    fileprivate func hexEncodedString(data: Data) -> String {
        let format = "%02hhX"
        return data.map { String(format: format, $0) }.joined()
    }
}

extension String {
    func hexToMillivolts() -> Int {
        let hexString = self.replacingOccurrences(of: "0x", with: "").uppercased()
        let hexDigits = Array(hexString)
        
        var result = 0
        for (index, digit) in hexDigits.reversed().enumerated() {
            let value: Int
            if let intVal = Int(String(digit)) {
                value = intVal
            } else {
                // Convert A-F to 10-15
                value = Int(digit.unicodeScalars.first!.value) - 55
            }
            result += value * Int(pow(16.0, Double(index)))
        }
        
        return result
    }
}
