//
//  CharacteristicFieldValueConverterError.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 29/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

enum CharacteristicFieldValueConverterError : Error {
    case wrongString(input : String)
    case wrongData(input : Data)
    case unknownFormat(format : String)
}
