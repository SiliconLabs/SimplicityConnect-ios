//
//  SILESLIdAddressTestSpec.swift
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

class SILESLIdAddressTestSpec: QuickSpec {
    var sut: SILESLIdAddress!

    
    override func spec() {
        describe("broadcast") {
            it("should return correct raw value") {
                self.sut = SILESLIdAddress.broadcast
                
                expect(self.sut.rawValue).to(equal("all"))
            }
            
            it("should return correct case based on init") {
                self.sut = SILESLIdAddress(rawValue: "all")
                
                expect(self.sut == .broadcast).to(beTrue())
            }
        }
        
        describe("unicast") {
            it("should return correct raw value") {
                self.sut = SILESLIdAddress.unicast(id: 5)
                
                expect(self.sut.rawValue).to(equal("5"))
            }
            
            it("should return correct case based on init") {
                self.sut = SILESLIdAddress(rawValue: "10")
                
                expect(self.sut == .unicast(id: 10)).to(beTrue())
            }
            
            it("should return nil") {
                self.sut = SILESLIdAddress(rawValue: "-10")
                
                expect(self.sut).to(beNil())
            }
        }
    }
}
