//
//  QRScannerViewModelTestSpec.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 28.3.2023.
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

class QRScannerViewModelTestSpec: QuickSpec {
    var sut: QRScannerViewModel!

    override func spec() {
        beforeEach {
            self.sut = QRScannerViewModel()
        }
        
        describe("readQR - correct") {
            it("should read correct two words") {
                let address = "00:01:02:03:04:05"
                let full = "connect \(address)"
                let qrData = self.sut.readQR(metadata: full)
                
                expect(qrData).notTo(beNil())
                expect(qrData?.bluetoothAddress.addressType).to(equal(.public))
                expect(qrData?.bluetoothAddress.address).to(equal(address))
                expect(qrData?.rawData).to(equal(full.bytes))
            }
            
            it("should read correct with more characters") {
                let address = "00:01:02:03:04:05"
                let full = "abc dconnect \(address) static"
                let qrData = self.sut.readQR(metadata: full)
                
                expect(qrData).notTo(beNil())
                expect(qrData?.bluetoothAddress.addressType).to(equal(.public))
                expect(qrData?.bluetoothAddress.address).to(equal(address))
                expect(qrData?.rawData).to(equal(full.bytes))
            }
        }
        
        describe("readQR - incorrect") {
            it("return nil - missing btAddress") {
                let qrData = self.sut.readQR(metadata: "connect a b c d")
                
                expect(qrData).to(beNil())
            }
            
            it("return nil - btAddress wrong") {
                let qrData = self.sut.readQR(metadata: "connect 100:12:13:14:15:16")
                
                expect(qrData).to(beNil())
            }
        }
    }
}
