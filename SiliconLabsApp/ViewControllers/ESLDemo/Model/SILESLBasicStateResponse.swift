//
//  SILESLBasicStateResponse.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 10.5.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation

struct SILESLBasicState: OptionSet, CustomStringConvertible {
    var rawValue: UInt16
    
    static let serviceNeeded = SILESLBasicState(rawValue: 1 << 0)
    static let synchronized = SILESLBasicState(rawValue: 1 << 1)
    static let activeLED = SILESLBasicState(rawValue: 1 << 2)
    static let pendingLEDUpdate = SILESLBasicState(rawValue: 1 << 3)
    static let pendingDisplayUpdate = SILESLBasicState(rawValue: 1 << 4)
    static let rfu = SILESLBasicState(rawValue: 1 << 5)
    
    init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    var description: String {
        switch self.rawValue {
        case SILESLBasicState.serviceNeeded.rawValue:
            return "The ESL has detected a condition that needs service"
    
        case SILESLBasicState.synchronized.rawValue:
            return "The ESL is synchronized to the AP"

        case SILESLBasicState.activeLED.rawValue:
            return "The ESL has an active LED:"
    
        case SILESLBasicState.pendingLEDUpdate.rawValue:
            return "The ESL has a timed LED update pending"
    
        case SILESLBasicState.pendingDisplayUpdate.rawValue:
            return "The ESL has a timed display update pending"
    
        default:
            return "Reserved for Future Use"
        }
    }
}

struct SILESLBasicStateResponse: SILESLResponseData, CustomStringConvertible, Equatable {
    let states: [SILESLBasicState]
    let activeLed: UInt8
    
    var description: String {
        var i = 0
        var desc = ""
        for state in states {
            if i != 0 {
                desc.append("\n")
            }
            
            if state == .activeLED {
                desc.append("\(state.description) index \(activeLed)")
            } else {
                desc.append(state.description)
            }
            i += 1
        }
        
        return desc
    }
    
    init(bits: UInt8, activeLed: UInt8) {
        var basicStates: [SILESLBasicState] = []
        if ((bits & 0b00000001) >> 0) == 1 {
            basicStates.append(.serviceNeeded)
        }
        if ((bits & 0b00000010) >> 1) == 1 {
            basicStates.append(.synchronized)
        }
        if ((bits & 0b00000100) >> 2) == 1 {
            basicStates.append(.activeLED)
        }
        if ((bits & 0b00001000) >> 3) == 1 {
            basicStates.append(.pendingLEDUpdate)
        }
        if ((bits & 0b00010000) >> 4) == 1 {
            basicStates.append(.pendingDisplayUpdate)
        }
        
        if basicStates.isEmpty {
            basicStates.append(.rfu)
        }
        
        self.activeLed = activeLed
        self.states = basicStates
    }
}

