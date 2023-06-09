//
//  SILESLCommandDisplayImage.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

enum SILESLDisplayImageError: Error, LocalizedError {
    case rfu
    case unspecifiedError
    case invalidOpcode
    case invalidState
    case invalidImageIndex
    case imageNotAvailable
    case invalidParameter
    case capacityLimit
    case insufficientBattery
    case insufficientResources
    case retry
    case quequeFull
    
    init?(rawValue: String) {
        if rawValue == "0" {
            self = .rfu
            return
        }
        else if rawValue == "1" {
            self = .unspecifiedError
            return
        }
        else if rawValue == "2" {
            self = .invalidOpcode
            return
        }
        else if rawValue == "3" {
            self = .invalidState
            return
        }
        else if rawValue == "4" {
            self = .invalidImageIndex
            return
        }
        else if rawValue == "5" {
            self = .imageNotAvailable
            return
        }
        else if rawValue == "6" {
            self = .invalidParameter
            return
        }
        else if rawValue == "7" {
            self = .capacityLimit
            return
        }
        else if rawValue == "8" {
            self = .insufficientBattery
            return
        }
        else if rawValue == "9" {
            self = .insufficientResources
            return
        }
        else if rawValue == "10" {
            self = .retry
            return
        }
        else if rawValue == "11" {
            self = .quequeFull
            return
        }
        return nil
    }
    
    public var errorDescription: String?{
        switch self {
        case .rfu:
            return "Reserved for Future Use."
        case .unspecifiedError:
            return "Any error condition that is not covered by a specific error code below."
        case .invalidOpcode:
            return "The opcode was not recognised."
        case .invalidState:
            return "The request was not valid for the present ESL state."
        case .invalidImageIndex:
            return "The Image_Index value was out of range."
        case .imageNotAvailable:
            return "The request image contained no image data."
        case .invalidParameter:
            return "The parameter value(s) or length did not match the opcode."
        case .capacityLimit:
            return "The required response could not be sent as it would exceed the payload size limit."
        case .insufficientBattery:
            return "The request could not be processed because of a lack of battery charge."
        case .insufficientResources:
            return "The request could not be processed because of a lack of resources. This may be a temporary condition."
        case .retry:
            return "The ESL is temporarily unable to give a  full response (e.g., because he required sensor hardware was asleep."
        case .quequeFull:
            return "The ESL is temporarily unable to add a further timed command to the queue of pendings commands - the queue has reached its limit."
        }
    }
}

class SILESLCommandDisplayImage: SILESLCommand {
    let name = "display_image"
    let opcode: UInt8 = 5
    
    private let eslId: SILESLIdAddress
    private let imageIndex: UInt
    private let displayIndex: UInt
    private var timer: Timer?
    
    init(eslId: SILESLIdAddress, imageIndex: UInt, displayIndex: UInt) {
        self.eslId = eslId
        self.imageIndex = imageIndex
        self.displayIndex = displayIndex
    }
    
    func getFullCommand() -> String {
        var command = name
        command.append(" ")
        command.append(eslId.rawValue)
        command.append(" ")
        command.append("\(imageIndex)")
        command.append(" ")
        command.append("\(displayIndex)")
        
        return command
    }
}

class SILESLCommandDisplayImageRunner: NSObject, SILESLCommandRunner, CBPeripheralDelegate {
    typealias T = Bool
    typealias W = SILESLCommandGenericError
    typealias S = SILESLCommandDisplayImage
    
    var commandResult: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
    private let command: SILESLCommandDisplayImage
    private let peripheral: CBPeripheral
    private let peripheralReferences: SILESLPeripheralGATTReferences
    private var timer: Timer?
    
    init(peripheral: CBPeripheral,
         peripheralReferences: SILESLPeripheralGATTReferences,
         command: SILESLCommandDisplayImage) {
        self.peripheral = peripheral
        self.peripheralReferences = peripheralReferences
        self.command = command
        super.init()
        self.peripheral.delegate = self
    }
    
    func perform(timeout: TimeInterval) {
        guard let eslControlPoint = peripheralReferences.eslControlPoint else {
            commandResult.accept(.failure(.missingCharacteristic))
            return
        }
        
        guard eslControlPoint.isNotifying else {
            commandResult.accept(.failure(.characteristicIsntNotifying))
            return
        }
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: timeout,
                                         repeats: false) { [weak self] _ in
                guard let self = self else { return }
                debugPrint("ESL Command Display Image: Timeout")
                self.timer?.invalidate()
                self.timer = nil
                self.peripheral.delegate = nil
                self.commandResult.accept(.failure(.timeout))
            }
        }
        
        self.peripheral.writeValue(Data(bytes: command.dataToSend), for: eslControlPoint, type: .withResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == peripheralReferences.eslControlPoint else {
            return
        }
        
        guard error == nil else {
            commandResult.accept(.failure(.errorFromCharacteristic(error: error!)))
            return
        }
        
        debugPrint("ESL Command Display Image: Did write value for characteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == peripheralReferences.eslControlPoint else {
            return
        }
        
        guard error == nil else {
            commandResult.accept(.failure(.errorFromCharacteristic(error: error!)))
            return
        }
    
        guard let value = characteristic.value?.bytes else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }
        
        debugPrint("ESL Command Display Image: Did update value \(value) for characteristic")
        
        guard value[0] == command.opcode else {
            return
        }
        
        guard value[1] == 0 else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }
        
        // group message response
        guard value[2] != 255 else {
            commandResult.accept(.success(true))
            return
        }
      
        guard value[4] != 0 else {
            if let error = SILESLDisplayImageError(rawValue: String(value[5])) {
                commandResult.accept(.failure(.tagResponseError(error: error)))
            }
            return
        }
        commandResult.accept(.success(true))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == peripheralReferences.eslControlPoint else {
            return
        }
        
        guard error == nil else {
            commandResult.accept(.failure(.errorFromCharacteristic(error: error!)))
            return
        }
        
        debugPrint("ESL Command Display Image: Did update notification state \(characteristic.isNotifying) for characteristic")
        
        if !characteristic.isNotifying {
            commandResult.accept(.failure(.characteristicIsntNotifying))
        }
    }
}
