//
//  SILAttErrorModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 01/06/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

class SILAttErrorModel : NSObject {
    private let errorCode: Int
    
    struct Error {
        let code: String
        let name: String
        let description: String
    }
    
    var errorDetails: Error {
        guard let CBATTErrorCode = CBATTError.Code(rawValue: errorCode) else {
            return Error(code: "0x00",
                         name: "UNKNOWN ERROR",
                         description: "No description.")
            }
        switch CBATTErrorCode {
        case .success:
            return Error(code: "0x00",
                         name: "SUCCESS",
                         description: "The ATT command or request successfully completed")
        case .invalidHandle:
            return Error(code: "0x01",
                         name: "INVALID HANDLE",
                         description: "The attribute handle given was not valid on this server.")
        case .readNotPermitted:
            return Error(code: "0x02",
                         name: "READ NOT PERMITTED",
                         description: "The attribute cannot be read.")
        case .writeNotPermitted:
            return Error(code: "0x03",
                         name: "WRITE NOT PERMITTED",
                         description: "The attribute cannot be written.")
        case .invalidPdu:
            return Error(code: "0x04",
                         name: "INVALID PDU",
                         description: "The attribute PDU was invalid.")
        case .insufficientAuthentication:
            return Error(code: "0x05",
                         name: "INSUFFICIENT AUTHENTICATION",
                         description: "The attribute requires authentication before it can be read or written.")
        case .requestNotSupported:
            return Error(code: "0x06",
                         name: "REQUEST NOT SUPPORTED",
                         description: "Attribute server does not support the request received from the client.")
        case .invalidOffset:
            return Error(code: "0x07",
                         name: "INVALID OFFSET",
                         description: "Offset specified was past the end of the attribute.")
        case .insufficientAuthorization:
            return Error(code: "0x08",
                         name: "INSUFFICIENT AUTHORIZATION",
                         description: "The attribute requires authorization before it can be read or written.")
        case .prepareQueueFull:
            return Error(code: "0x09",
                         name: "PREPARE QUEUE FULL",
                         description: "Too many prepare writes have been queued.")
        case .attributeNotFound:
            return Error(code: "0x0A",
                         name: "ATTRIBUTE NOT FOUND",
                         description: "No attribute found within the given attribute handle range.")
        case .attributeNotLong:
            return Error(code: "0x0B",
                         name: "ATTRIBUTE NOT LONG",
                         description: "The attribute cannot be read using the ATT_READ_BLOB_REQ PDU.")
        case .insufficientEncryptionKeySize:
            return Error(code: "0x0C",
                         name: "INSUFFICIENT ENCRYPTION KEY SIZE",
                         description: "The Encryption Key Size used for encrypting this link is insufficient.")
        case .invalidAttributeValueLength:
            return Error(code: "0x0D",
                         name: "INVALID ATTRIBUTE VALUE LENGTH",
                         description: "The attribute value length is invalid for the operation.")
        case .unlikelyError:
            return Error(code: "0x0E",
                         name: "UNLIKELY ERROR",
                         description: "The attribute request that was requested has encountered an error that was unlikely, and therefore could not be completed as requested.")
        case .insufficientEncryption:
            return Error(code: "0x0F",
                         name: "INSUFFICIENT ENCRYPTION",
                         description: "The attribute requires encryption before it can be read or written.")
        case .unsupportedGroupType:
            return Error(code: "0x10",
                         name: "UNSUPPORTED GROUP TYPE",
                         description: "The attribute type is not a supported grouping attribute as defined by a higher layer specification.")
        case .insufficientResources:
            return Error(code: "0x11",
                         name: "INSUFFICIENT RESOURCES",
                         description: "Insufficient Resources to complete the request.")
        @unknown default:
            if 0x80...0x87 ~= self.errorCode {
                return decodeOTAError()
            } else {
                return Error(code: "0x00",
                             name: "UNKNOWN ERROR",
                             description: "No description.")
            }
        }
    }
    
    private func decodeOTAError() -> Error {
        switch self.errorCode {
        case 0x80:
            return Error(code: "0x80",
                         name: "GATT_NO_RESOURCES",
                         description: "CRC check failed, or signature failure (if enabled).")
        case 0x81:
            return Error(code: "0x81",
                         name: "GATT_INTERNAL_ERROR",
                         description: "This error is returned if the OTA has not been started (by writing value 0x0 to the control endpoint) and the client tries to send data or terminate the update.")
        case 0x82:
            return Error(code: "0x82",
                         name: "GATT_WRONG_STATE",
                         description: "AppLoader has run out of buffer space.")
        case 0x83:
            return Error(code: "0x83",
                         name: "GATT_DB_FULL",
                         description: "New firmware image is too large to fit into flash, or it overlaps with AppLoader.")
        case 0x84:
            return Error(code: "0x84",
                         name: "GATT: BUSY",
                         description: """
        GBL file parsing failed. Potential causes are for example:
        1) Attempting a partial update from one SDK version to another (such as 2.3.0 to 2.4.0)
        2) The file is not a valid GBL file (for example, client is sending an EBL file)
        """)
        case 0x85:
            return Error(code: "0x85",
                         name: "GATT ERROR",
                         description: "The Gecko bootloader cannot erase or write flash as requested by AppLoader, for example if the download area is too small to fit the entire GBL image.")
        case 0x86:
            return Error(code: "0x86",
                         name: "GATT CMD STARTED",
                         description: "Wrong type of bootloader. For example, target device has UART DFU bootloader instead of OTA bootloader installed.")
        case 0x87:
            return Error(code: "0x87",
                         name: "GATT ILLEGAL PARAMETER",
                         description: "New application image is rejected because it would overlap with the AppLoader.")
        default:
            return Error(code: "0x00",
                         name: "UNKNOWN ERROR",
                         description: "No description.")
        }
    }
            
    @objc init(errorCode: Int) {
        self.errorCode = errorCode
    }
}
