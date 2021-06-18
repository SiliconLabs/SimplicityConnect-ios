//
//  StringExtension.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 26/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import Foundation

extension String {    
    func data(withCount: Int) -> Data? {
        let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)
        
        guard hexStr.count % 2 == 0 else { return nil }
        var newData =  Data(capacity: count)
        
        var indexIsEven = true
        for i in hexStr.indices {
            if indexIsEven {
                let byteRange = i...hexStr.index(after: i)
                guard let byte = UInt8(hexStr[byteRange], radix: 16) else { return nil }
                newData.append(byte)
            }
            indexIsEven.toggle()
        }
        return newData
    }
    
    var hexToInt: String {
        guard let val =  Int(self, radix: 16) else { return "" }
        return String(describing: val)
    }
    
    func isValidEBLorGBLExtension() -> Bool {
        return self.lowercased() == "ebl" || self.lowercased() == "gbl"
    }

}
