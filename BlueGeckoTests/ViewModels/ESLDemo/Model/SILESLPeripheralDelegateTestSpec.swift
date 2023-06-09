//
//  SILESLPeripheralDelegateTestSpec.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 20.3.2023.
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

class SILESLPeripheralDelegateTestSpec: QuickSpec {
    var sut: SILESLPeripheralDelegate!
    var peripheralMock: CBPeripheral!
    var peripheralReferencesMock: SILESLPeripheralGATTReferences!
    var disposeBag = DisposeBag()
    
    override func spec() {
        beforeEach {
            self.peripheralMock = mock(CBPeripheral.self)
            self.peripheralReferencesMock = SILESLPeripheralGATTReferences()
            self.sut = SILESLPeripheralDelegate(peripheral: self.peripheralMock,
                                                peripheralReferences: self.peripheralReferencesMock)
        }
        
        afterEach {
            self.disposeBag = DisposeBag()
        }
        
        describe("discoverGATTDatabase") {
            it("should invoke discover service with UUID on peripheral") {
                self.sut.discoverGATTDatabase()
                
                verify(self.peripheralMock.discoverServices([SILESLPeripheralGATTDatabase.ESLDemoService.cbUUID])).wasCalled(1)
            }
        }
                
        describe("peripheral(_:didDiscoverServices:") {
            let expectedError = SILESLPeripheralDelegateError.missingService
            var receivedError: SILESLPeripheralDelegateError? = nil
            var observerWasCalled = false
            
            beforeEach {
                self.sut.initializationState.asObservable().subscribe(onNext: { error in
                    receivedError = error
                    observerWasCalled = true
                }).disposed(by: self.disposeBag)
            }
            
            afterEach {
                receivedError = nil
                observerWasCalled = false
                self.disposeBag = DisposeBag()
            }
            
            it("request returns error") {
                self.sut.peripheral(self.peripheralMock, didDiscoverServices: TestError.unknown)
                
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
            
            it("no services found") {
                given(self.peripheralMock.services).willReturn([CBService]())
                
                self.sut.peripheral(self.peripheralMock, didDiscoverServices: nil)
                
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
            
            it("found service") {
                let mockESLDemoService = mock(CBService.self)
                given(mockESLDemoService.uuid).willReturn(SILESLPeripheralGATTDatabase.ESLDemoService.cbUUID)
                given(self.peripheralMock.services).willReturn([mockESLDemoService])
                
                self.sut.peripheral(self.peripheralMock, didDiscoverServices: nil)
                
                expect(receivedError).to(beNil())
                expect(observerWasCalled).to(equal(false))
                verify(self.peripheralMock.discoverCharacteristics([SILESLPeripheralGATTDatabase.ESLDemoService.ESLControlPoint.cbUUID, SILESLPeripheralGATTDatabase.ESLDemoService.ESLTransferImage.cbUUID], for: mockESLDemoService)).wasCalled(1)
            }
        }

        describe("peripheral(_:didDiscoverCharacteristicsFor:error:") {
            let expectedError = SILESLPeripheralDelegateError.wrongCharacteristics
            var receivedError: SILESLPeripheralDelegateError? = nil
            var observerWasCalled = false
            let mockESLDemoService = mock(CBService.self)

            beforeEach {
                self.sut.initializationState.asObservable().subscribe(onNext: { error in
                    receivedError = error
                    observerWasCalled = true
                }).disposed(by: self.disposeBag)
                
                given(mockESLDemoService.uuid).willReturn(SILESLPeripheralGATTDatabase.ESLDemoService.cbUUID)
            }
            
            afterEach {
                receivedError = nil
                observerWasCalled = false
                self.disposeBag = DisposeBag()
            }
            
            it("request returns error") {
                self.sut.peripheral(self.peripheralMock, didDiscoverCharacteristicsFor: mockESLDemoService, error: TestError.unknown)
                
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
            
            it("no characteristic found") {
                given(mockESLDemoService.characteristics).willReturn([CBCharacteristic]())
                given(self.peripheralMock.services).willReturn([mockESLDemoService])
                
                self.sut.peripheral(self.peripheralMock, didDiscoverCharacteristicsFor: mockESLDemoService, error: nil)
                
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
            
            it("found characteristics but wrong") {
                let expectedError = SILESLPeripheralDelegateError.missingESLControlPoint
                let mockCharacteristic1 = mock(CBCharacteristic.self)
                given(mockCharacteristic1.uuid).willReturn(CBUUID(string: "1800"))
                let mockCharacteristic2 = mock(CBCharacteristic.self)
                given(mockCharacteristic2.uuid).willReturn(CBUUID(string: "1801"))
                given(mockESLDemoService.characteristics).willReturn([mockCharacteristic1, mockCharacteristic2])
                given(self.peripheralMock.services).willReturn([mockESLDemoService])
                
                self.sut.peripheral(self.peripheralMock, didDiscoverCharacteristicsFor: mockESLDemoService, error: nil)
                
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
            
            it("found characteristics but second wrong") {
                let expectedError = SILESLPeripheralDelegateError.missingESLImageTransfer
                let mockESLControlPoint = mock(CBCharacteristic.self)
                given(mockESLControlPoint.uuid).willReturn(SILESLPeripheralGATTDatabase.ESLDemoService.ESLControlPoint.cbUUID)
                let mockCharacteristic2 = mock(CBCharacteristic.self)
                given(mockCharacteristic2.uuid).willReturn(CBUUID(string: "1801"))
                given(mockESLDemoService.characteristics).willReturn([mockESLControlPoint, mockCharacteristic2])
                given(self.peripheralMock.services).willReturn([mockESLDemoService])
                
                self.sut.peripheral(self.peripheralMock, didDiscoverCharacteristicsFor: mockESLDemoService, error: nil)
                
                verify(self.peripheralMock.setNotifyValue(true, for: mockESLControlPoint)).wasCalled(1)
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
            
            it("found characteristics") {
                let mockESLControlPoint = mock(CBCharacteristic.self)
                given(mockESLControlPoint.uuid).willReturn(SILESLPeripheralGATTDatabase.ESLDemoService.ESLControlPoint.cbUUID)
                let mockESLTransferImage = mock(CBCharacteristic.self)
                given(mockESLTransferImage.uuid).willReturn(SILESLPeripheralGATTDatabase.ESLDemoService.ESLTransferImage.cbUUID)
                given(mockESLDemoService.characteristics).willReturn([mockESLControlPoint, mockESLTransferImage])
                given(self.peripheralMock.services).willReturn([mockESLDemoService])
                
                self.sut.peripheral(self.peripheralMock, didDiscoverCharacteristicsFor: mockESLDemoService, error: nil)
                
                expect(receivedError).to(beNil())
                expect(observerWasCalled).to(equal(true))
                verify(self.peripheralMock.setNotifyValue(true, for: mockESLControlPoint)).wasCalled(1)
                verify(self.peripheralMock.setNotifyValue(true, for: mockESLTransferImage)).wasCalled(1)
            }
        }
        
        describe("peripheral(_:didUpdateNotificationStateFor:error:") {
            let expectedError = SILESLPeripheralDelegateError.notifactionStateUpdateError
            var receivedError: SILESLPeripheralDelegateError? = nil
            var observerWasCalled = false
            let mockESLControlPoint = mock(CBCharacteristic.self)

            beforeEach {
                self.sut = SILESLPeripheralDelegate(peripheral: self.peripheralMock,
                                                    peripheralReferences: SILESLPeripheralGATTReferences())
                self.sut.initializationState.asObservable().subscribe(onNext: { error in
                    receivedError = error
                    observerWasCalled = true
                }).disposed(by: self.disposeBag)
            }
            
            afterEach {
                receivedError = nil
                observerWasCalled = false
                self.disposeBag = DisposeBag()
            }
            
            it("request returns error") {
                self.sut.peripheral(self.peripheralMock, didUpdateNotificationStateFor:mockESLControlPoint, error: TestError.unknown)
                
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
            
            it("should do nothing on update without error") {
                self.sut.peripheral(self.peripheralMock, didUpdateNotificationStateFor:mockESLControlPoint, error: nil)
                
                expect(observerWasCalled).to(equal(false))
            }
        }
        
        describe("checkIfCharacteristicAreNotifying") {
            let expectedError = SILESLPeripheralDelegateError.eslControlPointIsntNotifying
            var receivedError: SILESLPeripheralDelegateError? = nil
            var observerWasCalled = false
            let mockESLControlPoint = mock(CBCharacteristic.self)
            let mockESLImageTransfer = mock(CBCharacteristic.self)

            beforeEach {
                self.sut = SILESLPeripheralDelegate(peripheral: self.peripheralMock,
                                                    peripheralReferences: SILESLPeripheralGATTReferences(eslDemoService: nil, eslControlPoint: mockESLControlPoint, eslTransferImage: mockESLImageTransfer))
                self.sut.notificationState.asObservable().subscribe(onNext: { error in
                    receivedError = error
                    observerWasCalled = true
                }).disposed(by: self.disposeBag)
            }
            
            afterEach {
                receivedError = nil
                observerWasCalled = false
                self.disposeBag = DisposeBag()
            }
            
            it("should return no error") {
                given(mockESLControlPoint.isNotifying).willReturn(true)
                given(mockESLImageTransfer.isNotifying).willReturn(true)
                
                self.sut.checkIfCharacteristicsAreNotifying()
                
                expect(receivedError).to(beNil())
                expect(observerWasCalled).to(equal(true))
            }
            
            it("should return error when elsControlPoint isn't notifying") {
                given(mockESLControlPoint.isNotifying).willReturn(false)
                given(mockESLImageTransfer.isNotifying).willReturn(true)
                
                self.sut.checkIfCharacteristicsAreNotifying()
                
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
            
            it("should return error when elsImqgeTransfer isn't notifying") {
                let expectedError = SILESLPeripheralDelegateError.eslImageTransferIsnNotifying
                given(mockESLControlPoint.isNotifying).willReturn(true)
                given(mockESLImageTransfer.isNotifying).willReturn(false)
                
                self.sut.checkIfCharacteristicsAreNotifying()
                
                expect(receivedError).to(equal(expectedError))
                expect(observerWasCalled).to(equal(true))
            }
        }
    }
}
