//
//  CBAttribute+UUID.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 24/04/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import CoreBluetooth

@objc
extension CBAttribute {
    static let AssignedNumberStringLenght = 4
    static let HexBeginning = "0x"
    
    @objc
    func hasAssignedNumber() -> Bool {
        return uuid.uuidString.count == CBAttribute.AssignedNumberStringLenght
    }
    
    @objc
    func getHexUuidValue() -> String {
        return hasAssignedNumber() ? CBAttribute.HexBeginning + self.uuid.uuidString : self.uuid.uuidString
    }
}
