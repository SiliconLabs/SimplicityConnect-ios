//
//  SILESLCommandPing.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 10.5.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

class SILESLCommandPing: SILESLCommand {
    let name = "ping"
    let opcode: UInt8 = 8
    
    private let eslId: SILESLIdAddress
    
    init(eslId: SILESLIdAddress) {
        self.eslId = eslId
    }
    
    func getFullCommand() -> String {
        var command = name
        command.append(" ")
        command.append(eslId.rawValue)
        
        return command
    }
}

class SILESLCommandPingRunner: NSObject, SILESLCommandRunner, CBPeripheralDelegate {
    typealias T = SILESLBasicStateResponse
    typealias W = SILESLCommandGenericError
    typealias S = SILESLCommandPing
    
    var commandResult: PublishRelay<Result<SILESLBasicStateResponse, SILESLCommandGenericError>> = PublishRelay()
    private let command: SILESLCommandPing
    private let peripheral: CBPeripheral
    private let peripheralReferences: SILESLPeripheralGATTReferences
    private var timer: Timer?
    private let BasicStateResponseOpcode = 16
    private let MessageLength = 7
    
    init(peripheral: CBPeripheral,
         peripheralReferences: SILESLPeripheralGATTReferences,
         command: SILESLCommandPing) {
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
                debugPrint("ESL Command Ping: Timeout")
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
        
        debugPrint("ESL Command Ping: Did write value for characteristic")
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
        
        debugPrint("ESL Command Ping: Did update value \(value) for characteristic")
        
        guard value[0] == command.opcode else {
            return
        }
        
        guard value[1] == 0 else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }
        
        guard value[4] == BasicStateResponseOpcode else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }
        
        guard value.count == MessageLength else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }
        
        let responseBytes = Array(value[5...6])
        let decodedResponse = decodeResponse(responseBytes)
        commandResult.accept(.success(decodedResponse))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == peripheralReferences.eslControlPoint else {
            return
        }
        
        guard error == nil else {
            commandResult.accept(.failure(.errorFromCharacteristic(error: error!)))
            return
        }
        
        debugPrint("ESL Command Ping: Did update notification state \(characteristic.isNotifying) for characteristic")
        
        if !characteristic.isNotifying {
            commandResult.accept(.failure(.characteristicIsntNotifying))
        }
    }

    private func decodeResponse(_ value: [UInt8]) -> SILESLBasicStateResponse {
        return SILESLBasicStateResponse(bits: value[0], activeLed: value[1])
    }
}
