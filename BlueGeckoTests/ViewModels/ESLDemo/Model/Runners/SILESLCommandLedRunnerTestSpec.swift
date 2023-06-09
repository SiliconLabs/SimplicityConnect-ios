//
//  SILESLCommandLedRunnerTestSpec.swift
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

class SILESLCommandLedRunnerTestSpec: QuickSpec {
    var sut: SILESLCommandLedRunner!
    var peripheralMock: CBPeripheral!
    var ledStateMock: SILESLLedState!
    var addressMock: SILESLIdAddress!
    var commandMock: SILESLCommandLedMock!
    var eslDemoServiceMock: CBService!
    var eslControlPointMock: CBCharacteristic!
    var peripheralReferencesMock: SILESLPeripheralGATTReferences!
    var disposeBag = DisposeBag()
    
    override func spec() {
        beforeEach {
            self.ledStateMock = .on
            self.addressMock = .broadcast
            self.commandMock = mock(SILESLCommandLed.self).initialize(ledState: self.ledStateMock, address: self.addressMock, index: 1)
            let defaultMock = SILESLPeripheralMockFactory().getDefault()
            given(self.commandMock.getFullCommand()).willReturn("")
            self.eslDemoServiceMock = defaultMock.eslDemoServiceMock
            self.eslControlPointMock = defaultMock.eslControlPointMock
            self.peripheralMock = defaultMock.peripheralMock
            self.peripheralReferencesMock = defaultMock.peripheralReferencesMock
            self.sut = SILESLCommandLedRunner(peripheral: self.peripheralMock,
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
                
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.perform(timeout: 10.0)
                
                expect(resultFromCommand == .failure(.characteristicIsntNotifying)).to(beTrue())
            }
            
            it("should run with error - missing characteristic") {
                self.peripheralReferencesMock = SILESLPeripheralGATTReferences()
                self.sut = SILESLCommandLedRunner(peripheral: self.peripheralMock,
                                                  peripheralReferences: self.peripheralReferencesMock,
                                                  command: self.commandMock)
                
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
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
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
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
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didUpdateNotificationStateFor: self.eslControlPointMock, error: TestError.unknown)
                
                expect(resultFromCommand == .failure(.errorFromCharacteristic(error: TestError.unknown))).to(beTrue())
            }
            
            it("should receive callback without error but isn't notifying") {
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
                given(self.eslControlPointMock.isNotifying).willReturn(false)
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didUpdateNotificationStateFor: self.eslControlPointMock, error: nil)
                
                expect(resultFromCommand == .failure(.characteristicIsntNotifying)).to(beTrue())
            }
        }
        
        describe("didUpdateValueFor:") {
            it("should receive callback without errors with value 0600") {
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [6, 0]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                expect(resultFromCommand == .success(true)).to(beTrue())
            }
            
            it("should receive callback without errors with value 0601") {
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [6, 1]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                expect(resultFromCommand == .failure(.errorFromAccessPoint)).to(beTrue())
            }
            
            it("should drop message with wrong opcode") {
                var wasCalled = false
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    wasCalled = true
                }).disposed(by: self.disposeBag)
                
                given(self.eslControlPointMock.value).willReturn(Data(bytes: [2, 1]))
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                expect(wasCalled).to(beFalse())
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
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)
                
                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: TestError.unknown)
                
                expect(resultFromCommand == .failure(.errorFromCharacteristic(error: TestError.unknown))).to(beTrue())
            }
            
            it("should receive callback without errors but value is nil") {
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!
                
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
