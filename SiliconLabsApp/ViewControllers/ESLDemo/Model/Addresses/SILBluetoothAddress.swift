//
//  SILBluetoothAddress.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 24.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

enum SILBluetoothAddressType: String {
    case `public`
    case `static`
    case rand_res
    case rand_nonres
}

struct SILBluetoothAddress: Equatable {
    let address: String
    let addressType: SILBluetoothAddressType
    
    var isValid: Bool {
        get {
            return validate()
        }
    }
    
    init(address: String, addressType: SILBluetoothAddressType) {
        self.address = address
        self.addressType = addressType
    }
    
    private func validate() -> Bool {
        switch addressType {
        case .public:
            return validatePublicAddress()
        
        default:
            return true
        }
    }
    
    private func validatePublicAddress() -> Bool {
        guard address.count == 17 else {
            return false
        }
        
        for i in stride(from: 2, to: 17, by: 3) {
            if address[i] != ":" {
                return false
            }
        }
        
        let addressWithoutSeparators = address.replacingOccurrences(of: ":", with: "")
        
        guard addressWithoutSeparators.count == 12 else {
            return false
        }
        
        for i in 0..<addressWithoutSeparators.count - 1 {
            let char = Character(addressWithoutSeparators[i])
            if !char.isHexDigit {
                return false
            }
        }
        
        return true
    }
}
