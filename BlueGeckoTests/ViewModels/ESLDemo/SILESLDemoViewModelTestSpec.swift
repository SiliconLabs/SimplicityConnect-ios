//
//  SILESLDemoViewModelTestSpec.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 2.2.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
import CoreBluetooth
import Mockingbird
import RxSwift
import RxCocoa
@testable import BlueGecko

class SILESLDemoViewModelTestSpec: QuickSpec {
    var sut: SILESLDemoViewModel!
    var centralManagerMock: SILCentralManager!
    var peripheralMock: CBPeripheral!
    var peripheralDelegateMock: SILESLPeripheralDelegateMock!
    var notificationCenterMock: NotificationCenter!
    var commandRunnerFactoryMock: SILESLCommandRunnerFactoryMock!
    var peripheralReferencesMock: SILESLPeripheralGATTReferences!
    var disposeBag = DisposeBag()
    
    override func spec() {
        beforeEach {
            self.peripheralMock = mock(CBPeripheral.self)
            self.centralManagerMock = mock(SILCentralManager.self)
            self.peripheralReferencesMock = SILESLPeripheralGATTReferences()
            self.peripheralDelegateMock = mock(SILESLPeripheralDelegate.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock)
            given(self.peripheralDelegateMock.peripheralReferences).willReturn(self.peripheralReferencesMock)
            self.notificationCenterMock = mock(NotificationCenter.self)
            self.commandRunnerFactoryMock = mock(SILESLCommandRunnerFactory.self)
            self.sut = SILESLDemoViewModel(centralManager: self.centralManagerMock,
                                           peripheralDelegate: self.peripheralDelegateMock,
                                           commandRunnerFactory: self.commandRunnerFactoryMock,
                                           notificationCenter: self.notificationCenterMock)
        }
        
        afterEach {
            self.disposeBag = DisposeBag()
        }
        
        describe("viewWillAppear") {
            it("requested action were done") {
                self.sut.viewWillAppear()
                
                verify(self.notificationCenterMock.addObserver(self.sut,
                                                               selector: #selector(self.sut.handleDisconnectNotification),
                                                               name: .SILCentralManagerDidDisconnectPeripheral,
                                                               object: nil)).wasCalled(1)
                verify(self.notificationCenterMock.addObserver(self.sut,
                                                               selector: #selector(self.sut.handleBluetoothDisabledNotification),
                                                               name: .SILCentralManagerBluetoothDisabled,
                                                               object: nil)).wasCalled(1)
                verify(self.peripheralDelegateMock.discoverGATTDatabase()).wasCalled(1)
            }
        }
        
        describe("shouldShowPopupWithError") {
            var observerWasCalled = false
            
            afterEach {
                observerWasCalled = false
            }
            
            it("event notificationState was passed") {
                self.sut.viewWillAppear()
                self.sut.shouldShowPopupWithError.asObservable().subscribe(onNext: { _ in
                    observerWasCalled = true
                }).disposed(by: self.disposeBag)
                
                self.peripheralDelegateMock.notificationState.accept(nil)
                
                expect(observerWasCalled).to(equal(true))
            }
            
            it("event initializationState was passed") {
                self.sut.viewWillAppear()
                self.sut.shouldShowPopupWithError.asObservable().subscribe(onNext: { _ in
                    observerWasCalled = true
                }).disposed(by: self.disposeBag)
                
                self.peripheralDelegateMock.initializationState.accept(.missingService)
                
                expect(observerWasCalled).to(equal(true))
            }
        }
                
        describe("viewWillDisappear") {
            it("requested action were done") {
                self.sut.viewWillDisappear()
                
                verify(self.notificationCenterMock.removeObserver(self.sut)).wasCalled(1)
                verify(self.centralManagerMock.disconnectConnectedPeripheral()).wasCalled(1)
            }
        }
        
        describe("handleDisconnectNotification") {
            var finalValue: Bool = false
            
            beforeEach {
                self.sut.shouldLeaveViewController.asObservable().subscribe(onNext: { value in
                    finalValue = value
                }).disposed(by: self.disposeBag)
            }
            
            afterEach {
                self.disposeBag = DisposeBag()
            }
            
            it("requested action were done") {
                self.sut.handleDisconnectNotification()
                
                verify(self.notificationCenterMock.removeObserver(self.sut)).wasCalled(1)
                expect(finalValue).to(equal(true))
            }
        }
        
        describe("handleBluetoothDisabledNotification") {
            var finalValue: Bool = false
            
            beforeEach {
                self.sut.shouldLeaveViewController.asObservable().subscribe(onNext: { value in
                    finalValue = value
                }).disposed(by: self.disposeBag)
            }
            
            afterEach {
                self.disposeBag = DisposeBag()
            }
            
            it("requested action were done") {
                self.sut.handleBluetoothDisabledNotification()
                
                verify(self.notificationCenterMock.removeObserver(self.sut)).wasCalled(1)
                expect(finalValue).to(equal(true))
            }
        }

        describe("provisionTag") {
            it("should call perform on runner and finish with success") {
                let provisionCommandMock = mock(SILESLProvisioningTag.self).initialize(peripheral: self.peripheralMock,
                                                                                       peripheralReferences: self.peripheralReferencesMock,
                                                                                       commandRunnerFactory: self.commandRunnerFactoryMock,
                                                                                       qrData: [UInt8]())
                
                given(self.commandRunnerFactoryMock.createCommandProvisioning(peripheral: self.peripheralMock, peripheralReferences: any(), commandRunnerFactory: self.commandRunnerFactoryMock, qrData: any())).willReturn(provisionCommandMock)
       
                let publishRelay: PublishRelay<Result<SILESLDemoViewModelState, SILESLCommandGenericError>> = PublishRelay()
                given(provisionCommandMock.commandResult).willReturn(publishRelay)
                
                var expectedState: SILESLDemoViewModelState = .completed
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    expectedState = commandState
                }).disposed(by: self.disposeBag)
                
                self.sut.provisionTag(with: [UInt8]())
                publishRelay.accept(.success(.provisioningInProgressConfig))
                
                verify(provisionCommandMock.perform(timeout: 10.0)).wasCalled(1)
                expect(expectedState == .provisioningInProgressConfig).to(beTrue())
            }
            
            it("should call perform on runner and finish with failure") {
                let provisionCommandMock = mock(SILESLProvisioningTag.self).initialize(peripheral: self.peripheralMock,
                                                                                       peripheralReferences: self.peripheralReferencesMock,
                                                                                       commandRunnerFactory: self.commandRunnerFactoryMock,
                                                                                       qrData: [UInt8]())
                
                given(self.commandRunnerFactoryMock.createCommandProvisioning(peripheral: self.peripheralMock, peripheralReferences: any(), commandRunnerFactory: self.commandRunnerFactoryMock, qrData: any())).willReturn(provisionCommandMock)
       
                let publishRelay: PublishRelay<Result<SILESLDemoViewModelState, SILESLCommandGenericError>> = PublishRelay()
                given(provisionCommandMock.commandResult).willReturn(publishRelay)
                
                var expectedState: SILESLDemoViewModelState = .completed
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    expectedState = commandState
                }).disposed(by: self.disposeBag)
                
                self.sut.provisionTag(with: [UInt8]())
                publishRelay.accept(.failure(.timeout))
                
                verify(provisionCommandMock.perform(timeout: 10.0)).wasCalled(1)
                expect(expectedState == .finishedWithError(commandName: "Provisioning", error: .timeout)).to(beTrue())
            }
        }
        
        describe("listTags") {
            it("should call perform on runner and finish with success") {
                let listCommandMock = mock(SILESLCommandList.self).initialize()
                let list = mock(SILESLCommandListRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: listCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandListRunner(peripheral: self.peripheralMock, peripheralReferences: any())).willReturn(list)
                      
                let publishRelay: PublishRelay<Result<[SILESLTag], SILESLCommandGenericError>> = PublishRelay()
                given(list.commandResult).willReturn(publishRelay)
                
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                
                self.sut.listTags()
                let btAddress = SILBluetoothAddress(address: "", addressType: .public)
                let eslTag = SILESLTag(btAddress: btAddress, eslId: .broadcast, maxImageIndex: 1, displaysNumber: 1, sensors: [.temperature])
                publishRelay.accept(.success([eslTag]))
                
                expect(self.sut.tagViewModels.count).to(equal(1))
                expect(self.sut.tagViewModels.first?.btAddress).to(equal(btAddress))
                expect(self.sut.tagViewModels.first?.elsId).to(equal(.broadcast))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.count).to(equal(3))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.first?.tagDetailName).to(equal("Max Image Index"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.first?.tagDetailValue).to(equal("1"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels[1].tagDetailName).to(equal("Displays Count"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels[1].tagDetailValue).to(equal("1"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.last?.tagDetailName).to(equal("Sensors Present"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.last?.tagDetailValue).to(equal("0x0059 - Present Device Operating Temperature"))
                expect(self.sut.tagViewModels.first?.isOnLed).to(equal(false))
                expect(self.sut.tagViewModels.first?.knownImages).to(equal([nil, nil]))
                
                verify(list.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .completed).to(beTrue())
            }
            
            it("should call perform on runner and finish with success - update tag") {
                let listCommandMock = mock(SILESLCommandList.self).initialize()
                let list = mock(SILESLCommandListRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: listCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandListRunner(peripheral: self.peripheralMock, peripheralReferences: any())).willReturn(list)
                      
                let publishRelay: PublishRelay<Result<[SILESLTag], SILESLCommandGenericError>> = PublishRelay()
                given(list.commandResult).willReturn(publishRelay)
                
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                let btAddress = SILBluetoothAddress(address: "", addressType: .public)
                
                var tag = SILESLTag(btAddress: btAddress, eslId: .broadcast, maxImageIndex: 1, displaysNumber: 1, sensors: [.temperature])
                tag.ledState = .on
                let knownImagesMock = [URL(string: "/"), nil]
                tag.knownImages = knownImagesMock
                self.sut.appendProvisionedTag(tag)
                
                self.sut.listTags()
                let eslTag = SILESLTag(btAddress: btAddress, eslId: .broadcast, maxImageIndex: 1, displaysNumber: 1, sensors: [.temperature])
                publishRelay.accept(.success([eslTag]))
                
                expect(self.sut.tagViewModels.count).to(equal(1))
                expect(self.sut.tagViewModels.first?.btAddress).to(equal(btAddress))
                expect(self.sut.tagViewModels.first?.elsId).to(equal(.broadcast))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.count).to(equal(3))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.first?.tagDetailName).to(equal("Max Image Index"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.first?.tagDetailValue).to(equal("1"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels[1].tagDetailName).to(equal("Displays Count"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels[1].tagDetailValue).to(equal("1"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.last?.tagDetailName).to(equal("Sensors Present"))
                expect(self.sut.tagViewModels.first?.tagDetailViewModels.last?.tagDetailValue).to(equal("0x0059 - Present Device Operating Temperature"))
                expect(self.sut.tagViewModels.first?.isOnLed).to(equal(true))
                expect(self.sut.tagViewModels.first?.knownImages).to(equal(knownImagesMock))
                
                verify(list.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .completed).to(beTrue())
            }
            
            it("should call perform on runner and finish with failure") {
                let listCommandMock = mock(SILESLCommandList.self).initialize()
                let list = mock(SILESLCommandListRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: listCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandListRunner(peripheral: self.peripheralMock, peripheralReferences: any())).willReturn(list)
                      
                let publishRelay: PublishRelay<Result<[SILESLTag], SILESLCommandGenericError>> = PublishRelay()
                given(list.commandResult).willReturn(publishRelay)
                    
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                    
                self.sut.listTags()
                publishRelay.accept(.failure(.errorFromAccessPoint))
                
                verify(list.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .finishedWithError(commandName: "List", error: .errorFromAccessPoint)).to(beTrue())
            }
        }
        
        describe("deleteTag(address:)") {
            it("should call perform on runner and finish with success") {
                let address = SILESLIdAddress.unicast(id: 10)
                let deleteCommandMock = mock(SILESLCommandDelete.self).initialize(address: .eslId(address))
                let delete = mock(SILESLCommandDeleteRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: deleteCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDeleteRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any())).willReturn(delete)
                      
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(delete.commandResult).willReturn(publishRelay)
                
                let tagMock = SILESLTag(btAddress: SILBluetoothAddress(address: "", addressType: .public),
                                        eslId: address,
                                        maxImageIndex: 1,
                                        displaysNumber: 1,
                                        sensors: [])
                self.sut.appendProvisionedTag(tagMock)
                
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                
                self.sut.deleteTag(address: address)
                publishRelay.accept(.success(true))
                
                verify(delete.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .completed).to(beTrue())
                expect(self.sut.tagViewModels.count).to(equal(0))
            }
            
            it("should call perform on runner and finish with failure") {
                let address = SILESLIdAddress.unicast(id: 10)
                let deleteCommandMock = mock(SILESLCommandDelete.self).initialize(address: .eslId(address))
                let delete = mock(SILESLCommandDeleteRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: deleteCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDeleteRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any())).willReturn(delete)
                      
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(delete.commandResult).willReturn(publishRelay)
                    
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                    
                self.sut.deleteTag(address: address)
                publishRelay.accept(.failure(.errorFromAccessPoint))
                
                verify(delete.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .finishedWithError(commandName: "Delete", error: .errorFromAccessPoint)).to(beTrue())
            }
        }
        
        describe("displayImage") {
            it("should call perform on runner and finish with success") {
                let displayImageCommandMock = mock(SILESLCommandDisplayImage.self).initialize(eslId: .broadcast, imageIndex: 1, displayIndex: 1)
                let displayImage = mock(SILESLCommandDisplayImageRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: displayImageCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisplayImageRunner(peripheral: self.peripheralMock, peripheralReferences: any(), eslId: any(), imageIndex: any(), displayIndex: any())).willReturn(displayImage)
                      
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(displayImage.commandResult).willReturn(publishRelay)
                
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                
                self.sut.displayImage(eslId: 10, imageIndex: 1, displayIndex: 1)
                publishRelay.accept(.success(true))
                
                verify(displayImage.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .completed).to(beTrue())
            }
            
            it("should call perform on runner and finish with failure") {
                let displayImageCommandMock = mock(SILESLCommandDisplayImage.self).initialize(eslId: .broadcast, imageIndex: 1, displayIndex: 1)
                let displayImage = mock(SILESLCommandDisplayImageRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: displayImageCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisplayImageRunner(peripheral: self.peripheralMock, peripheralReferences: any(), eslId: any(), imageIndex: any(), displayIndex: any())).willReturn(displayImage)
                      
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(displayImage.commandResult).willReturn(publishRelay)
                    
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                    
                self.sut.displayImageAllTags(imageIndex: 0, displayIndex: 0)
                publishRelay.accept(.failure(.errorFromAccessPoint))
                
                verify(displayImage.perform(timeout: 30.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .finishedWithError(commandName: "Display Image", error: .errorFromAccessPoint)).to(beTrue())
            }
        }
        
        describe("sendLed") {
            it("should call perform on runner and finish with success") {
                let ledCommandMock = mock(SILESLCommandLed.self).initialize(ledState: .on, address: .unicast(id: 5), index: 1)
                let led = mock(SILESLCommandLedRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: ledCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandLedRunner(peripheral: self.peripheralMock, peripheralReferences: any(), ledState: any(), address: any(), index: any())).willReturn(led)
                      
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(led.commandResult).willReturn(publishRelay)
                given(led.getRequestData()).willReturn((address: .unicast(id: 5), newLedState: .on))
                
                let tagMock = SILESLTag(btAddress: SILBluetoothAddress(address: "", addressType: .public),
                                        eslId: .unicast(id: 5),
                                        maxImageIndex: 1,
                                        displaysNumber: 1,
                                        sensors: [])
                let tagViewModelMock = mock(SILESLDemoTagViewModel.self).initialize(tag: tagMock, onTapLedButton: { state in }, onTapImageUpdateButton: { index, url, showImageAfterUpdate in }, onTapDisplayImageButton: { index in }, onTapDeleteButton: { }, onTapPingButton: { })
                given(tagViewModelMock.getElsId()).willReturn(.unicast(id: 5))
                
                self.sut.tagViewModels.append(tagViewModelMock)
                
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                
                self.sut.sendLed(ledState: .on, eslId: 5, index: 1)
                publishRelay.accept(.success(true))
                
                verify(tagViewModelMock.setIsOnLed(true)).wasCalled(1)
                verify(led.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .completed).to(beTrue())
            }
            
            it("should call perform on runner and finish with failure") {
                let ledCommandMock = mock(SILESLCommandLed.self).initialize(ledState: .on, address: .unicast(id: 5), index: 1)
                let led = mock(SILESLCommandLedRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: ledCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandLedRunner(peripheral: self.peripheralMock, peripheralReferences: any(), ledState: any(), address: any(), index: any())).willReturn(led)
                      
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(led.commandResult).willReturn(publishRelay)
                    
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                    
                self.sut.sendLed(ledState: .on, eslId: 5, index: 1)
                publishRelay.accept(.failure(.errorFromAccessPoint))
                
                verify(led.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .finishedWithError(commandName: "Led", error: .errorFromAccessPoint)).to(beTrue())
            }
            
            it("should call perform on runner and finish with success - sendAll") {
                let ledCommandMock = mock(SILESLCommandLed.self).initialize(ledState: .on, address: .unicast(id: 5), index: 1)
                let led = mock(SILESLCommandLedRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: ledCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandLedRunner(peripheral: self.peripheralMock, peripheralReferences: any(), ledState: any(), address: any(), index: any())).willReturn(led)
                      
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(led.commandResult).willReturn(publishRelay)
                given(led.getRequestData()).willReturn((address: .broadcast, newLedState: .on))
                
                let tagMock = SILESLTag(btAddress: SILBluetoothAddress(address: "", addressType: .public),
                                        eslId: .unicast(id: 5),
                                        maxImageIndex: 1,
                                        displaysNumber: 1,
                                        sensors: [])
                let tagViewModelMock = mock(SILESLDemoTagViewModel.self).initialize(tag: tagMock, onTapLedButton: { state in }, onTapImageUpdateButton: { index, url, showImageAfterUpdate in }, onTapDisplayImageButton: { index in }, onTapDeleteButton: { }, onTapPingButton: { })
                let tagMock2 = SILESLTag(btAddress: SILBluetoothAddress(address: "", addressType: .public),
                                        eslId: .unicast(id: 6),
                                        maxImageIndex: 1,
                                        displaysNumber: 1,
                                        sensors: [])
                let tagViewModelMock2 = mock(SILESLDemoTagViewModel.self).initialize(tag: tagMock2, onTapLedButton: { state in }, onTapImageUpdateButton: { index, url, showImageAfterUpdate in }, onTapDisplayImageButton: { index in }, onTapDeleteButton: { }, onTapPingButton: { })
                
                self.sut.tagViewModels.append(contentsOf: [tagViewModelMock, tagViewModelMock2])
                
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                
                self.sut.sendAllTagsLed(ledState: .on, index: 1)
                publishRelay.accept(.success(true))
                
                verify(tagViewModelMock.setIsOnLed(true)).wasCalled(1)
                verify(tagViewModelMock2.setIsOnLed(true)).wasCalled(1)
                verify(led.perform(timeout: 30.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .completed).to(beTrue())
            }
        }
        
        describe("imageUpdate") {
            it("should call perform on runner and finish with success after image_update command") {
                let imageFileMock = URL(string: "../apple.png")!
                let imageUpdate = mock(SILESLImageUpdate.self).initialize(peripheral: self.peripheralMock,
                                                                          peripheralReferences: self.peripheralReferencesMock,
                                                                          commandRunnerFactory: self.commandRunnerFactoryMock,
                                                                          address: .unicast(id: 5),
                                                                          imageIndex: 1,
                                                                          imageFile: imageFileMock,
                                                                          showImageAfterUpdate: false)

                given(self.commandRunnerFactoryMock.createCommandImageUpdate(peripheral: self.peripheralMock, peripheralReferences: any(), commandRunnerFactory: self.commandRunnerFactoryMock, address: any(), imageIndex: any(), imageFile: any(), showImageAfterUpdate: any())).willReturn(imageUpdate)

                let commandResultMock: PublishRelay<Result<SILESLDemoViewModelState, SILESLCommandGenericError>> = PublishRelay()
                given(imageUpdate.commandResult).willReturn(commandResultMock)

                let tagMock = SILESLTag(btAddress: SILBluetoothAddress(address: "", addressType: .public),
                                        eslId: .unicast(id: 5),
                                        maxImageIndex: 1,
                                        displaysNumber: 1,
                                        sensors: [])
                let tagViewModelMock = mock(SILESLDemoTagViewModel.self).initialize(tag: tagMock, onTapLedButton: { state in }, onTapImageUpdateButton: { index, url, showImageAfterUpdate in }, onTapDisplayImageButton: { index in }, onTapDeleteButton: { }, onTapPingButton: { })
                given(tagViewModelMock.getElsId()).willReturn(.unicast(id: 5))

                self.sut.tagViewModels.append(tagViewModelMock)
                      
                var expectedState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    expectedState = commandState
                }).disposed(by: self.disposeBag)

                self.sut.imageUpdate(address: .unicast(id: 5), imageIndex: 1, imageFile: imageFileMock)
                commandResultMock.accept(.success(.processInProgressDisplayImage(address: .unicast(id: 5), imageIndex: 1, imageFile: imageFileMock)))

                verify(tagViewModelMock.updateImage(imageFileMock, at: 1)).wasCalled(1)
                verify(imageUpdate.perform(timeout: 10.0)).wasCalled(1)
                expect(expectedState == .processInProgressDisplayImage(address: .unicast(id: 5), imageIndex: 1, imageFile: imageFileMock)).to(beTrue())
            }
            
            it("should call perform on runner and finish with success after display_image command") {
                let imageFileMock = URL(string: "../apple.png")!
                let imageUpdate = mock(SILESLImageUpdate.self).initialize(peripheral: self.peripheralMock,
                                                                          peripheralReferences: self.peripheralReferencesMock,
                                                                          commandRunnerFactory: self.commandRunnerFactoryMock,
                                                                          address: .unicast(id: 5),
                                                                          imageIndex: 1,
                                                                          imageFile: imageFileMock,
                                                                          showImageAfterUpdate: true)

                given(self.commandRunnerFactoryMock.createCommandImageUpdate(peripheral: self.peripheralMock, peripheralReferences: any(), commandRunnerFactory: self.commandRunnerFactoryMock, address: any(), imageIndex: any(), imageFile: any(), showImageAfterUpdate: any())).willReturn(imageUpdate)

                let commandResultMock: PublishRelay<Result<SILESLDemoViewModelState, SILESLCommandGenericError>> = PublishRelay()
                given(imageUpdate.commandResult).willReturn(commandResultMock)
                      
                var expectedState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    expectedState = commandState
                }).disposed(by: self.disposeBag)

                self.sut.imageUpdate(address: .unicast(id: 5), imageIndex: 1, imageFile: imageFileMock)
                commandResultMock.accept(.success(.completed))

                verify(imageUpdate.perform(timeout: 10.0)).wasCalled(1)
                expect(expectedState == .completed).to(beTrue())
            }
            
            it("should call perform on runner and finish with error") {
                let imageFileMock = URL(string: "../apple.png")!
                let imageUpdate = mock(SILESLImageUpdate.self).initialize(peripheral: self.peripheralMock,
                                                                          peripheralReferences: self.peripheralReferencesMock,
                                                                          commandRunnerFactory: self.commandRunnerFactoryMock,
                                                                          address: .unicast(id: 5),
                                                                          imageIndex: 1,
                                                                          imageFile: imageFileMock,
                                                                          showImageAfterUpdate: true)

                given(self.commandRunnerFactoryMock.createCommandImageUpdate(peripheral: self.peripheralMock, peripheralReferences: any(), commandRunnerFactory: self.commandRunnerFactoryMock, address: any(), imageIndex: any(), imageFile: any(), showImageAfterUpdate: any())).willReturn(imageUpdate)

                let commandResultMock: PublishRelay<Result<SILESLDemoViewModelState, SILESLCommandGenericError>> = PublishRelay()
                given(imageUpdate.commandResult).willReturn(commandResultMock)
                      
                var expectedState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    expectedState = commandState
                }).disposed(by: self.disposeBag)

                self.sut.imageUpdate(address: .unicast(id: 5), imageIndex: 1, imageFile: imageFileMock)
                commandResultMock.accept(.failure(.timeout))

                verify(imageUpdate.perform(timeout: 10.0)).wasCalled(1)
                expect(expectedState == .finishedWithError(commandName: "Image Update", error: .timeout)).to(beTrue())
            }
        }
        
        describe("ping(address:)") {
            it("should call perform on runner and finish with success with change led state to on") {
                let address = SILESLIdAddress.unicast(id: 5)
                let pingCommandMock = mock(SILESLCommandPing.self).initialize(eslId: address)
                let ping = mock(SILESLCommandPingRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: pingCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandPingRunner(peripheral: self.peripheralMock, peripheralReferences: any(), eslId: any())).willReturn(ping)
                      
                let publishRelay: PublishRelay<Result<SILESLBasicStateResponse, SILESLCommandGenericError>> = PublishRelay()
                given(ping.commandResult).willReturn(publishRelay)
  
                let tagMock = SILESLTag(btAddress: SILBluetoothAddress(address: "", addressType: .public),
                                        eslId: address,
                                        maxImageIndex: 1,
                                        displaysNumber: 1,
                                        sensors: [])
                let tagViewModelMock = mock(SILESLDemoTagViewModel.self).initialize(tag: tagMock, onTapLedButton: { state in }, onTapImageUpdateButton: { index, url, showImageAfterUpdate in }, onTapDisplayImageButton: { index in }, onTapDeleteButton: { }, onTapPingButton: { })
                given(tagViewModelMock.getElsId()).willReturn(.unicast(id: 5))
                
                self.sut.tagViewModels.append(contentsOf: [tagViewModelMock])
                
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                
                self.sut.pingTag(address: address)
                let basicStateResponseMock = SILESLBasicStateResponse(bits: 4, activeLed: 0)
                publishRelay.accept(.success(basicStateResponseMock))
                
                verify(ping.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                verify(tagViewModelMock.setIsOnLed(true)).wasCalled(1)
                expect(secondState == .completedWithPopup(text: "The ESL has an active LED: index 0")).to(beTrue())
            }
            
            it("should call perform on runner and finish with success with change led state to off") {
                let address = SILESLIdAddress.unicast(id: 5)
                let pingCommandMock = mock(SILESLCommandPing.self).initialize(eslId: address)
                let ping = mock(SILESLCommandPingRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: pingCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandPingRunner(peripheral: self.peripheralMock, peripheralReferences: any(), eslId: any())).willReturn(ping)
                      
                let publishRelay: PublishRelay<Result<SILESLBasicStateResponse, SILESLCommandGenericError>> = PublishRelay()
                given(ping.commandResult).willReturn(publishRelay)
  
                let tagMock = SILESLTag(btAddress: SILBluetoothAddress(address: "", addressType: .public),
                                        eslId: address,
                                        maxImageIndex: 1,
                                        displaysNumber: 1,
                                        sensors: [])
                let tagViewModelMock = mock(SILESLDemoTagViewModel.self).initialize(tag: tagMock, onTapLedButton: { state in }, onTapImageUpdateButton: { index, url, showImageAfterUpdate in }, onTapDisplayImageButton: { index in }, onTapDeleteButton: { }, onTapPingButton: { })
                given(tagViewModelMock.getElsId()).willReturn(.unicast(id: 5))
                
                self.sut.tagViewModels.append(contentsOf: [tagViewModelMock])
                
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                
                self.sut.pingTag(address: address)
                let basicStateResponseMock = SILESLBasicStateResponse(bits: 2, activeLed: 0)
                publishRelay.accept(.success(basicStateResponseMock))
                
                verify(ping.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                verify(tagViewModelMock.setIsOnLed(false)).wasCalled(1)
                expect(secondState == .completedWithPopup(text: "The ESL is synchronized to the AP")).to(beTrue())
            }
            
            it("should call perform on runner and finish with failure") {
                let address = SILESLIdAddress.unicast(id: 10)
                let pingCommandMock = mock(SILESLCommandPing.self).initialize(eslId: address)
                let ping = mock(SILESLCommandPingRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: pingCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandPingRunner(peripheral: self.peripheralMock, peripheralReferences: any(), eslId: any())).willReturn(ping)
                      
                let publishRelay: PublishRelay<Result<SILESLBasicStateResponse, SILESLCommandGenericError>> = PublishRelay()
                given(ping.commandResult).willReturn(publishRelay)
                    
                var i = 0
                var firstState: SILESLDemoViewModelState = .completed
                var secondState: SILESLDemoViewModelState = .starting
                self.sut.commandState.asObservable().subscribe(onNext: { commandState in
                    if i == 0 {
                        firstState = commandState
                    } else {
                        secondState = commandState
                    }
                    i += 1
                }).disposed(by: self.disposeBag)
                    
                self.sut.pingTag(address: address)
                publishRelay.accept(.failure(.errorFromAccessPoint))
                
                verify(ping.perform(timeout: 10.0)).wasCalled(1)
                expect(firstState == .starting).to(beTrue())
                expect(secondState == .finishedWithError(commandName: "Ping", error: .errorFromAccessPoint)).to(beTrue())
            }
        }
    }
}
