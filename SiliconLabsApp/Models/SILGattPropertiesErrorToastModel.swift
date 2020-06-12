//
//  SILGattPropertiesErrorToastModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 01/06/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc
class SILGattPropertiesErrorToastModel : NSObject, SILToastModelType {
    let peripheralName: String
    let errorCode: Int
    var errorDescription: String {
        guard let CBATTErrorCode = CBATTError.Code(rawValue: errorCode) else {
            return "Unspecified error"
        }
        switch CBATTErrorCode {
        case .success:
            return "The ATT command or request successfully completed"
        case .invalidHandle:
            return "0x0001 The attribute handle is invalid on this peripheral"
        case .readNotPermitted:
            return "0x0002 The permissions prohibit reading the attribute’s value"
        case .writeNotPermitted:
            return "0x0003 The permissions prohibit writing the attribute’s value"
        case .invalidPdu:
            return "0x0004 The attribute Protocol Data Unit (PDU) is invalid"
        case .insufficientAuthentication:
            return "0x0005 Failed for lack of authentication."
        case .requestNotSupported:
            return "0x0006 The attribute server doesn’t support the request received from the client"
        case .invalidOffset:
            return "0x0007 The specified offset value was past the end of the attribute’s value"
        case .insufficientAuthorization:
            return "0x0008 Failed for lack of authorization."
        case .prepareQueueFull:
            return "0x0009 The prepare queue is full, too many write requests in the queue"
        case .attributeNotFound:
            return "0x000A The attribute wasn’t found within the specified attribute handle range"
        case .attributeNotLong:
            return "0x000B The ATT read blob request can’t read or write the attribute"
        case .insufficientEncryptionKeySize:
            return "0x000C The encryption key size used for encryption is insufficient"
        case .invalidAttributeValueLength:
            return "0x000D The length of the attribute’s value is invalid"
        case .unlikelyError:
            return "0x000E The ATT request encountered an unlikely error"
        case .insufficientEncryption:
            return "0x000F Failed for lack of encryption"
        case .unsupportedGroupType:
            return "0x0010 The attribute type isn’t a supported grouping attribute"
        case .insufficientResources:
            return "0x0011 Resources are insufficient to complete the ATT request"
        @unknown default:
            return "Unspecified error"
        }
    }
        
    @objc
    init(peripheralName: String, errorCode: Int) {
        self.peripheralName = peripheralName
        self.errorCode = errorCode
    }
 
    func getErrorMessageForToast() -> String {
        return "Failed action on \(peripheralName)\nReason: \(errorDescription)"
    }
}
