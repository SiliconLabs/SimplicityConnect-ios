//
//  StringConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 29/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

class StringConverter : CharacteristicFieldValueConverter {
    let encoding: String.Encoding
    init(encoding: String.Encoding) {
        self.encoding = encoding
    }
    
    func dataToString(_ data: Data, fieldModel : SILBluetoothFieldModel) -> Result<String, Error> {
        let resultString = String(data: data, encoding: encoding)
        if let resultString = resultString {
            return .success(resultString)
        }else {
            return .failure(CharacteristicFieldValueConverterError.wrongData(input: data))
        }
    }
    
    func stringToData(_ string: String, fieldModel : SILBluetoothFieldModel) -> Result<Data, Error> {
        let resultData = string.data(using: encoding)
        
        if let resultData = resultData {
            return .success(resultData)
        } else {
            return .failure(CharacteristicFieldValueConverterError.wrongString(input: string))
        }
    }
}
