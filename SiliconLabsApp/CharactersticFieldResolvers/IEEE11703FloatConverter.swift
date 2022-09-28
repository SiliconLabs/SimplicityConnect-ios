//
//  IEEE11703FloatConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 05/09/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

class IEEE11703FloatConverter : CharacteristicFieldValueConverter {
    private let regexPattern = "^[+-]?\\d+(\\.\\d{0,})?$"
    
    func dataToString(_ data: Data, fieldModel: SILBluetoothFieldModel) -> Result<String, Error> {
        guard data.count == 4 else { return .failure(CharacteristicFieldValueConverterError.wrongData(input: data)) }
        
        let integerData = reverseDataIfNeeded(data: data, reverse: fieldModel.invertedBytesOrder).withUnsafeBytes { pointer in
            pointer.load(as: Int32.self)
        }
        
        let exponent = integerData >> 24
        let mantissa = (integerData << 8) >> 8
        
        let result = mantissa == (1 << 23) ? Double.nan : Double(mantissa) * pow(10, Double(exponent))
        
        let resultNumber = NSNumber(floatLiteral: result).modify(from: fieldModel)
        
        return .success(resultNumber.stringValue)
    }
    
    func stringToData(_ string: String, fieldModel: SILBluetoothFieldModel) -> Result<Data, Error> {
        let cleanInput = string.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        
        guard self.stringMatchesRegex(string: cleanInput, regex: regexPattern) else {
            return .failure(CharacteristicFieldValueConverterError.wrongString(input: string))
        }
        
        let locale = Locale(identifier: localeForNumberParsing)
        let decimal = NSDecimalNumber(string: cleanInput, locale: locale).modify(to: fieldModel)
        
        let exponent = Int32(decimal.decimalValue.exponent)
        let mantissa = (decimal.decimalValue.significand as NSDecimalNumber).int32Value
        
        let result : Int32 = (mantissa & 0x00FFFFFF) | ((exponent & 0x000000FF) << 24)
        
        let data = withUnsafePointer(to: result) { pointer in
            Data.init(bytes: pointer, count: 4)
        }
        return .success(reverseDataIfNeeded(data: data, reverse: fieldModel.invertedBytesOrder))
    }
}
