//
//  SILESLCommandLed.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

enum SILESLLedState: String {
    case on
    case off
}

class SILESLCommandLed: SILESLCommand {
    let name = "led"
    let opcode: UInt8 = 6
    
    let ledState: SILESLLedState
    let address: SILESLIdAddress
    private let index: UInt

    init(ledState: SILESLLedState, address: SILESLIdAddress, index: UInt) {
        self.ledState = ledState
        self.address = address
        self.index = index
    }
    
    func getFullCommand() -> String {
        var command = name
        command.append(" ")
        command.append(ledState.rawValue)
        command.append(" ")
        command.append(address.rawValue)
        command.append(" ")
        command.append("index=\(index)")
        
        return command
    }
}

class SILESLCommandLedRunner: NSObject, SILESLCommandRunner, CBPeripheralDelegate {
    typealias T = Bool
    typealias W = SILESLCommandGenericError
    typealias S = SILESLCommandLed
    
    var commandResult: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
    private let command: SILESLCommandLed
    private let peripheral: CBPeripheral
    private let peripheralReferences: SILESLPeripheralGATTReferences
    private var timer: Timer?
    
    init(peripheral: CBPeripheral,
         peripheralReferences: SILESLPeripheralGATTReferences,
         command: SILESLCommandLed ) {
        self.peripheral = peripheral
        self.peripheralReferences = peripheralReferences
        self.command = command
        super.init()
        self.peripheral.delegate = self
    }
    
    func getRequestData() -> (address: SILESLIdAddress, newLedState: SILESLLedState) {
        return (address: command.address, newLedState: command.ledState)
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
                debugPrint("ESL Command Led: Timeout")
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
        
        debugPrint("ESL Command Led: Did write value for characteristic")
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
        
        debugPrint("ESL Command Led: Did update value \(value) for characteristic")
        
        guard value[0] == command.opcode else {
            return
        }
        
        guard value[1] == 0 else {
            commandResult.accept(.failure(.errorFromAccessPoint))
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
        
        debugPrint("ESL Command Led: Did update notification state \(characteristic.isNotifying) for characteristic")
        
        if !characteristic.isNotifying {
            commandResult.accept(.failure(.characteristicIsntNotifying))
        }
    }
}
