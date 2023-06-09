//
//  SILESLCommandConfigureRunnerTestSpec.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 24.3.2023.
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

class SILESLCommandConfigureRunnerTestSpec: QuickSpec {
    var sut: SILESLCommandConfigureRunner!
    var peripheralMock: CBPeripheral!
    var commandMock: SILESLCommandConfigureMock!
    var eslDemoServiceMock: CBService!
    var eslControlPointMock: CBCharacteristic!
    var peripheralReferencesMock: SILESLPeripheralGATTReferences!
    var disposeBag = DisposeBag()
    
    override func spec() {
        beforeEach {
            self.commandMock = mock(SILESLCommandConfigure.self).initialize()
            given(self.commandMock.getFullCommand()).willReturn("")
            let defaultMock = SILESLPeripheralMockFactory().getDefault()
            self.eslDemoServiceMock = defaultMock.eslDemoServiceMock
            self.eslControlPointMock = defaultMock.eslControlPointMock
            self.peripheralMock = defaultMock.peripheralMock
            self.peripheralReferencesMock = defaultMock.peripheralReferencesMock
            self.sut = SILESLCommandConfigureRunner(peripheral: self.peripheralMock,
                                                    peripheralReferences: self.peripheralReferencesMock,
                                                    command: self.commandMock)
        }
        
        afterEach {
            self.disposeBag = DisposeBag()
        }
        
        describe("perform") {
            it("should run without error") {
                given(self.eslControlPointMock.isNotifying).willReturn(true)
                
                self.sut.perform(timeout: 10.0)
                
                verify(self.peripheralMock.writeValue(Data(bytes: self.commandMock.dataToSend),
                                                      for: self.peripheralReferencesMock.eslControlPoint!,
                                                      type: .withResponse)).wasCalled(1)
            }
            
            it("should run with error - isnt notifying") {
                given(self.eslControlPointMock.isNotifying).willReturn(false)
                
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.perform(timeout: 10.0)
                
                expect(resultFromCommand == .failure(.characteristicIsntNotifying)).to(beTrue())
            }
            
            it("should run with error - missing characteristic") {
                self.peripheralReferencesMock = SILESLPeripheralGATTReferences()
                self.sut = SILESLCommandConfigureRunner(peripheral: self.peripheralMock,
                                                        peripheralReferences: self.peripheralReferencesMock,
                                                        command: self.commandMock)
                
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.perform(timeout: 10.0)
                
                expect(resultFromCommand == .failure(.missingCharacteristic)).to(beTrue())
            }
        }
        
        describe("didWriteValueFor:") {
            it("should receive callback without errors") {
                var wasCalled = false
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    wasCalled = true
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didWriteValueFor: self.eslControlPointMock, error: nil)
                
                expect(wasCalled).to(beFalse())
            }
            
            it("should receive callback from other characteristic") {
                var wasCalled = false
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    wasCalled = true
                }).disposed(by: self.disposeBag)
                
                let characterisiticMock = mock(CBCharacteristic.self)
                given(characterisiticMock.uuid).willReturn(CBUUID(string: "1800"))
                
                self.sut.peripheral(self.peripheralMock, didWriteValueFor: characterisiticMock, error: nil)
                
                expect(wasCalled).to(beFalse())
            }
            
            it("should receive callback with errors") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didWriteValueFor: self.eslControlPointMock, error: TestError.unknown)
                
                expect(resultFromCommand == .failure(.errorFromCharacteristic(error: TestError.unknown))).to(beTrue())
            }
        }
        
        describe("didUpdateNotifcationStateFor:") {
            it("should receive callback without errors") {
                var wasCalled = false
                
                given(self.eslControlPointMock.isNotifying).willReturn(true)
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    wasCalled = true
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didUpdateNotificationStateFor: self.eslControlPointMock, error: nil)
                
                expect(wasCalled).to(beFalse())
            }
            
            it("should receive callback from other characteristic") {
                var wasCalled = false
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    wasCalled = true
                }).disposed(by: self.disposeBag)
                
                let characterisiticMock = mock(CBCharacteristic.self)
                given(characterisiticMock.uuid).willReturn(CBUUID(string: "1800"))
                
                self.sut.peripheral(self.peripheralMock, didUpdateNotificationStateFor: characterisiticMock, error: nil)
                
                expect(wasCalled).to(beFalse())
            }
            
            it("should receive callback with errors ") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didUpdateNotificationStateFor: self.eslControlPointMock, error: TestError.unknown)
                
                expect(resultFromCommand == .failure(.errorFromCharacteristic(error: TestError.unknown))).to(beTrue())
            }
            
            it("should receive callback without error but isn't notifying") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                given(self.eslControlPointMock.isNotifying).willReturn(false)
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didUpdateNotificationStateFor: self.eslControlPointMock, error: nil)
                
                expect(resultFromCommand == .failure(.characteristicIsntNotifying)).to(beTrue())
            }
        }
        
        describe("didUpdateValueFor:") {
            it("should receive callback without errors with value 0101") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [1, 1]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                expect(resultFromCommand == .failure(.errorFromAccessPoint)).to(beTrue())
            }
            
            it("should drop message with wrong opcode") {
                var wasCalled = false
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    wasCalled = true
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [3, 1]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                expect(wasCalled).to(beFalse())
            }
            
            it("should return esl tag") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [1, 0, 97, 2, 1, 54, 56, 58, 48, 97, 58, 101, 50, 58, 50, 56, 58, 56, 55, 58, 98, 50, 89, 0, 84, 0, 85, 0]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                let btAddress =  SILBluetoothAddress(address: "68:0a:e2:28:87:b2", addressType: .public)
                let expectedTag = SILESLTag(btAddress: btAddress,
                                            eslId: .unicast(id: 97),
                                            maxImageIndex: 1,
                                            displaysNumber: 1,
                                            sensors: [.temperature, .batteryState, .unknown(id: "0x0055")])
                
                expect(resultFromCommand == .success(expectedTag)).to(beTrue())
            }
            
            it("should return error when data incomplete - count = 3 ") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [1, 0, 97]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
    
                expect(resultFromCommand == .failure(.errorFromAccessPoint)).to(beTrue())
            }
            
            it("should return error when data incomplete - count = 6") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [1, 0, 97, 1, 1, 5]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
    
                expect(resultFromCommand == .failure(.errorFromAccessPoint)).to(beTrue())
            }
            
            it("should return esl tag when incomplete sensors data") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [1, 0, 97, 2, 1, 54, 56, 58, 48, 97, 58, 101, 50, 58, 50, 56, 58, 56, 55, 58, 98, 50, 89, 0, 84, 0]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                let btAddress =  SILBluetoothAddress(address: "68:0a:e2:28:87:b2", addressType: .public)
                let expectedTag = SILESLTag(btAddress: btAddress,
                                            eslId: .unicast(id: 97),
                                            maxImageIndex: 1,
                                            displaysNumber: 1,
                                            sensors: [.temperature, .batteryState])
                
                expect(resultFromCommand == .success(expectedTag)).to(beTrue())
            }
            
            it("should return esl tag when no sensors") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [1, 0, 97, 2, 1, 54, 56, 58, 48, 97, 58, 101, 50, 58, 50, 56, 58, 56, 55, 58, 98, 50, 0, 0, 0, 0]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                let btAddress =  SILBluetoothAddress(address: "68:0a:e2:28:87:b2", addressType: .public)
                let expectedTag = SILESLTag(btAddress: btAddress,
                                            eslId: .unicast(id: 97),
                                            maxImageIndex: 1,
                                            displaysNumber: 1,
                                            sensors: [])
                
                expect(resultFromCommand == .success(expectedTag)).to(beTrue())
            }
            
            it("should receive callback from other characteristic") {
                var wasCalled = false
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    wasCalled = true
                }).disposed(by: self.disposeBag)
                
                let characterisiticMock = mock(CBCharacteristic.self)
                given(characterisiticMock.uuid).willReturn(CBUUID(string: "1800"))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: characterisiticMock, error: nil)
                
                expect(wasCalled).to(beFalse())
            }
            
            it("should receive callback with errors ") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: TestError.unknown)
                
                expect(resultFromCommand == .failure(.errorFromCharacteristic(error: TestError.unknown))).to(beTrue())
            }
            
            it("should receive callback without errors but value is nil") {
                var resultFromCommand: Result<SILESLTag, SILESLCommandGenericError>!
                
                given(self.eslControlPointMock.value).willReturn(nil)
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                expect(resultFromCommand == .failure(.errorFromAccessPoint)).to(beTrue())
            }
        }
    }
}
