//
//  SILESLCommandDisconnectTestSpec.swift
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

class SILESLCommandDisconnectTestSpec: QuickSpec {
    var sut: SILESLCommandDisconnect!
    var address: SILAddress!
    
    override func spec() {
        describe("disconnect bt_addr") {
            it("should prepare data for disconnect without address") {
                self.sut = SILESLCommandDisconnect()
                
                let dataToSend = "disconnect".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare data for public address") {
                let btAddress = "8c:f6:81:b8:82:b2"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .public))
                self.sut = SILESLCommandDisconnect(address: self.address)
                
                let dataToSend = "disconnect \(btAddress)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare data for static address") {
                let btAddress = "X"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .static))
                self.sut = SILESLCommandDisconnect(address: self.address)
                
                let dataToSend = "disconnect \(btAddress)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }

            it("should prepare data for rand_res address") {
                let btAddress = "XXXX"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .rand_res))
                self.sut = SILESLCommandDisconnect(address: self.address)
                
                let dataToSend = "disconnect \(btAddress)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare data for rand_nonres address") {
                let btAddress = "XXX"
                self.address = SILAddress.btAddress(SILBluetoothAddress(address: btAddress, addressType: .rand_nonres))
                self.sut = SILESLCommandDisconnect(address: self.address)
                
                let dataToSend = "disconnect \(btAddress)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
        
        describe("disconnect esl_id") {
            it("should prepare data for esl_id") {
                let eslId = 7
                self.address = SILAddress.eslId(SILESLIdAddress.unicast(id: 7))
                self.sut = SILESLCommandDisconnect(address: self.address)
                
                let dataToSend = "disconnect \(eslId)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
    }
}
