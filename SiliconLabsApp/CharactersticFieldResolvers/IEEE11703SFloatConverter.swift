//
//  IEEE11703SFloatConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 06/09/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
class IEEE11703SFloatConverter : CharacteristicFieldValueConverter {
    private let regexPattern = "^[+-]?\\d+(\\.\\d{0,})?$"
    
    func dataToString(_ data: Data, fieldModel: SILBluetoothFieldModel) -> Result<String, Error> {
        guard data.count == 2 else { return .failure(CharacteristicFieldValueConverterError.wrongData(input: data)) }
        
        let integerData = reverseDataIfNeeded(data: data, reverse: fieldModel.invertedBytesOrder).withUnsafeBytes { pointer in
            pointer.load(as: Int16.self)
        }
        
        let exponent = integerData >> 12
        let mantissa = (integerData << 4) >> 4
        
        let result = mantissa == (1 << 11) ? Double.nan : Double(mantissa) * pow(10, Double(exponent))
        
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
        
        let exponent = Int16(decimal.decimalValue.exponent)
        let mantissa = (decimal.decimalValue.significand as NSDecimalNumber).int16Value
        
        let result : Int16 = (mantissa & 0x0FFF) | ((exponent & 0x000F) << 12)
        
        let data = withUnsafePointer(to: result) { pointer in
            Data.init(bytes: pointer, count: 2)
        }
        return .success(reverseDataIfNeeded(data: data, reverse: fieldModel.invertedBytesOrder))
    }
}
