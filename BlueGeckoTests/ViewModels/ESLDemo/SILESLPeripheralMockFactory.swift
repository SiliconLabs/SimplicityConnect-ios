//
//  SILESLPeripheralMockFactory.swift
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

enum TestError: Error {
    case unknown
}

struct SILESLPeripheralMock {
    let eslDemoServiceMock: CBService
    let eslControlPointMock: CBCharacteristic
    let eslImageTransferMock: CBCharacteristic
    let peripheralMock: CBPeripheral
    let peripheralReferencesMock: SILESLPeripheralGATTReferences
}

class SILESLPeripheralMockFactory {
    func getDefault() -> SILESLPeripheralMock {
        let eslDemoServiceMock = mock(CBService.self)
        given(eslDemoServiceMock.uuid).willReturn(SILESLPeripheralGATTDatabase.ESLDemoService.cbUUID)
        let eslControlPointMock = mock(CBCharacteristic.self)
        given(eslControlPointMock.uuid).willReturn(SILESLPeripheralGATTDatabase.ESLDemoService.ESLControlPoint.cbUUID)
        let eslImageTransferMock = mock(CBCharacteristic.self)
        given(eslImageTransferMock.uuid).willReturn(SILESLPeripheralGATTDatabase.ESLDemoService.ESLTransferImage.cbUUID)
        let peripheralMock = mock(CBPeripheral.self)
        given(peripheralMock.services).willReturn([eslDemoServiceMock])
        given(peripheralMock.services?.first?.characteristics).willReturn([eslControlPointMock, eslImageTransferMock])
        let peripheralReferencesMock = SILESLPeripheralGATTReferences(eslDemoService: eslDemoServiceMock,
                                                                      eslControlPoint: eslControlPointMock,
                                                                      eslTransferImage: eslImageTransferMock)
        
        return SILESLPeripheralMock(eslDemoServiceMock: eslDemoServiceMock,
                                    eslControlPointMock: eslControlPointMock,
                                    eslImageTransferMock: eslImageTransferMock,
                                    peripheralMock: peripheralMock,
                                    peripheralReferencesMock: peripheralReferencesMock)
    }
}
