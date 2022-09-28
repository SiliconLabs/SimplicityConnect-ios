//
//  NSNumber+FieldModelModifier.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 04/08/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

fileprivate let decimalHandler = NSDecimalNumberHandler(roundingMode: .plain, scale: NSDecimalNumberHandler.default.scale(), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)

extension NSNumber {
    
    func modify(from fieldModel: SILBluetoothFieldModel) -> NSNumber {
        let multiplier = NSDecimalNumber(integerLiteral: fieldModel.multiplier)
        return NSDecimalNumber(decimal: self.decimalValue)
            .multiplying(by: multiplier, withBehavior: decimalHandler)
            .multiplying(byPowerOf10: Int16(fieldModel.decimalExponent), withBehavior: decimalHandler)
    }
    
    func modify(to fieldModel: SILBluetoothFieldModel) -> NSNumber {
        let divisor = NSDecimalNumber(integerLiteral: fieldModel.multiplier)
        return NSDecimalNumber(decimal: self.decimalValue)
            .dividing(by: divisor, withBehavior: decimalHandler)
            .multiplying(byPowerOf10: Int16(-fieldModel.decimalExponent), withBehavior: decimalHandler)
    }
    
    func verify(for fieldModel: SILBluetoothFieldModel) -> Result<NSNumber, Error> {
        return .success(self)
    }
}
