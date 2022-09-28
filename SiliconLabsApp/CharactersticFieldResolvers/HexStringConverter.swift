//
//  HexStringConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 03/09/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

class HexStringConverter : CharacteristicFieldValueConverter {
    func dataToString(_ data: Data, fieldModel: SILBluetoothFieldModel) -> Result<String, Error> {
        
        let result = reverseDataIfNeeded(data: data, reverse: fieldModel.invertedBytesOrder).bytes.map {
            String(format:"%02X", $0)
        }.joined()
        
        return .success(result)
    }
    
    func stringToData(_ string: String, fieldModel: SILBluetoothFieldModel) -> Result<Data, Error> {
        let hexPairs = string.splitToPairs().map { String($0) }.map { $0.count == 1 ? "0" + $0 : $0 }
        
        
        let isLegalHexString = hexPairs.allSatisfy {
            $0.isLegalHexPair()
        }
        
        guard isLegalHexString else { return .failure(CharacteristicFieldValueConverterError.wrongString(input: string)) }
        
        let hexBytes = hexPairs.map {
            UInt8($0, radix: 16)!
        }
        
        let result = reverseDataIfNeeded(data: Data(bytes: hexBytes), reverse: fieldModel.invertedBytesOrder)
        
        return .success(result)
    }
}

extension String {
    fileprivate func isLegalHexPair() -> Bool {
        let hexInt = UInt8(self, radix: 16)
        return self.count == 2 && hexInt != nil
    }
    
    fileprivate func splitToPairs() -> [String] {
        var result = [String]()
        var left = self
        while left.count > 1 {
            result.append(left[0...1])
            left = String(left.dropFirst(2))
        }
        
        if left.count == 1 {
            result.append(left)
        }
        
        return result
    }
}
