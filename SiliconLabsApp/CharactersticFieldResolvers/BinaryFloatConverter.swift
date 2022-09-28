//
//  BinaryFloatConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 05/09/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

class BinaryFloatConverter<T : BinaryFloatingPoint> : CharacteristicFieldValueConverter {
    let bytesLength : Int
    let regexPattern = "^[+-]?\\d+(\\.\\d{0,})?$"
    
    init(bytesLength: Int) {
        self.bytesLength = bytesLength
    }
    
    func dataToString(_ data: Data, fieldModel: SILBluetoothFieldModel) -> Result<String, Error> {
        guard data.count == bytesLength else { return .failure(CharacteristicFieldValueConverterError.wrongData(input: data)) }
        
        let result = reverseDataIfNeeded(data: data, reverse: fieldModel.invertedBytesOrder).withUnsafeBytes { pointer in
            pointer.load(as: T.self)
        }
        
        return .success(NSNumber(floatLiteral: Double(result)).modify(from: fieldModel).stringValue)
    }
    
    func stringToData(_ string: String, fieldModel: SILBluetoothFieldModel) -> Result<Data, Error> {
        let cleanInput = string.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        
        guard self.stringMatchesRegex(string: cleanInput, regex: regexPattern) else {
            return .failure(CharacteristicFieldValueConverterError.wrongString(input: string))
        }
        
        let locale = Locale(identifier: localeForNumberParsing)
        let decimal = NSDecimalNumber(string: cleanInput, locale: locale).modify(to: fieldModel)
        
        let result = T(decimal.floatValue)
        
        let data = withUnsafePointer(to: result) { pointer in
            Data.init(bytes: pointer, count: bytesLength)
        }
        
        return .success(data)
    }
}
