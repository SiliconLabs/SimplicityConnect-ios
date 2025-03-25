//
//  SILESLImageUpdate.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 12.4.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreBluetooth

class SILESLImageUpdate: NSObject, SILESLCommandRunner {
    typealias T = SILESLDemoViewModelState
    typealias W = SILESLCommandGenericError
    typealias S = SILESLCommandCompound
    
    private let peripheral: CBPeripheral
    private var peripheralReferences: SILESLPeripheralGATTReferences
    private let commandRunnerFactory: SILESLCommandRunnerFactory
    private let address: SILESLIdAddress
    private let imageIndex: UInt
    private let imageFile: URL
    private let showImageAfterUpdate: Bool
    private var timeout: TimeInterval! = 0.0
    private var currentRunningCommand: (any SILESLCommandRunner)?
    var commandResult: PublishRelay<Result<SILESLDemoViewModelState, SILESLCommandGenericError>> = PublishRelay()
    private var disposeBag = DisposeBag()
    
    init(peripheral: CBPeripheral,
         peripheralReferences: SILESLPeripheralGATTReferences,
         commandRunnerFactory: SILESLCommandRunnerFactory,
         address: SILESLIdAddress,
         imageIndex: UInt,
         imageFile: URL,
         showImageAfterUpdate: Bool = false) {
        self.peripheral = peripheral
        self.peripheralReferences = peripheralReferences
        self.commandRunnerFactory = commandRunnerFactory
        self.address = address
        self.imageIndex = imageIndex
        self.imageFile = imageFile
        self.showImageAfterUpdate = showImageAfterUpdate
        super.init()
    }
    
    func perform(timeout: TimeInterval) {
        let connect = commandRunnerFactory.createCommandConnectRunner(peripheral: peripheral,
                                                                      peripheralReferences: peripheralReferences,
                                                                      address: .eslId(address))
        currentRunningCommand = connect
        self.timeout = timeout
        connect.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success:
                self.imageUpdate()
                
            case .failure(let error):
                self.commandResult.accept(.failure(error))
                
            }
        }).disposed(by: disposeBag)
        self.commandResult.accept(.success(.starting))
        connect.perform(timeout: timeout)
    }
        
    private func imageUpdate() {
        let imageUpdate = commandRunnerFactory.createCommandImageUpdateRunner(peripheral: peripheral,
                                                                              peripheralReferences: peripheralReferences,
                                                                              imageIndex: imageIndex,
                                                                              imageFile: imageFile)
        currentRunningCommand = imageUpdate
        
        imageUpdate.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            let imageUpdateCommand = self.currentRunningCommand as? SILESLCommandImageUpdateRunner
            self.clearAfterCommand()
            
            switch result {
            case .success:
                if let imageUpdateCommand = imageUpdateCommand {
                    let requestData = imageUpdateCommand.getRequestData()
                    self.commandResult.accept(.success(.processInProgressDisplayImage(address: self.address, imageIndex: Int(requestData.imageIndex), imageFile: requestData.imageFile)))
 
                    if self.showImageAfterUpdate {
                        self.displayImage(address: self.address, imageIndex: requestData.imageIndex, displayIndex: 0)
                    } else {
                        self.disconnectConnectedTag()
                    }
                }

            case .failure(let error):
                self.disconnectConnectedTag(after: "Image Update", with: error)
                
            }
        }).disposed(by: disposeBag)
        
        imageUpdate.updateProgress.asObservable().subscribe(onNext: { [weak self] progress in
            guard let self = self else { return }
            self.commandResult.accept(.success(.imageUpdateProgress(progress: progress)))
        }).disposed(by: disposeBag)
        
        self.commandResult.accept(.success(.starting))
        imageUpdate.perform(timeout: timeout)
    }
        
    private func disconnectConnectedTag(after command: String? = nil,
                                        with error: SILESLCommandGenericError? = nil) {
        let disconnect = commandRunnerFactory.createCommandDisconnectRunner(peripheral: peripheral,
                                                                            peripheralReferences: peripheralReferences)
        
        currentRunningCommand = disconnect
        disconnect.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success:
                if let _ = command, let error = error {
                    self.commandResult.accept(.failure(error))
                } else {
                    self.commandResult.accept(.success(.completed))
                }
                
            case .failure(let error):
                self.commandResult.accept(.failure(error))
                
            }
        }).disposed(by: disposeBag)
        self.commandResult.accept(.success(.starting))
        disconnect.perform(timeout: timeout)
    }
    
    private func displayImage(address: SILESLIdAddress,
                              imageIndex: UInt,
                              displayIndex: UInt) {
        let displayImage = commandRunnerFactory.createCommandDisplayImageRunner(peripheral: peripheral,
                                                                                peripheralReferences: peripheralReferences,
                                                                                eslId: address,
                                                                                imageIndex: imageIndex,
                                                                                displayIndex: displayIndex)
        currentRunningCommand = displayImage
        displayImage.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success:
                self.disconnectConnectedTag()
                
            case .failure(let error):
                self.disconnectConnectedTag(after: "Display Image", with: error)
                
            }
        }).disposed(by: disposeBag)
        self.commandResult.accept(.success(.starting))
        displayImage.perform(timeout: timeout)
    }
    
    private func clearAfterCommand() {
        self.disposeBag = DisposeBag()
       self.currentRunningCommand = nil
    }
    
    // Write 0x01 for cancel uploading image
    func cancelUploadingImage() -> Bool {
        let dataToSend = Data(repeating: 0x01, count: 1)
        debugPrint("ESL Command Image Update: Chunk data \(dataToSend.bytes) Image Update Cancled")
        peripheral.writeValue(dataToSend, for: self.peripheralReferences.eslTransferImage!, type: .withResponse)
        return true
    }
}

