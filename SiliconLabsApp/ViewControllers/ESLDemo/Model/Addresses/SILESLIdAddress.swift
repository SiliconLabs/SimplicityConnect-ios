//
//  SILESLIdAddress.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 24.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

enum SILESLIdAddress: RawRepresentable, Equatable {
    typealias RawValue = String
    
    case unicast(id: UInt)
    case broadcast
    
    init?(rawValue: String) {
        if rawValue == "all" {
            self = .broadcast
            return
        } else if let id = UInt(rawValue) {
            self = .unicast(id: id)
            return
        }
        
        return nil
    }
    
    var rawValue: String {
        get {
            switch self {
            case .unicast(id: let id):
                return "\(id)"
                
            case .broadcast:
                return "all"
            }
        }
    }
}
