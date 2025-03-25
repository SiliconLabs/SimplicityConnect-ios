//
//  SILESLProvisioningTag.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 12.4.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreBluetooth

class SILESLProvisioningTag: NSObject, SILESLCommandRunner {
    typealias T = SILESLDemoViewModelState
    typealias W = SILESLCommandGenericError
    typealias S = SILESLCommandCompound
    
    private let peripheral: CBPeripheral
    private var peripheralReferences: SILESLPeripheralGATTReferences
    private let commandRunnerFactory: SILESLCommandRunnerFactory
    private let qrData: [UInt8]
    private var timeout: TimeInterval! = 0.0
    private var currentRunningCommand: (any SILESLCommandRunner)?
    var commandResult: PublishRelay<Result<SILESLDemoViewModelState, SILESLCommandGenericError>> = PublishRelay()
    private var disposeBag = DisposeBag()    
    var eslAddress: SILESLIdAddress?
    private var imageIndex: UInt?
    
    init(peripheral: CBPeripheral,
         peripheralReferences: SILESLPeripheralGATTReferences,
         commandRunnerFactory: SILESLCommandRunnerFactory,
         qrData: [UInt8]) {
        self.peripheral = peripheral
        self.peripheralReferences = peripheralReferences
        self.commandRunnerFactory = commandRunnerFactory
        self.qrData = qrData
        super.init()
    }
    
    func perform(timeout: TimeInterval) {
        let connect = commandRunnerFactory.createCommandConnectRunner(peripheral: peripheral,
                                                                      peripheralReferences: peripheralReferences,
                                                                      qrData: qrData)
        currentRunningCommand = connect
        self.timeout = timeout
        connect.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success:
                self.commandResult.accept(.success(.provisioningInProgressConfig))
                
            case .failure(let error):
                self.commandResult.accept(.failure(error))
                
            }
        }).disposed(by: disposeBag)
        self.commandResult.accept(.success(.starting))
        connect.perform(timeout: timeout)
    }
    
    func configureConnectedTag() {
        let configure = commandRunnerFactory.createCommandConfigureRunner(peripheral: peripheral,
                                                                          peripheralReferences: peripheralReferences)
        currentRunningCommand = configure
        configure.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success(let tag):
                self.commandResult.accept(.success(.provisioningInProgressImageUpdate(tag: tag)))
                
            case .failure(let error):
                self.disconnectConnectedTag(after: "Configure", with: error)
                
            }
        }).disposed(by: disposeBag)
        self.commandResult.accept(.success(.starting))
        configure.perform(timeout: timeout)
    }
    
    func imageUpdate(address: SILESLIdAddress,
                     imageIndex: UInt,
                     imageFile: URL,
                     showImageAfterUpdate: Bool = false) {
        let imageUpdate = commandRunnerFactory.createCommandImageUpdateRunner(peripheral: peripheral,
                                                                              peripheralReferences: peripheralReferences,
                                                                              imageIndex: imageIndex,
                                                                              imageFile: imageFile)
        currentRunningCommand = imageUpdate
        self.eslAddress = address
        
        imageUpdate.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            let imageUpdateCommand = self.currentRunningCommand as? SILESLCommandImageUpdateRunner
            self.clearAfterCommand()
            
            switch result {
            case .success:
                if let imageUpdateCommand = imageUpdateCommand {
                    let requestData = imageUpdateCommand.getRequestData()
                    self.imageIndex = requestData.imageIndex
                    self.commandResult.accept(.success(.processInProgressDisplayImage(address: address, imageIndex: Int(requestData.imageIndex), imageFile: requestData.imageFile)))
                    self.disconnectConnectedTag(showImageAfterUpdate: showImageAfterUpdate)
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
        
    func disconnectConnectedTag(showImageAfterUpdate: Bool = false,
                                after command: String? = nil,
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
                    if showImageAfterUpdate {
                        if let eslAddress = self.eslAddress, let imageIndex = self.imageIndex {
                            self.displayImage(address: eslAddress, imageIndex: imageIndex, displayIndex: 0)
                        }
                    } else {
                        self.commandResult.accept(.success(.completed))
                    }
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
                self.commandResult.accept(.success(.completed))
                
            case .failure(let error):
                self.commandResult.accept(.failure(error))
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
    func cancelUploading() -> Bool {
        let dataToSend = Data(repeating: 0x01, count: 1)
        debugPrint("ESL Command Image Update: Chunk data \(dataToSend.bytes) Image Update CANCLED !!!")
        peripheral.writeValue(dataToSend, for: self.peripheralReferences.eslTransferImage!, type: .withResponse)
        return true
    }
}
