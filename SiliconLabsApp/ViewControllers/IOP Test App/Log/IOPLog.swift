//
//  IOPLog.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 01/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import CoreBluetooth
import Foundation
import CocoaLumberjack


class IOPLog: NSObject {
    private static var activeTestID: String?
    
    static func setActiveTestID(_ testID: String?) {
        activeTestID = testID
    }
    
    @objc func iopLogSwiftFunction(message: String) {
        emit(source: "IOP", message: message)
    }
    
    func emit(source: String, message: String) {
        let finalMessage: String
        if let activeTestID = IOPLog.activeTestID,
           !activeTestID.isEmpty,
           !message.hasPrefix("[") {
            finalMessage = "[\(activeTestID)] \(message)"
        } else {
            finalMessage = message
        }
        
        SILIOPExpertLogPublisher.publishRawLog(source: source, message: finalMessage)
        DDLogVerbose("Application: \(source): \(finalMessage)")
    }
    
    func step(source: String,
              testID: String? = nil,
              action: String,
              detail: String? = nil) {
        var message = ""
        if let testID = testID {
            message = "[\(testID)] \(action)"
        } else {
            message = action
        }
        
        if let detail = detail, !detail.isEmpty {
            message.append(" | \(detail)")
        }
        
        emit(source: source, message: message)
    }
    
    func retry(source: String,
               testID: String? = nil,
               attempt: Int,
               maxAttempts: Int,
               action: String,
               timeoutDescription: String? = nil) {
        var detail = "Attempt \(attempt) of \(maxAttempts)"
        if let timeoutDescription = timeoutDescription, !timeoutDescription.isEmpty {
            detail.append(" | timeout=\(timeoutDescription)")
        }
        step(source: source, testID: testID, action: action, detail: detail)
    }
    
    func gatt(source: String,
              testID: String? = nil,
              operation: String,
              uuid: CBUUID? = nil,
              serviceUUID: CBUUID? = nil,
              writeType: CBCharacteristicWriteType? = nil,
              expected: String? = nil,
              actual: String? = nil,
              value: String? = nil,
              outcome: String? = nil) {
        var parts: [String] = []
        if let serviceUUID = serviceUUID {
            parts.append("service=\(serviceUUID.uuidString)")
        }
        if let uuid = uuid {
            parts.append("char=\(uuid.uuidString)")
        }
        if let writeType = writeType {
            parts.append("writeType=\(writeType == .withResponse ? "withResponse" : "withoutResponse")")
        }
        if let expected = expected, !expected.isEmpty {
            parts.append("expected=\(expected)")
        }
        if let actual = actual, !actual.isEmpty {
            parts.append("actual=\(actual)")
        }
        if let value = value, !value.isEmpty {
            parts.append("value=\(value)")
        }
        if let outcome = outcome, !outcome.isEmpty {
            parts.append("result=\(outcome)")
        }
        step(source: source, testID: testID, action: operation, detail: parts.joined(separator: " | "))
    }
    
    func connection(source: String,
                    testID: String? = nil,
                    action: String,
                    peripheralName: String? = nil,
                    identifier: UUID? = nil,
                    error: Error? = nil) {
        var parts: [String] = []
        if let peripheralName = peripheralName, !peripheralName.isEmpty {
            parts.append("peripheral=\(peripheralName)")
        }
        if let identifier = identifier {
            parts.append("id=\(identifier.uuidString)")
        }
        if let error = error {
            parts.append("error=\(formattedError(error))")
        }
        step(source: source, testID: testID, action: action, detail: parts.joined(separator: " | "))
    }
    
    func formattedError(_ error: Error?) -> String {
        guard let error = error else { return "nil" }
        let nsError = error as NSError
        return "\(nsError.domain)(\(nsError.code)): \(nsError.localizedDescription)"
    }
    
    func peripheralSummary(_ peripheral: CBPeripheral?) -> String {
        guard let peripheral = peripheral else { return "peripheral=nil" }
        let name = peripheral.name ?? "Unknown"
        return "peripheral=\(name) | id=\(peripheral.identifier.uuidString) | mtu=\(peripheral.maximumWriteValueLength(for: .withResponse)) | state=\(peripheral.state.readableName)"
    }
}

private extension CBPeripheralState {
    var readableName: String {
        switch self {
        case .connected:
            return "connected"
        case .connecting:
            return "connecting"
        case .disconnected:
            return "disconnected"
        case .disconnecting:
            return "disconnecting"
        @unknown default:
            return "unknown"
        }
    }
}
