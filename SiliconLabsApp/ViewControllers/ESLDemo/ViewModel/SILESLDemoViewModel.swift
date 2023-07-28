//
//  SILESLDemoViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 2.2.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreBluetooth

enum SILESLDemoViewModelState: Equatable, SILESLResponseData {
    case starting
    case provisioningInProgressConfig
    case provisioningInProgressImageUpdate(tag: SILESLTag)
    case processInProgressDisplayImage(address: SILESLIdAddress, imageIndex: Int, imageFile: URL)
    case finishedWithError(commandName: String, error: SILESLCommandGenericError)
    case imageUpdateProgress(progress: String)
    case completed
    case completedWithPopup(text: String)
}

class SILESLDemoViewModel {
    private let centralManager: SILCentralManager
    private var peripheralDelegate: SILESLPeripheralDelegate?
    private let notificationCenter: NotificationCenter
    private let peripheral: CBPeripheral
    private var peripheralReferences: SILESLPeripheralGATTReferences!
    private let commandRunnerFactory: SILESLCommandRunnerFactory
    private var currentRunningCommand: (any SILESLCommandRunner)?
    private var disposeBag = DisposeBag()
    var areGroupLedsOn = false
    let shouldLeaveViewController: PublishRelay<Bool> = PublishRelay()
    let shouldShowPopupWithError: PublishRelay<SILESLPeripheralDelegateError?> = PublishRelay()
    let commandState: PublishRelay<SILESLDemoViewModelState> = PublishRelay()
    var tagViewModels: [SILESLDemoTagViewModel] = []
    private var tags: [SILESLTag] = []
    
    init(centralManager: SILCentralManager,
         peripheralDelegate: SILESLPeripheralDelegate,
         commandRunnerFactory: SILESLCommandRunnerFactory = SILESLCommandRunnerFactory(),
         notificationCenter: NotificationCenter = .default) {
        self.centralManager = centralManager
        self.peripheralDelegate = peripheralDelegate
        self.peripheral = self.peripheralDelegate!.peripheral
        self.peripheralReferences = self.peripheralDelegate!.peripheralReferences
        self.commandRunnerFactory = commandRunnerFactory
        self.notificationCenter = notificationCenter
    }
    
    func viewWillAppear() {
        subscribeForCentralManagerNotifications()
        subscribeToPeripheralDelegate()
        peripheralDelegate?.discoverGATTDatabase()
    }
    
    func viewWillDisappear() {
        unsubscribeFromCentralManagerNotifications()
        centralManager.disconnectConnectedPeripheral()
    }
    
    //MARK: Provisioning
    func provisionTag(with qrData: [UInt8]) {
        let provisioningTag = commandRunnerFactory.createCommandProvisioning(peripheral: peripheral,
                                                                             peripheralReferences: peripheralReferences,
                                                                             commandRunnerFactory: commandRunnerFactory,
                                                                             qrData: qrData)
        currentRunningCommand = provisioningTag
        
        provisioningTag.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let state):
                self.processUpdate(state: state)
                self.commandState.accept(state)
                
            case .failure(let error):
                self.clearAfterCommand()
                self.commandState.accept(.finishedWithError(commandName: "Provisioning", error: error))
            }
        }).disposed(by: disposeBag)
        provisioningTag.perform(timeout: 10.0)
    }
    
    func tagWithAddressIsProvisioned(_ address: SILBluetoothAddress) -> Bool {
        return tags.contains(where: { tag in tag.btAddress == address })
    }
    
    private func processUpdate(state: SILESLDemoViewModelState) {
        switch state {
        case .provisioningInProgressImageUpdate(tag: let tag):
            self.appendProvisionedTag(tag)
            
        case .processInProgressDisplayImage(address: let address, imageIndex: let imageIndex, imageFile: let imageFile):
            self.updateTagViewModels(address: address, imageIndex: imageIndex, imageFile: imageFile)
            
        case .completed:
            self.clearAfterCommand()
            
        default:
            break
        }
    }
    
    func configureConnectedTag() {
        if let provisioningTag = self.currentRunningCommand as? SILESLProvisioningTag {
            provisioningTag.configureConnectedTag()
        }
    }
    
    func imageUpdateAtProvisioning(address: SILESLIdAddress, imageIndex: UInt, imageFile: URL, showImageAfterUpdate: Bool) {
        if let provisioningTag = self.currentRunningCommand as? SILESLProvisioningTag {
            provisioningTag.imageUpdate(address: address, imageIndex: imageIndex, imageFile: imageFile, showImageAfterUpdate: showImageAfterUpdate)
        }
    }
    
    func disconnectConnectedTag() {
        if let provisioningTag = self.currentRunningCommand as? SILESLProvisioningTag {
            provisioningTag.disconnectConnectedTag()
        }
    }
    
    //MARK: Commands
    func listTags() {
        let list = commandRunnerFactory.createCommandListRunner(peripheral: peripheral,
                                                                peripheralReferences: peripheralReferences)
        currentRunningCommand = list
        
        list.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success(let tags):
                self.updateTags(tags)
                self.buildTagViewModels()
                self.commandState.accept(.completed)
                
            case .failure(let error):
                self.commandState.accept(.finishedWithError(commandName: "List", error: error))
            }
        }).disposed(by: disposeBag)
        self.commandState.accept(.starting)
        list.perform(timeout: 10.0)
    }
    
    func imageUpdate(address: SILESLIdAddress, imageIndex: UInt, imageFile: URL, showImageAfterUpdate: Bool = false) {
        let imageUpdateProcess = commandRunnerFactory.createCommandImageUpdate(peripheral: peripheral,
                                                                               peripheralReferences: peripheralReferences,
                                                                               commandRunnerFactory: commandRunnerFactory,
                                                                               address: address,
                                                                               imageIndex: imageIndex,
                                                                               imageFile: imageFile,
                                                                               showImageAfterUpdate: showImageAfterUpdate)
        currentRunningCommand = imageUpdateProcess
        imageUpdateProcess.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let state):
                self.processUpdate(state: state)
                self.commandState.accept(state)
                
            case .failure(let error):
                self.clearAfterCommand()
                self.commandState.accept(.finishedWithError(commandName: "Image Update", error: error))
            }
        }).disposed(by: disposeBag)
        imageUpdateProcess.perform(timeout: 10.0)
    }
    
    func sendLed(ledState: SILESLLedState, eslId: UInt, index: UInt) {
        sendLed(ledState: ledState, address: .unicast(id: eslId), index: index)
    }
    
    func sendAllTagsLed(ledState: SILESLLedState, index: UInt) {
        sendLed(ledState: ledState, address: .broadcast, index: index)
    }
    
    private func sendLed(ledState: SILESLLedState, address: SILESLIdAddress, index: UInt) {
        let led = commandRunnerFactory.createCommandLedRunner(peripheral: peripheral,
                                                              peripheralReferences: peripheralReferences,
                                                              ledState: ledState,
                                                              address: address,
                                                              index: index)
        
        currentRunningCommand = led
        led.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            let ledCommand = self.currentRunningCommand as? SILESLCommandLedRunner
            self.clearAfterCommand()
            
            switch result {
            case .success:
                if let ledCommand = ledCommand {
                    let requestData = ledCommand.getRequestData()
                    self.updateTagViewModels(address: requestData.address, newLedState: requestData.newLedState)
                }
  
                self.commandState.accept(.completed)
                
            case .failure(let error):
                self.commandState.accept(.finishedWithError(commandName: "Led", error: error))
            }
        }).disposed(by: disposeBag)
        self.commandState.accept(.starting)
        led.perform(timeout: address == .broadcast ? 30.0 : 10.0)
    }
 
    func displayImage(eslId: UInt, imageIndex: UInt, displayIndex: UInt) {
        displayImage(address: .unicast(id: eslId), imageIndex: imageIndex, displayIndex: displayIndex)
    }
    
    func displayImageAllTags(imageIndex: UInt, displayIndex: UInt) {
        displayImage(address: .broadcast, imageIndex: imageIndex, displayIndex: displayIndex)
    }
    
    private func displayImage(address: SILESLIdAddress,
                              imageIndex: UInt,
                              displayIndex: UInt) {
        let displayImage = commandRunnerFactory.createCommandDisplayImageRunner(peripheral: peripheral,
                                                                                peripheralReferences: peripheralReferences, eslId: address,
                                                                                imageIndex: imageIndex,
                                                                                displayIndex: displayIndex)
        currentRunningCommand = displayImage
        displayImage.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success:
                self.commandState.accept(.completed)
                
            case .failure(let error):
                self.commandState.accept(.finishedWithError(commandName: "Display Image", error: error))
            }
        }).disposed(by: disposeBag)
        self.commandState.accept(.starting)
        displayImage.perform(timeout: address == .broadcast ? 30.0 : 10.0)
    }
    
    func deleteTag(address: SILESLIdAddress) {
        let delete = commandRunnerFactory.createCommandDeleteRunner(peripheral: peripheral,
                                                                    peripheralReferences: peripheralReferences,
                                                                    address: .eslId(address))
        currentRunningCommand = delete
    
        delete.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success:
                self.deleteTagViewModel(address: address)
                self.commandState.accept(.completed)
                
            case .failure(let error):
                self.commandState.accept(.finishedWithError(commandName: "Delete", error: error))
            }
        }).disposed(by: disposeBag)
        self.commandState.accept(.starting)
        delete.perform(timeout: 10.0)
    }
    
    func pingTag(address: SILESLIdAddress) {
        let ping = commandRunnerFactory.createCommandPingRunner(peripheral: peripheral,
                                                                peripheralReferences: peripheralReferences,
                                                                eslId: address)
        currentRunningCommand = ping
        
        ping.commandResult.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            self.clearAfterCommand()
            
            switch result {
            case .success(let response):
                if response.states.contains(.activeLED) {
                    self.updateTagViewModels(address: address, newLedState: .on)
                } else {
                    self.updateTagViewModels(address: address, newLedState: .off)
                }
                
                self.commandState.accept(.completedWithPopup(text: response.description))
                
            case .failure(let error):
                self.commandState.accept(.finishedWithError(commandName: "Ping", error: error))
            }
        }).disposed(by: disposeBag)
        self.commandState.accept(.starting)
        ping.perform(timeout: 10.0)
    }
                                                    
    private func clearAfterCommand() {
        self.disposeBag = DisposeBag()
        self.currentRunningCommand = nil
    }
    
    //MARK: Updating tags
    private func updateTags(_ newTags: [SILESLTag]) {
        var updatedTags = [SILESLTag]()
        
        for newTag in newTags {
            var oldTag: SILESLTag?
            
            if let index = tags.firstIndex(where: { oldTag in oldTag.btAddress == newTag.btAddress }) {
                oldTag = tags[index]
            }
            
            var tag = SILESLTag(btAddress: newTag.btAddress,
                                eslId: newTag.eslId,
                                maxImageIndex: newTag.maxImageIndex,
                                displaysNumber: newTag.displaysNumber,
                                sensors: newTag.sensors)
            if let oldTag = oldTag {
                tag.ledState = oldTag.ledState
                tag.knownImages = oldTag.knownImages
            }
            
            updatedTags.append(tag)
        }
        
        tags = updatedTags
    }
    
    func appendProvisionedTag(_ tag: SILESLTag) {
        tags.append(tag)
        let tagViewModel = createTagViewModel(for: tag)
        tagViewModels.append(tagViewModel)
    }
    
    private func buildTagViewModels() {
        tagViewModels = []
        
        for tag in tags {
            let tagViewModel = createTagViewModel(for: tag)
            tagViewModels.append(tagViewModel)
        }
    }
    
    private func createTagViewModel(for tag: SILESLTag) -> SILESLDemoTagViewModel {
        let tagViewModel = SILESLDemoTagViewModel(tag: tag,
                                                  onTapLedButton: { [weak self] ledState in
            guard let self = self else { return }
            self.sendLed(ledState: ledState, address: tag.eslId, index: 0)
        },
                                                  onTapImageUpdateButton: { [weak self] imageIndex, url, showImageAfterUpdate in
            guard let self = self else { return }
            if let url = url {
                self.imageUpdate(address: tag.eslId, imageIndex: imageIndex, imageFile: url, showImageAfterUpdate: showImageAfterUpdate)
            } else {
                self.commandState.accept(.finishedWithError(commandName: "Image Update", error: .unknown))
            }
        },
                                                  onTapDisplayImageButton: { [weak self] imageIndex in
            guard let self = self else { return }
            self.displayImage(eslId: UInt(tag.eslId.rawValue)!, imageIndex: imageIndex, displayIndex: 0)
        },
                                                  onTapDeleteButton: { [weak self] in
            guard let self = self else { return }
            self.deleteTag(address: tag.eslId)
        },
                                                  onTapPingButton: { [weak self] in
            guard let self = self else { return }
            self.pingTag(address: tag.eslId)
        })
        
        let tagMaxImageIndexViewModel = SILESLDemoTagDetailViewModel(tagDetailName: "Max Image Index", tagDetailValue: "\(tag.maxImageIndex)")
        let tagDisplaysCountViewModel = SILESLDemoTagDetailViewModel(tagDetailName: "Displays Count", tagDetailValue: "\(tag.displaysNumber)")
        tagViewModel.tagDetailViewModels.append(contentsOf: [tagMaxImageIndexViewModel, tagDisplaysCountViewModel])
        tagViewModel.isOnLed = tag.ledState == .on ? true : false
        
        if tag.sensors.count > 0 {
            var sensorsValue = ""
            var i = 0
            for sensor in tag.sensors {
                if i != 0 {
                    sensorsValue.append("\n")
                }
                
                sensorsValue.append("\(sensor.rawValue)")
                i += 1
            }

            let tagSensorsViewModel = SILESLDemoTagDetailViewModel(tagDetailName: "Sensors Present", tagDetailValue: sensorsValue)
            tagViewModel.tagDetailViewModels.append(tagSensorsViewModel)
        }
        
        return tagViewModel
    }
    
    private func updateTagViewModels(address: SILESLIdAddress, imageIndex: Int, imageFile: URL) {
        if let index = tagViewModels.firstIndex(where: { tagViewModel in tagViewModel.elsId == address }) {
            tagViewModels[index].updateImage(imageFile, at: imageIndex)
        }
    }
    
    private func updateTagViewModels(address: SILESLIdAddress, newLedState: SILESLLedState) {
        let isledOn = newLedState == .on ? true : false
        if address.rawValue == "all" {
            self.areGroupLedsOn = isledOn
            for tagViewModel in tagViewModels {
                tagViewModel.isOnLed = isledOn
            }
        } else if let index = tagViewModels.firstIndex(where: { tagViewModel in tagViewModel.elsId == address }) {
                tagViewModels[index].isOnLed = isledOn
        }
    }
    
    private func deleteTagViewModel(address: SILESLIdAddress) {
        if let index = tags.firstIndex(where: { tag in tag.eslId == address }) {
            tags.remove(at: index)
            buildTagViewModels()
        }
    }
    
    //MARK: Initialization
    private func subscribeToPeripheralDelegate() {
        peripheralDelegate?.initializationState.asObservable().subscribe(onNext: { [weak self] error in
            guard let self = self else { return }
            if error != nil {
                self.shouldShowPopupWithError.accept(error)
            } else {
                let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { [weak self] timer in
                    guard let self = self else { return }
                    timer.invalidate()
                    self.peripheralDelegate?.checkIfCharacteristicsAreNotifying()
                })
            }
        }).disposed(by: disposeBag)
        
        peripheralDelegate?.notificationState.asObservable().subscribe(onNext: { [weak self] error in
            guard let self = self else { return }
            self.shouldShowPopupWithError.accept(error)
            if error == nil {
                self.peripheralReferences = self.peripheralDelegate?.peripheralReferences
                self.peripheralDelegate = nil
            }
            self.disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
    }
    
    private func subscribeForCentralManagerNotifications() {
        self.notificationCenter.addObserver(self,
                                            selector: #selector(handleDisconnectNotification),
                                            name: .SILCentralManagerDidDisconnectPeripheral,
                                            object: nil)
        
        self.notificationCenter.addObserver(self,
                                            selector: #selector(handleBluetoothDisabledNotification),
                                            name: .SILCentralManagerBluetoothDisabled,
                                            object: nil)
    }
    
    @objc func handleDisconnectNotification() {
        debugPrint("Did disconnect peripheral")
        unsubscribeFromCentralManagerNotifications()
        shouldLeaveViewController.accept(true)
    }
    
    @objc func handleBluetoothDisabledNotification() {
        debugPrint("Did disable Bluetooth")
        unsubscribeFromCentralManagerNotifications()
        shouldLeaveViewController.accept(true)
    }
    
    private func unsubscribeFromCentralManagerNotifications() {
        self.notificationCenter.removeObserver(self)
    }
}
