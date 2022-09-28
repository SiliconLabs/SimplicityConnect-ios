//
//  CharacteristicFieldConverter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 02/09/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

enum CharacteristicFormat : String{
    case bitField8bit = "8bit", bitField16bit = "16bit", bitField24bit = "24bit", bitField32bit = "32bit"
    case uint8, uint16, uint24, uint32, uint40, uint48, uint64, uint128
    case sint8, sint12, sint16, sint24, sint32, sint48, sint64, sint128
    case float32, float64
    case IEEE11703SFloat = "SFLOAT", IEEE11703Float = "FLOAT"
    case dunit16
    case utf8String = "utf8s", utf16String = "utf16s"
    case regCert = "reg-cert-data-list"
    case variable
}

@objc class CharacteristicFieldConverter : NSObject {
    static let dict : [CharacteristicFormat : CharacteristicFieldValueConverter] = [
        .bitField8bit : IntegerValueConverter<UInt8>(resultBitLength: 8),
        .bitField16bit : IntegerValueConverter<UInt16>(resultBitLength: 16),
        .bitField24bit : IntegerValueConverter<UInt32>(resultBitLength: 24),
        .bitField32bit : IntegerValueConverter<UInt32>(resultBitLength: 32),
        .uint8 : IntegerValueConverter<UInt8>(resultBitLength: 8),
        .uint16 : IntegerValueConverter<UInt16>(resultBitLength: 16),
        .uint24 : IntegerValueConverter<UInt32>(resultBitLength: 24),
        .uint32 : IntegerValueConverter<UInt32>(resultBitLength: 32),
        .uint40 : IntegerValueConverter<UInt64>(resultBitLength: 40),
        .uint48 : IntegerValueConverter<UInt64>(resultBitLength: 48),
        .uint64 : IntegerValueConverter<UInt64>(resultBitLength: 64),
        .sint8 : IntegerValueConverter<Int8>(resultBitLength: 8),
        .sint12 : IntegerValueConverter<Int16>(resultBitLength: 12),
        .sint16 : IntegerValueConverter<Int16>(resultBitLength: 16),
        .sint24 : IntegerValueConverter<Int32>(resultBitLength: 24),
        .sint32 : IntegerValueConverter<Int32>(resultBitLength: 32),
        .sint48 : IntegerValueConverter<Int64>(resultBitLength: 48),
        .sint64 : IntegerValueConverter<Int64>(resultBitLength: 64),
        .dunit16 : IntegerValueConverter<UInt16>(resultBitLength: 16),
        .utf8String : StringConverter(encoding: .utf8),
        .utf16String : StringConverter(encoding: .utf16),
        .uint128 : HexStringConverter(),
        .sint128 : HexStringConverter(),
        .regCert : HexStringConverter(),
        .variable : HexStringConverter(),
        .float32 : BinaryFloatConverter<Float32>(bytesLength: 4),
        .float64 : BinaryFloatConverter<Float64>(bytesLength: 8),
        .IEEE11703SFloat : IEEE11703SFloatConverter(),
        .IEEE11703Float : IEEE11703FloatConverter()
    ]
    
    @objc func supports(fieldModel: SILBluetoothFieldModel) -> Bool {
        guard let format = CharacteristicFormat(rawValue: fieldModel.format) else { return false }
        return CharacteristicFieldConverter.dict[format] != nil
    }
    
    @objc func convertToData(fieldModel : SILBluetoothFieldModel, value : String) -> Data?{
        guard let format = CharacteristicFormat(rawValue: fieldModel.format),
                let converter = CharacteristicFieldConverter.dict[format]
        else { return nil }
        
        return try? converter.stringToData(value, fieldModel: fieldModel).get()
    }
    
    @objc func convertToString(fieldModel : SILBluetoothFieldModel, value : Data) -> String? {
        guard let format = CharacteristicFormat(rawValue: fieldModel.format),
                let converter = CharacteristicFieldConverter.dict[format]
        else { return nil }
        
        return try? converter.dataToString(value, fieldModel: fieldModel).get()
    }
}
