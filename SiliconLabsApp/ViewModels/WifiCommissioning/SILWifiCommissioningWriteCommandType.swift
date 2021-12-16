//
//  SILWifiCommissioningWriteCommandType.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 24/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

enum SILWifiCommissioningWriteCommandType: Equatable {
    case unknown
    case customId
    case join(_ accessPointName: String?)
    case scan
    case disconnect
    case security(_ type: SILWifiCommissioningSecurityType?)
    case password(_ password: String?)
    case connectionStatus
    case readFirmware
    
    static func ==(lhs: SILWifiCommissioningWriteCommandType, rhs: SILWifiCommissioningWriteCommandType) -> Bool {
        return lhs.intValue == rhs.intValue
    }
    
    var intValue: Int {
        get {
            switch self {
            case .unknown:
                return 0
            case .customId:
                return 1
            case .join(_):
                return 2
            case .scan:
                return 3
            case .disconnect:
                return 4
            case .security(_):
                return 5
            case .password(_):
                return 6
            case .connectionStatus:
                return 7
            case .readFirmware:
                return 8
            }
        }
    }
    
    static func fromInt(_ intVal: Int) -> SILWifiCommissioningWriteCommandType? {
        switch intVal {
        case 0:
            return .unknown
        case 1:
            return .customId
        case 2:
            return .join(nil)
        case 3:
            return .scan
        case 4:
            return .disconnect
        case 5:
            return .security(nil)
        case 6:
            return .password(nil)
        case 7:
            return .connectionStatus
        case 8:
            return .readFirmware
        default:
            return nil
        }
    }
    
    var command: Data? {
        get {
            switch self {
            case .scan, .readFirmware, .connectionStatus, .disconnect:
                return Data("\(self.intValue)".utf8)
            case .join(let val), .password(let val):
                if let val = val {
                    return Data("\(self.intValue)\(getTwoDigitsStringLength(val.count))\(val)".utf8)
                }
            case .security(let type):
                if let type = type {
                    let typeString = "\(type.rawValue)"
                    return Data("\(self.intValue)\(getTwoDigitsStringLength(typeString.count))\(typeString)".utf8)
                }
            default:
                return nil
            }
            return nil
        }
    }
    
    private func getTwoDigitsStringLength(_ val: Int) -> String {
        return String(format: "%02d", val)
    }
}

enum SILWifiCommissioningReadCommandType: Int {
    case unknown = 0
    case customId = 1
    case join = 2
    case scan = 3
    case disconnect = 4
    case connectionStatus = 7
    case readFirmware = 8
}

enum SILWifiCommissioningNotifyState: Int {
    case unknown = -1
    case scanning = 0
    case connected = 1
}
