//
//  SILESLCommandConnect.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

class SILESLCommandConnect: SILESLCommand {
    let name = "connect"
    let opcode: UInt8 = 0
    
    private let address: SILAddress
    private let passcode: String?
    
    init(address: SILAddress, passcode: String? = nil) {
        self.address = address
        self.passcode = passcode
    }
    
    func getFullCommand() -> String {
        var command = name
        command.append(" ")
        command.append(address.rawValue)
        
        if case .btAddress(let address) = address, address.addressType != .public {
            command.append(" ")
            command.append(address.addressType.rawValue)
        }
        
        if let passcode = passcode {
            command.append(" ")
            command.append(passcode)
        }
        
        return command
    }
}

class SILESLCommandConnectRunner: NSObject, SILESLCommandRunner, CBPeripheralDelegate {
    typealias T = Bool
    typealias W = SILESLCommandGenericError
    typealias S = SILESLCommandConnect
    
    var commandResult: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
    private let command: SILESLCommandConnect
    private let peripheral: CBPeripheral
    private let peripheralReferences: SILESLPeripheralGATTReferences
    private var timer: Timer?
    
    init(peripheral: CBPeripheral,
         peripheralReferences: SILESLPeripheralGATTReferences,
         command: SILESLCommandConnect) {
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
                debugPrint("ESL Command Connect: Timeout")
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
        
        debugPrint("ESL Command Connect: Did write value for characteristic")
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
        
        debugPrint("ESL Command Connect: Did update value \(value) for characteristic")
        
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
        
        debugPrint("ESL Command Connect: Did update notification state \(characteristic.isNotifying) for characteristic")
        
        if !characteristic.isNotifying {
            commandResult.accept(.failure(.characteristicIsntNotifying))
        }
    }
}
