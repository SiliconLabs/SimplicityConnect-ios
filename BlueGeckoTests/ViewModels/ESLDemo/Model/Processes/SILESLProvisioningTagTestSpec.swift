//
//  SILESLProvisioningTagTestSpec.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 12.4.2023.
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

class SILESLProvisioningTagTestSpec: QuickSpec {
    var sut: SILESLProvisioningTag!
    var peripheralMock: CBPeripheral!
    var commandRunnerFactoryMock: SILESLCommandRunnerFactoryMock!
    var peripheralReferencesMock: SILESLPeripheralGATTReferences!
    var disposeBag = DisposeBag()
    
    override func spec() {
        beforeEach {
            self.peripheralMock = mock(CBPeripheral.self)
            self.peripheralReferencesMock = SILESLPeripheralGATTReferences()
            self.commandRunnerFactoryMock = mock(SILESLCommandRunnerFactory.self)
            self.sut = SILESLProvisioningTag(peripheral: self.peripheralMock,
                                             peripheralReferences: self.peripheralReferencesMock,
                                             commandRunnerFactory: self.commandRunnerFactoryMock,
                                             address: .init(address: "", addressType: .public))
        }
        
        afterEach {
            self.disposeBag = DisposeBag()
        }
        
        describe("perform(timeout:)") {
            it("should call function and return success") {
                let btAddress = SILBluetoothAddress(address: "", addressType: .public)
                let connectCommandMock = mock(SILESLCommandConnect.self).initialize(address: .btAddress(btAddress), passcode: "1234")
                let connect = mock(SILESLCommandConnectRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: connectCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandConnectRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any(), passcode: any())).willReturn(connect)
                
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(connect.commandResult).willReturn(publishRelay)
                
                var expectedResult: Result<SILESLDemoViewModelState, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    expectedResult = result
                }).disposed(by: self.disposeBag)
                
                self.sut.perform(timeout: 10.0)
                publishRelay.accept(.success(true))
                
                verify(connect.perform(timeout: 10.0)).wasCalled(1)
                expect(expectedResult == .success(.provisioningInProgressConfig)).to(equal(true))
            }
            
            it("should call function and return error") {
                let btAddress = SILBluetoothAddress(address: "", addressType: .public)
                let connectCommandMock = mock(SILESLCommandConnect.self).initialize(address: .btAddress(btAddress), passcode: "1234")
                let connect = mock(SILESLCommandConnectRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: connectCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandConnectRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any(), passcode: any())).willReturn(connect)
                
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(connect.commandResult).willReturn(publishRelay)
                
                var expectedResult: Result<SILESLDemoViewModelState, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    expectedResult = result
                }).disposed(by: self.disposeBag)
                
                self.sut.perform(timeout: 10.0)
                publishRelay.accept(.failure(.timeout))
                
                verify(connect.perform(timeout: 10.0)).wasCalled(1)
                expect(expectedResult == .failure(.timeout)).to(equal(true))
            }
        }
        
        describe("configureConnectedTag()") {
            it("should call function and return success") {
                let configureCommandMock = mock(SILESLCommandConfigure.self).initialize()
                let configure = mock(SILESLCommandConfigureRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: configureCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandConfigureRunner(peripheral: self.peripheralMock, peripheralReferences: any())).willReturn(configure)
                
                let publishRelay: PublishRelay<Result<SILESLTag, SILESLCommandGenericError>> = PublishRelay()
                given(configure.commandResult).willReturn(publishRelay)
                
                var expectedResult: Result<SILESLDemoViewModelState, SILESLCommandGenericError>!
                let tag = SILESLTag(btAddress: .init(address: "", addressType: .public), eslId: .broadcast, maxImageIndex: 0, displaysNumber: 0, sensors: [])
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    expectedResult = result
                }).disposed(by: self.disposeBag)
                
                self.sut.configureConnectedTag()
                publishRelay.accept(.success(tag))
                
                verify(configure.perform(timeout: 0.0)).wasCalled(1)
                expect(expectedResult == .success(.provisioningInProgressImageUpdate(tag: tag))).to(equal(true))
            }
            
            it("should call function and return error") {
                let configureCommandMock = mock(SILESLCommandConfigure.self).initialize()
                let configure = mock(SILESLCommandConfigureRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: configureCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandConfigureRunner(peripheral: self.peripheralMock, peripheralReferences: any())).willReturn(configure)
                
                let publishRelay: PublishRelay<Result<SILESLTag, SILESLCommandGenericError>> = PublishRelay()
                given(configure.commandResult).willReturn(publishRelay)
                
                let disconnectCommandMock = mock(SILESLCommandDisconnect.self).initialize(address: nil)
                let disconnect = mock(SILESLCommandDisconnectRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: disconnectCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisconnectRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any())).willReturn(disconnect)
                
                let publishRelayDisconnect: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(disconnect.commandResult).willReturn(publishRelayDisconnect)

                var expectedResult: Result<SILESLDemoViewModelState, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    expectedResult = result
                }).disposed(by: self.disposeBag)
                
                self.sut.configureConnectedTag()
                publishRelay.accept(.failure(.timeout))
                publishRelayDisconnect.accept(.success(true))
                
                verify(configure.perform(timeout: 0.0)).wasCalled(1)
                verify(disconnect.perform(timeout: 0.0)).wasCalled(1)
                expect(expectedResult == .failure(.timeout)).to(equal(true))
            }
        }
        
        describe("imageUpdate(address:imageIndex:imageFile:showImageAfterUpdate:)") {
            it("should call function and return success with showImageAfterUpdate = true, display success") {
                let imageFileMock = URL(string: "../apple.png")!
                let imageUpdateMock = mock(SILESLCommandImageUpdate.self).initialize(imageIndex: 1, imageFile: imageFileMock)
                let imageUpdate = mock(SILESLCommandImageUpdateRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: imageUpdateMock)
                
                given(self.commandRunnerFactoryMock.createCommandImageUpdateRunner(peripheral: self.peripheralMock, peripheralReferences: any(), imageIndex: any(), imageFile: any())).willReturn(imageUpdate)
                
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(imageUpdate.commandResult).willReturn(publishRelay)
                
                let progressUpdateMock: PublishRelay<String> = PublishRelay()
                given(imageUpdate.updateProgress).willReturn(progressUpdateMock)
                given(imageUpdate.getRequestData()).willReturn((imageIndex: 0, imageFile: imageFileMock))
                
                let displayImageCommandMock = mock(SILESLCommandDisplayImage.self).initialize(eslId: .broadcast, imageIndex: 1, displayIndex: 1)
                let displayImage = mock(SILESLCommandDisplayImageRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: displayImageCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisplayImageRunner(peripheral: self.peripheralMock, peripheralReferences: any(), eslId: any(), imageIndex: any(), displayIndex: any())).willReturn(displayImage)
                
                let publishRelayDislayImage: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(displayImage.commandResult).willReturn(publishRelayDislayImage)
                
                let disconnectCommandMock = mock(SILESLCommandDisconnect.self).initialize(address: nil)
                let disconnect = mock(SILESLCommandDisconnectRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: disconnectCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisconnectRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any())).willReturn(disconnect)
                
                let publishRelayDisconnect: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(disconnect.commandResult).willReturn(publishRelayDisconnect)
                
                var expectedResult: Result<SILESLDemoViewModelState, SILESLCommandGenericError>!
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    expectedResult = result
                }).disposed(by: self.disposeBag)
                
                self.sut.imageUpdate(address: .broadcast, imageIndex: 0, imageFile: imageFileMock, showImageAfterUpdate: true)
                publishRelay.accept(.success(true))
                publishRelayDisconnect.accept(.success(true))
                publishRelayDislayImage.accept(.success(true))
                
                verify(imageUpdate.perform(timeout: 0.0)).wasCalled(1)
                verify(disconnect.perform(timeout: 0.0)).wasCalled(1)
                verify(displayImage.perform(timeout: 0.0)).wasCalled(1)
                expect(expectedResult == .success(.completed)).to(equal(true))
            }
            
            it("should call function and return success with showImageAfterUpdate = true, display error") {
                let imageFileMock = URL(string: "../apple.png")!
                let imageUpdateMock = mock(SILESLCommandImageUpdate.self).initialize(imageIndex: 1, imageFile: imageFileMock)
                let imageUpdate = mock(SILESLCommandImageUpdateRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: imageUpdateMock)
                
                given(self.commandRunnerFactoryMock.createCommandImageUpdateRunner(peripheral: self.peripheralMock, peripheralReferences: any(), imageIndex: any(), imageFile: any())).willReturn(imageUpdate)
                
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(imageUpdate.commandResult).willReturn(publishRelay)
                
                let progressUpdateMock: PublishRelay<String> = PublishRelay()
                given(imageUpdate.updateProgress).willReturn(progressUpdateMock)
                given(imageUpdate.getRequestData()).willReturn((imageIndex: 0, imageFile: imageFileMock))
                
                let displayImageCommandMock = mock(SILESLCommandDisplayImage.self).initialize(eslId: .broadcast, imageIndex: 1, displayIndex: 1)
                let displayImage = mock(SILESLCommandDisplayImageRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: displayImageCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisplayImageRunner(peripheral: self.peripheralMock, peripheralReferences: any(), eslId: any(), imageIndex: any(), displayIndex: any())).willReturn(displayImage)
                
                let publishRelayDislayImage: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(displayImage.commandResult).willReturn(publishRelayDislayImage)
                
                let disconnectCommandMock = mock(SILESLCommandDisconnect.self).initialize(address: nil)
                let disconnect = mock(SILESLCommandDisconnectRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: disconnectCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisconnectRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any())).willReturn(disconnect)
                
                let publishRelayDisconnect: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(disconnect.commandResult).willReturn(publishRelayDisconnect)
                
                var expectedResult: Result<SILESLDemoViewModelState, SILESLCommandGenericError>!
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    expectedResult = result
                }).disposed(by: self.disposeBag)
                
                self.sut.imageUpdate(address: .broadcast, imageIndex: 0, imageFile: imageFileMock, showImageAfterUpdate: true)
                publishRelay.accept(.success(true))
                publishRelayDisconnect.accept(.success(true))
                publishRelayDislayImage.accept(.failure(.timeout))
                
                verify(imageUpdate.perform(timeout: 0.0)).wasCalled(1)
                verify(displayImage.perform(timeout: 0.0)).wasCalled(1)
                verify(disconnect.perform(timeout: 0.0)).wasCalled(1)
                expect(expectedResult == .failure(.timeout)).to(equal(true))
            }
            
            it("should call function and return success with showImageAfterUpdate = false") {
                let imageFileMock = URL(string: "../apple.png")!
                let imageUpdateMock = mock(SILESLCommandImageUpdate.self).initialize(imageIndex: 1, imageFile: imageFileMock)
                let imageUpdate = mock(SILESLCommandImageUpdateRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: imageUpdateMock)
                
                given(self.commandRunnerFactoryMock.createCommandImageUpdateRunner(peripheral: self.peripheralMock, peripheralReferences: any(), imageIndex: any(), imageFile: any())).willReturn(imageUpdate)
                
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(imageUpdate.commandResult).willReturn(publishRelay)
                
                let progressUpdateMock: PublishRelay<String> = PublishRelay()
                given(imageUpdate.updateProgress).willReturn(progressUpdateMock)
                given(imageUpdate.getRequestData()).willReturn((imageIndex: 0, imageFile: imageFileMock))
                
                let disconnectCommandMock = mock(SILESLCommandDisconnect.self).initialize(address: nil)
                let disconnect = mock(SILESLCommandDisconnectRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: disconnectCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisconnectRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any())).willReturn(disconnect)
                
                let publishRelayDisconnect: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(disconnect.commandResult).willReturn(publishRelayDisconnect)
                
                var expectedResult: Result<SILESLDemoViewModelState, SILESLCommandGenericError>!
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    expectedResult = result
                }).disposed(by: self.disposeBag)
                
                self.sut.imageUpdate(address: .broadcast, imageIndex: 0, imageFile: imageFileMock)
                publishRelay.accept(.success(true))
                publishRelayDisconnect.accept(.failure(.unknown))
                
                verify(imageUpdate.perform(timeout: 0.0)).wasCalled(1)
                verify(disconnect.perform(timeout: 0.0)).wasCalled(1)
                expect(expectedResult == .failure(.unknown)).to(equal(true))
            }
            
            it("should call function and return error") {
                let imageFileMock = URL(string: "../apple.png")!
                let imageUpdateMock = mock(SILESLCommandImageUpdate.self).initialize(imageIndex: 1, imageFile: imageFileMock)
                let imageUpdate = mock(SILESLCommandImageUpdateRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: imageUpdateMock)
                
                given(self.commandRunnerFactoryMock.createCommandImageUpdateRunner(peripheral: self.peripheralMock, peripheralReferences: any(), imageIndex: any(), imageFile: any())).willReturn(imageUpdate)
                
                let publishRelay: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(imageUpdate.commandResult).willReturn(publishRelay)
                
                let progressUpdateMock: PublishRelay<String> = PublishRelay()
                given(imageUpdate.updateProgress).willReturn(progressUpdateMock)
                
                let disconnectCommandMock = mock(SILESLCommandDisconnect.self).initialize(address: nil)
                let disconnect = mock(SILESLCommandDisconnectRunner.self).initialize(peripheral: self.peripheralMock, peripheralReferences: self.peripheralReferencesMock, command: disconnectCommandMock)
                
                given(self.commandRunnerFactoryMock.createCommandDisconnectRunner(peripheral: self.peripheralMock, peripheralReferences: any(), address: any())).willReturn(disconnect)
                
                let publishRelayDisconnect: PublishRelay<Result<Bool, SILESLCommandGenericError>> = PublishRelay()
                given(disconnect.commandResult).willReturn(publishRelayDisconnect)
                
                var expectedResult: Result<SILESLDemoViewModelState, SILESLCommandGenericError>!
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    expectedResult = result
                }).disposed(by: self.disposeBag)
                
                self.sut.imageUpdate(address: .broadcast, imageIndex: 0, imageFile: imageFileMock)
                publishRelay.accept(.failure(.timeout))
                publishRelayDisconnect.accept(.failure(.unknown))
                
                verify(imageUpdate.perform(timeout: 0.0)).wasCalled(1)
                verify(disconnect.perform(timeout: 0.0)).wasCalled(1)
                expect(expectedResult == .failure(.unknown)).to(equal(true))
            }
        }
    }
}

