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
                let qrData = self.sut.readQR(metadata: "connect \(address)")
                
                expect(qrData).notTo(beNil())
                expect(qrData?.bluetoothAddress.addressType).to(equal(.public))
                expect(qrData?.bluetoothAddress.address).to(equal(address))
                expect(qrData?.passcode).to(beNil())
            }
            
            it("should read correct three words") {
                let address = "00:01:02:03:04:05"
                let qrData = self.sut.readQR(metadata: "connect \(address) static")
                
                expect(qrData).notTo(beNil())
                expect(qrData?.bluetoothAddress.addressType).to(equal(.static))
                expect(qrData?.bluetoothAddress.address).to(equal(address))
                expect(qrData?.passcode).to(beNil())
            }
            
            it("should read correct four words") {
                let address = "00:01:02:03:04:05"
                let passcode = "1234"
                let qrData = self.sut.readQR(metadata: "connect \(address) rand_nonres \(passcode)")
                
                expect(qrData).notTo(beNil())
                expect(qrData?.bluetoothAddress.addressType).to(equal(.rand_nonres))
                expect(qrData?.bluetoothAddress.address).to(equal(address))
                expect(qrData?.passcode).to(equal(passcode))
            }
        }
        
        describe("readQR - incorrect") {
            it("return nil - words.count = 1") {
                let qrData = self.sut.readQR(metadata: "connect")
                
                expect(qrData).to(beNil())
            }
            
            it("return nil - words.count = 5") {
                let qrData = self.sut.readQR(metadata: "connect a b c d")
                
                expect(qrData).to(beNil())
            }
            
            it("return nil - words[0] != connect") {
                let qrData = self.sut.readQR(metadata: "connected 11:12:13:14:15:16")
                
                expect(qrData).to(beNil())
            }
            
            it("return nil - words[1].isValid = false") {
                let qrData = self.sut.readQR(metadata: "connect 100:12:13:14:15:16")
                
                expect(qrData).to(beNil())
            }
            
            it("return nil - words[2] invalid type") {
                let qrData = self.sut.readQR(metadata: "connect 11:12:13:14:15:16 nonpublic")
                
                expect(qrData).to(beNil())
            }
        }
    }
}
