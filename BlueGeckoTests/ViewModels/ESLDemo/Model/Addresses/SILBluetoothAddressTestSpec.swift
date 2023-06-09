//
//  SILBluetoothAddressTestSpec.swift
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

class SILBluetoothAddressTestSpec: QuickSpec {
    var sut: SILBluetoothAddress!

    
    override func spec() {
        describe("public address") {
            it("should be valid address") {
                let address = "8c:f6:81:b8:82:b2"
                self.sut = SILBluetoothAddress(address: address, addressType: .public)
                
                expect(self.sut.address).to(equal(address))
                expect(self.sut.addressType).to(equal(.public))
                expect(self.sut.isValid).to(beTrue())
            }
            
            it("should be invalid address - too long") {
                let address = "8c:f6:81:b8:82:b2:"
                self.sut = SILBluetoothAddress(address: address, addressType: .public)
                
                expect(self.sut.address).to(equal(address))
                expect(self.sut.addressType).to(equal(.public))
                expect(self.sut.isValid).to(beFalse())
            }
            
            it("should be invalid address - wrong format :") {
                let address = "8c:f6:81:b8:82::2"
                self.sut = SILBluetoothAddress(address: address, addressType: .public)
                
                expect(self.sut.address).to(equal(address))
                expect(self.sut.addressType).to(equal(.public))
                expect(self.sut.isValid).to(beFalse())
            }
            
            it("should be invalid address - wrong format non hex") {
                let address = "8c:f6:r1:b8:82:b2"
                self.sut = SILBluetoothAddress(address: address, addressType: .public)
                
                expect(self.sut.address).to(equal(address))
                expect(self.sut.addressType).to(equal(.public))
                expect(self.sut.isValid).to(beFalse())
            }
            
            it("should be invalid address - wrong format places") {
                let address = "8:cf:6b:1b:88:2b2"
                self.sut = SILBluetoothAddress(address: address, addressType: .public)
                
                expect(self.sut.address).to(equal(address))
                expect(self.sut.addressType).to(equal(.public))
                expect(self.sut.isValid).to(beFalse())
            }
        }
        
        describe("non-public address") {
            it("isValid for static address") {
                self.sut = SILBluetoothAddress(address: "", addressType: .static)
                
                expect(self.sut.address).to(equal(""))
                expect(self.sut.addressType).to(equal(.static))
                expect(self.sut.isValid).to(beTrue())
            }
            
            it("isValid for rand_res address") {
                self.sut = SILBluetoothAddress(address: "", addressType: .rand_res)
                
                expect(self.sut.address).to(equal(""))
                expect(self.sut.addressType).to(equal(.rand_res))
                expect(self.sut.isValid).to(beTrue())
            }
            
            it("isValid for rand_nonres address") {
                self.sut = SILBluetoothAddress(address: "", addressType: .rand_nonres)
                
                expect(self.sut.address).to(equal(""))
                expect(self.sut.addressType).to(equal(.rand_nonres))
                expect(self.sut.isValid).to(beTrue())
            }
        }
    }
}
