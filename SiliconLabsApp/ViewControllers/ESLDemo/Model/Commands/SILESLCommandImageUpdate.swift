//
//  SILESLCommandImageUpdate.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift
import RxCocoa

class SILESLCommandImageUpdate: SILESLCommand {
    let name = "image_update"
    let opcode: UInt8 = 3
    
    let imageIndex: UInt
    let imageFile: URL
    var imageFileData: Data? {
        get {
            return try? Data(contentsOf: imageFile)
        }
    }
    private let imageName = "a"
    
    init(imageIndex: UInt, imageFile: URL) {
        self.imageIndex = imageIndex
        self.imageFile = imageFile
    }
    
    func getFullCommand() -> String {
        var command = name
        command.append(" ")
        command.append("\(imageIndex)")
        command.append(" ")
        command.append(imageName)
        command.append(getImageFileExtension())
        
        return command
    }
    
    private func getImageFileExtension() -> String {
        return ".\(imageFile.pathExtension)"
    }
}

class SILESLCommandImageUpdateRunner: NSObject, SILESLCommandRunner, CBPeripheralDelegate {
    typealias T = Bool
    typealias W = SILESLCommandGenericError
    typealias S = SILESLCommandImageUpdate
    
    var updateProgress: PublishRelay<String> = PublishRelay()
    var commandResult: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
    private let command: SILESLCommandImageUpdate
    private let peripheral: CBPeripheral
    private let peripheralReferences: SILESLPeripheralGATTReferences
    private var timer: Timer?
    
    private let firstByteInChunk = (usual: UInt8(0), last: UInt8(1))
    private let efrMaxChunkSize = 182
    private lazy var chunkSize: Int = min(self.peripheral.maximumWriteValueLength(for: .withResponse) - 1, efrMaxChunkSize - 1)
    private lazy var fileContent = self.command.imageFileData
    private var timeout: TimeInterval = 0.0
    
    init(peripheral: CBPeripheral,
         peripheralReferences: SILESLPeripheralGATTReferences,
         command: SILESLCommandImageUpdate) {
        self.peripheral = peripheral
        self.peripheralReferences = peripheralReferences
        self.command = command
        super.init()
        self.peripheral.delegate = self
    }
    
    func getRequestData() -> (imageIndex: UInt, imageFile: URL) {
        return (imageIndex: command.imageIndex, imageFile: command.imageFile)
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
        
        guard let _ = self.command.imageFileData else {
            commandResult.accept(.failure(.unknown))
            return
        }
        
        self.timeout = timeout
        self.installTimer()
        self.peripheral.writeValue(Data(bytes: command.dataToSend), for: eslControlPoint, type: .withResponse)
    }
    
    private func installTimer() {
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: self.timeout,
                                         repeats: false) { [weak self] _ in
                guard let self = self else { return }
                debugPrint("ESL Command Image Update: Timeout")
                self.timer?.invalidate()
                self.timer = nil
                self.peripheral.delegate = nil
                self.commandResult.accept(.failure(.timeout))
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == peripheralReferences.eslControlPoint else {
            return
        }
        
        guard error == nil else {
            commandResult.accept(.failure(.errorFromCharacteristic(error: error!)))
            return
        }
        
        debugPrint("ESL Command Image Update: Did write value for characteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.timer?.invalidate()
        self.timer = nil
        
        guard characteristic == peripheralReferences.eslControlPoint || characteristic == peripheralReferences.eslTransferImage else {
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
        
        debugPrint("ESL Command Image Update: Did update value \(value) for characteristic")
        
        if characteristic == peripheralReferences.eslControlPoint {
            processCommandResult(bytes: value)
        } else {
            processResponseDuringUpdate(bytes: value)
        }
    }
    
    private func processCommandResult(bytes: [UInt8]) {
        guard bytes[0] == command.opcode else {
            return
        }
        
        guard bytes[1] == 0 else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }

        commandResult.accept(.success(true))
    }
    
    private func processResponseDuringUpdate(bytes: [UInt8]) {
        let headerLength = 1
        let offsetLength = 4
        let reservedDataLength = 1
        let headerFirstByte = 239
  
        guard bytes.count == headerLength + offsetLength + reservedDataLength else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }
        
        guard Int(bytes[0]) == headerFirstByte else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }
            
        let bytesStartingOffset = bytes.dropFirst(headerLength)
        let offsetBytes = bytesStartingOffset[1..<(1 + offsetLength)]
        let offsetValue = offsetBytes.reversed().reduce(0) { $0 << 8 + Int($1) }
        
        sendNextChunk(offset: offsetValue)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == peripheralReferences.eslControlPoint || characteristic == peripheralReferences.eslTransferImage else {
            return
        }
        
        guard error == nil else {
            commandResult.accept(.failure(.errorFromCharacteristic(error: error!)))
            return
        }
        
        debugPrint("ESL Command Image Update: Did update notification state \(characteristic.uuid) to value \(characteristic.isNotifying)")
        
        if !characteristic.isNotifying {
            commandResult.accept(.failure(.characteristicIsntNotifying))
        }
    }
    
    private func sendNextChunk(offset: Int) {
        guard let imageFileData = self.fileContent else { return }
        let progressInPercent = String(format: "%.1f", (Double(offset) / Double(imageFileData.count) * 100))
        updateProgress.accept("\(progressInPercent)%")
        
        let amountOfDataToSend = imageFileData.count - offset
        guard amountOfDataToSend >= 0 else {
            commandResult.accept(.failure(.errorFromAccessPoint))
            return
        }
        let isLastChunk = amountOfDataToSend <= chunkSize
        let takeAmountOfBytes: Int! = amountOfDataToSend <= chunkSize ? amountOfDataToSend : chunkSize
        var dataToSend = Data(repeating: 0, count: 1)
        dataToSend[0] = isLastChunk ? firstByteInChunk.last : firstByteInChunk.usual
        let chunkData = imageFileData[offset..<(offset + takeAmountOfBytes)].bytes
        dataToSend.append(chunkData, count: takeAmountOfBytes)
        
        debugPrint("ESL Command Image Update: Chunk data \(dataToSend.bytes)")
        
        self.installTimer()
        peripheral.writeValue(dataToSend, for: self.peripheralReferences.eslTransferImage!, type: .withResponse)
    }
}
