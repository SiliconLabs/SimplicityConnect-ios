//
//  CharacteristicFieldValueConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 29/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

protocol CharacteristicFieldValueConverter {
    func dataToString(_ data : Data, fieldModel : SILBluetoothFieldModel) -> Result<String, Error>
    func stringToData(_ string : String, fieldModel : SILBluetoothFieldModel) -> Result<Data, Error>
}

extension CharacteristicFieldValueConverter {
    func reverseDataIfNeeded(data: Data, reverse: Bool) -> Data {
        reverse ? .init(bytes: data.reversed()) : data
    }
    
    func stringMatchesRegex(string: String, regex: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: regex, options: .init())
        let searchedRange = NSMakeRange(0, string.count)
        let numberOfMatches = regex?.numberOfMatches(in: string, range: searchedRange)
        
        return numberOfMatches == 1
    }
}
