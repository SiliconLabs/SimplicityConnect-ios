//
//  IntegerValueConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 05/08/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

fileprivate let regexPatternZeroDecimalExponent = "^[+-]?\\d+$"
fileprivate let regexPatternFormatPositiveDecimalExponent = "^[+-]?\\d+0{%ld,}$"
fileprivate let regexPatternFormatNegativeDecimalExponent = "^[+-]?\\d+(\\.\\d{0,%ld})?$"
let localeForNumberParsing = "en_US"

class IntegerValueConverter<T : FixedWidthInteger> : CharacteristicFieldValueConverter {
    let resultBitLength : Int
    
    init(resultBitLength: Int) {
        self.resultBitLength = resultBitLength
    }
    
    func dataToString(_ data: Data, fieldModel: SILBluetoothFieldModel) -> Result<String, Error> {
        let bitsToClear = T.bitWidth - resultBitLength
        let bitsToMove = bitsToClear % 8
        let tInteger = data.withUnsafeBytes { buffer in
            buffer.baseAddress?.load(as: T.self)
        }
        
        let correctlyOrderedInteger = fieldModel.invertedBytesOrder ? tInteger?.byteSwapped : tInteger
        let result = correctlyOrderedInteger
            .map { $0 >> bitsToMove }
            .map { ($0 << bitsToClear) >> bitsToClear }
            .map { T.isSigned ? NSNumber(value: Int64($0)) : NSNumber(value: UInt64($0)) }?
            .modify(from: fieldModel).stringValue
        
        return result.map { .success($0) } ?? .failure(CharacteristicFieldValueConverterError.wrongData(input: data))
    }
    
    fileprivate func regexPattern(forExponent decimalExponent: Int) -> String {
        if (decimalExponent == 0) {
            return regexPatternZeroDecimalExponent
        } else if (decimalExponent > 0) {
            return String.init(format: regexPatternFormatPositiveDecimalExponent, arguments: [decimalExponent])
        } else {
            return String.init(format: regexPatternFormatNegativeDecimalExponent, arguments: [-decimalExponent])
        }
    }
    
    func stringToData(_ string: String, fieldModel: SILBluetoothFieldModel) -> Result<Data, Error> {
        let cleanInput = string.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        
        let decimalExponent = fieldModel.decimalExponent;
        let regexPattern = regexPattern(forExponent: decimalExponent)
        let bitsToClear = T.bitWidth - resultBitLength
        
        guard self.stringMatchesRegex(string: cleanInput, regex: regexPattern) else {
            return .failure(CharacteristicFieldValueConverterError.wrongString(input: string))
        }
        
        let locale = Locale(identifier: localeForNumberParsing)
        let decimal = NSDecimalNumber(string: cleanInput, locale: locale)
        let finalNumber = decimal.modify(to: fieldModel)
        
        let result = finalNumber.verify(for: fieldModel)
            .map { T.isSigned ? T(clamping: $0.int64Value) : T(clamping: $0.uint64Value) }
            .map { ($0 << bitsToClear) >> bitsToClear }
            .map { fieldModel.invertedBytesOrder ? $0.byteSwapped : $0 }
            .map { withUnsafeBytes(of: $0) { Data(bytes: $0.baseAddress!, count: T.bitWidth/8) } }
        
        return result
    }
}
