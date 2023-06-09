//
//  SILESLCommandConnectTestSpec.swift
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

class SILESLCommandConnectTestSpec: QuickSpec {
    var address: SILAddress!
    var sut: SILESLCommandConnect!
    
    override func spec() {
        describe("connect bt_addr") {
            it("should prepare data for public address") {
                let btAddress = "8c:f6:81:b8:82:b2"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .public))
                self.sut = SILESLCommandConnect(address: self.address)
                
                let dataToSend = "connect \(btAddress)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare data for public address with passcode") {
                let btAddress = "8c:f6:81:b8:82:b2"
                let passcode = "1234"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .public))
                self.sut = SILESLCommandConnect(address: self.address, passcode: passcode)
                
                let dataToSend = "connect \(btAddress) \(passcode)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare data for static address with passcode") {
                let btAddress = "X"
                let passcode = "1234"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .static))
                self.sut = SILESLCommandConnect(address: self.address, passcode: passcode)
                
                let dataToSend = "connect \(btAddress) static \(passcode)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }

            it("should prepare data for rand_res address") {
                let btAddress = "XXXX"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .rand_res))
                self.sut = SILESLCommandConnect(address: self.address)
                
                let dataToSend = "connect \(btAddress) rand_res".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare data for rand_nonres address") {
                let btAddress = "XXX"
                let passcode = "4321"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .rand_nonres))
                self.sut = SILESLCommandConnect(address: self.address, passcode: passcode)
                
                let dataToSend = "connect \(btAddress) rand_nonres \(passcode)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
        
        describe("connect esl_id") {
            it("should prepare data for esl_id") {
                let eslId = 5
                self.address = SILAddress.eslId(SILESLIdAddress.unicast(id: 5))
                self.sut = SILESLCommandConnect(address: self.address)
                
                let dataToSend = "connect \(eslId)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare data for esl_id with passcode") {
                let eslId = 55
                let passcode = "56789"
                self.address = SILAddress.eslId(SILESLIdAddress.unicast(id: 55))
                self.sut = SILESLCommandConnect(address: self.address, passcode: passcode)
                
                let dataToSend = "connect \(eslId) \(passcode)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
    }
}
