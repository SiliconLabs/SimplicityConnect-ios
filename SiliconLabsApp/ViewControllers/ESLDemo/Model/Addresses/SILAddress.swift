//
//  SILAddress.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 24.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

enum SILAddress: RawRepresentable, Equatable {
    typealias RawValue = String
    
    case btAddress(_ address: SILBluetoothAddress)
    case eslId(_ id: SILESLIdAddress)
    
    init?(rawValue: String) {
        if let eslId = SILESLIdAddress(rawValue: rawValue) {
            self = .eslId(eslId)
            return
        } else {
            let btAddress = SILBluetoothAddress(address: rawValue, addressType: .public)
            self = .btAddress(btAddress)
            return
        }
    }
    
    var rawValue: String {
        get {
            switch self {
            case .btAddress(let btAddress):
                return btAddress.address
            
            case .eslId(let id):
                return id.rawValue
            }
        }
    }
}
