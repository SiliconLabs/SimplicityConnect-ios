//
//  AsciiStringConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 29/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

class AsciiStringConverter : StringConverter {
    
    init() {
        super.init(encoding: .ascii)
    }
    
    override func dataToString(_ data: Data, fieldModel : SILBluetoothFieldModel) -> Result<String, Error> {
        super.dataToString(data, fieldModel: fieldModel)
            .map{ $0.map{ $0.isASCII ? $0 : "\u{fffd}"} }
            .map { String($0) }
    }
}
