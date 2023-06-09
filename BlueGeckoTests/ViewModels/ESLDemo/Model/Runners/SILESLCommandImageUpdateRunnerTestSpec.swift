//
//  SILESLCommandImageUpdateRunnerTestSpec.swift
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

class SILESLCommandImageUpdateRunnerTestSpec: QuickSpec {
    var sut: SILESLCommandImageUpdateRunner!
    var peripheralMock: CBPeripheral!
    var imageIndexMock: UInt!
    var imageFileMock: URL!
    var commandMock: SILESLCommandImageUpdateMock!
    var eslDemoServiceMock: CBService!
    var eslControlPointMock: CBCharacteristic!
    var eslImageTransferMock: CBCharacteristic!
    var peripheralReferencesMock: SILESLPeripheralGATTReferences!
    var disposeBag = DisposeBag()
    
    override func spec() {
        beforeEach {
            self.imageIndexMock = 0
            self.imageFileMock = URL(string: "../apple.jpg")!
            self.commandMock = mock(SILESLCommandImageUpdate.self).initialize(imageIndex: self.imageIndexMock,
                                                                              imageFile: self.imageFileMock)
            given(self.commandMock.getFullCommand()).willReturn("")
            let defaultMock = SILESLPeripheralMockFactory().getDefault()
            self.eslDemoServiceMock = defaultMock.eslDemoServiceMock
            self.eslControlPointMock = defaultMock.eslControlPointMock
            self.eslImageTransferMock = defaultMock.eslImageTransferMock
            self.peripheralMock = defaultMock.peripheralMock
            given(self.peripheralMock.maximumWriteValueLength(for: .withResponse)).willReturn(5)
            self.peripheralReferencesMock = defaultMock.peripheralReferencesMock
            self.sut = SILESLCommandImageUpdateRunner(peripheral: self.peripheralMock,
                                                      peripheralReferences: self.peripheralReferencesMock,
                                                      command: self.commandMock)
        }
        
        afterEach {
            self.disposeBag = DisposeBag()
        }
        
        describe("perform") {
            it("should run without error") {
                given(self.eslControlPointMock.isNotifying).willReturn(true)
                given(self.commandMock.getImageFileData()).willReturn(Data(bytes: [1, 2, 3]))
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
                self.sut = SILESLCommandImageUpdateRunner(peripheral: self.peripheralMock,
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
            it("should receive callback without errors with value 0300 and return success") {
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!

                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)

                given(self.eslControlPointMock.value).willReturn(Data(bytes: [3, 0]))

                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)

                expect(resultFromCommand == .success(true)).to(equal(true))
            }
            
            it("should receive callback without errors with value 0301 and return error") {
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!

                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)

                given(self.eslControlPointMock.value).willReturn(Data(bytes: [3, 1]))

                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslControlPointMock, error: nil)
                
                expect(resultFromCommand == .failure(.errorFromAccessPoint)).to(equal(true))
            }
            
            it("should receive callback without errors and more chunk request and send a chunk") {
                let fileData = Data(bytes: [1, 2, 3, 4, 5])
                given(self.commandMock.getImageFileData()).willReturn(fileData)
                var dataToWrite = Data(bytes: [UInt8(0)])
                dataToWrite.append(fileData[0..<4].bytes, count: 4)
                                        
                var uploadProgress: String = ""

                self.sut.updateProgress.asObservable().subscribe(onNext: { progress in
                    uploadProgress = progress
                }).disposed(by: self.disposeBag)

                given(self.eslImageTransferMock.value).willReturn(Data(bytes: [239, 0, 0, 0, 0, 0]))

                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslImageTransferMock, error: nil)
                
                expect(uploadProgress).to(equal("0.0%"))
                verify(self.peripheralMock.writeValue(dataToWrite, for: self.eslImageTransferMock, type: .withResponse)).wasCalled(1)
            }
            
            it("should receive callback without errors and wrong more chunk request and return error - wrong header") {
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!

                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)

                given(self.eslImageTransferMock.value).willReturn(Data(bytes: [222, 0, 0, 0, 0, 0]))

                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslImageTransferMock, error: nil)
                
                expect(resultFromCommand == .failure(.errorFromAccessPoint)).to(equal(true))
            }
            
            it("should receive callback without errors with more chunk request and send a chunk") {
                let fileData = Data(bytes: [1, 2, 3, 4, 5])
                given(self.commandMock.getImageFileData()).willReturn(fileData)
                var dataToWrite = Data(bytes: [UInt8(1)])
                dataToWrite.append(fileData[4..<5].bytes, count: 1)
                                        
                var uploadProgress: String = ""

                self.sut.updateProgress.asObservable().subscribe(onNext: { progress in
                    uploadProgress = progress
                }).disposed(by: self.disposeBag)

                given(self.eslImageTransferMock.value).willReturn(Data(bytes: [239, 4, 0, 0, 0, 0]))

                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslImageTransferMock, error: nil)
                
                expect(uploadProgress).to(equal("80.0%"))
                verify(self.peripheralMock.writeValue(dataToWrite, for: self.eslImageTransferMock, type: .withResponse)).wasCalled(1)
            }
            
            it("should receive callback without errors with wrong more chunk request and return error") {
                var resultFromCommand: Result<Bool, SILESLCommandGenericError>!

                self.sut.commandResult.asObservable().subscribe(onNext: { result in
                    resultFromCommand = result
                }).disposed(by: self.disposeBag)

                given(self.eslImageTransferMock.value).willReturn(Data(bytes: [239, 4, 0, 0, 0, 0, 0, 0]))

                self.sut.peripheral(self.peripheralMock, didUpdateValueFor: self.eslImageTransferMock, error: nil)
                
                expect(resultFromCommand == .failure(.errorFromAccessPoint)).to(equal(true))
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
            
            it("should receive callback with errors") {
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
