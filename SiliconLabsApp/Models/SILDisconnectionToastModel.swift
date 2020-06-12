//
//  SILDisconnectionToastModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 11/05/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import CoreBluetooth
import Foundation

@objc
class SILDisconnectionToastModel : NSObject, SILToastModelType {
    let peripheralName: String
    let errorCode: Int
    let peripheralWasConnected: Bool
    var errorDescription: String {
        guard let CBErrorCode = CBError.Code(rawValue: errorCode) else {
            return "Unspecified error"
        }
        switch CBErrorCode {
        case .unknown:
            return "0x0085 GATT Error"
        case .invalidParameters:
            return "0x0002 The specified parameters are invalid"
        case .invalidHandle:
            return "0x0002 The specified attribute handle is invalid"
        case .notConnected:
            return "0x0085 The device isn’t currently connected"
        case .outOfSpace:
            return "0x0007 The device has run out of space to complete the intended operation"
        case .operationCancelled:
            return "0x0100 The connection canceled"
        case .connectionTimeout:
            return "0x0008 The connection timed out"
        case .peripheralDisconnected:
            return "0x0013 The peripheral disconnected"
        case .uuidNotAllowed:
            return "0x0085 The specified UUID isn’t permitted"
        case .alreadyAdvertising:
            return "0x0085 The peripheral is already advertising"
        case .connectionFailed:
            return "0x003E The connection failed"
        case .connectionLimitReached:
            return "0x0009 The device already has the maximum number of connections"
        case .unkownDevice:
            return "0x0085 The device is unknown"
        case .operationNotSupported:
            return "0x0085 The operation isn’t supported"
        @unknown default:
            return "Unspecified error"
        }
    }
    
    @objc
    init(peripheralName: String, errorCode: Int, peripheralWasConnected: Bool) {
        self.peripheralName = peripheralName
        self.errorCode = errorCode
        self.peripheralWasConnected = peripheralWasConnected
    }
    
    @objc
    func getErrorMessageForToast() -> String {
        if peripheralWasConnected {
            return "Device \(peripheralName) has disconnected\nReason: \(errorDescription)"
        } else {
            return "Failed connecting to: \(peripheralName)\nReason: \(errorDescription)"
        }
    }
}
