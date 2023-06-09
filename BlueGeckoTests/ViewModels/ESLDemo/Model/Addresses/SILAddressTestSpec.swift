//
//  SILAddressTestSpec.swift
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

class SILAddressTestSpec: QuickSpec {
    var sut: SILAddress!
    
    override func spec() {
        describe("init") {
            it("should init with esl unicast") {
                self.sut = SILAddress(rawValue: "12")
                expect(self.sut == .eslId(.unicast(id: 12))).to(beTrue())
            }
            
            it("should init with esl all") {
                self.sut = SILAddress(rawValue: "all")
                expect(self.sut == .eslId(.broadcast)).to(beTrue())
            }
            
            it("should init with btAddress") {
                let address = "00:01:02:03:04:05"
                self.sut = SILAddress(rawValue: address)
                expect(self.sut == .btAddress(SILBluetoothAddress(address: address, addressType: .public))).to(beTrue())
            }
        }
        
        describe("rawValue") {
            it("should print esl unicast") {
                self.sut = SILAddress.eslId(.unicast(id: 10))
                expect(self.sut.rawValue == "10").to(beTrue())
            }
            
            it("should print esl all") {
                self.sut = SILAddress.eslId(.broadcast)
                expect(self.sut.rawValue == "all").to(beTrue())
            }
            
            it("should print btAddress") {
                let address = "00:01:02:03:04:05"
                let btAddress = SILBluetoothAddress(address: address, addressType: .public)
                self.sut = SILAddress.btAddress(btAddress)
                expect(self.sut.rawValue == address).to(beTrue())
            }
        }
    }
}
