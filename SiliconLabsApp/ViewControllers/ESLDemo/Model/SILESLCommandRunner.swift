//
//  SILESLCommandRunner.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

protocol SILESLResponseError: Error { }

enum SILESLCommandGenericError: SILESLResponseError, Equatable, LocalizedError {
    case missingCharacteristic
    case errorFromCharacteristic(error: Error)
    case characteristicIsntNotifying
    case errorFromAccessPoint
    case timeout
    case unknown
    case tagResponseError(error: SILESLDisplayImageError)
    
    static func == (lhs: SILESLCommandGenericError, rhs: SILESLCommandGenericError) -> Bool {
        switch (lhs, rhs) {
        case (.missingCharacteristic, .missingCharacteristic):
            return true
            
        case (.errorFromCharacteristic(error: let lhsError), .errorFromCharacteristic(error: let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        case (.characteristicIsntNotifying, .characteristicIsntNotifying):
            return true
            
        case (.errorFromAccessPoint, .errorFromAccessPoint):
            return true
            
        case (.timeout, .timeout):
            return true
        
        case (.unknown, .unknown):
            return true
    
        default:
            return false
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .missingCharacteristic:
            return "Missing ESL Control Point characteristic."
        case .errorFromCharacteristic(error: let error):
            return "Error from ESL Control Point characteristic: \(error.localizedDescription)."
        case .characteristicIsntNotifying:
            return "Characteristic ESL Control Point isn't notifying."
        case .errorFromAccessPoint:
            return "Error when processing command through Access Point."
        case .timeout:
            return "Timeout occurs."
        case .unknown:
            return "Unknown error."
        case .tagResponseError(error: let error):
            return "\(error.localizedDescription)"
        }
    }
}

protocol SILESLResponseData { }

extension Bool: SILESLResponseData { }

protocol SILESLCommand {
    var dataToSend: [UInt8] { get }
    var name: String { get }
    var opcode: UInt8 { get }
    func getFullCommand() -> String
}

extension SILESLCommand {
    var dataToSend: [UInt8] {
        get {
            let command = getFullCommand()
            return command.bytes
        }
    }
}

class SILESLCommandCompound: SILESLCommand {
    var name: String = ""
    var opcode: UInt8 = 100
    
    func getFullCommand() -> String {
        return ""
    }
}

protocol SILESLCommandRunner {
    associatedtype T: SILESLResponseData
    associatedtype W: SILESLResponseError
    associatedtype S: SILESLCommand
    
    var commandResult: PublishRelay<Result<T, W>> { get }
    
    func perform(timeout: TimeInterval)
}
