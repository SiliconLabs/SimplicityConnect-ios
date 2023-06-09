//
//  SILESLBasicStateResponseTestSpec.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 10.5.2023.
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

class SILESLBasicStateResponseTestSpec: QuickSpec {
    var sut: SILESLBasicStateResponse!
    
    override func spec() {
        describe("init - one case matcher") {
            it("should return serviceNeeded") {
                self.sut = SILESLBasicStateResponse(bits: 1, activeLed: 0)
                
                let description = "The ESL has detected a condition that needs service"
                expect(self.sut.description).to(equal(description))
            }
            
            it("should return synchronized") {
                self.sut = SILESLBasicStateResponse(bits: 2, activeLed: 0)
                
                let description = "The ESL is synchronized to the AP"
                expect(self.sut.description).to(equal(description))
            }
            
            it("should return activeLED") {
                self.sut = SILESLBasicStateResponse(bits: 4, activeLed: 1)
                
                let description = "The ESL has an active LED: index 1"
                expect(self.sut.description).to(equal(description))
            }
            
            it("should return pendingLEDUpdate") {
                self.sut = SILESLBasicStateResponse(bits: 8, activeLed: 0)
                
                let description = "The ESL has a timed LED update pending"
                expect(self.sut.description).to(equal(description))
            }
            
            it("should return pendingDisplayUpdate") {
                self.sut = SILESLBasicStateResponse(bits: 16, activeLed: 0)
                
                let description = "The ESL has a timed display update pending"
                expect(self.sut.description).to(equal(description))
            }
            
            it("should return rfu") {
                self.sut = SILESLBasicStateResponse(bits: 32, activeLed: 0)
                
                let description = "Reserved for Future Use"
                expect(self.sut.description).to(equal(description))
            }
        }
        
        describe("init - more than one case matcher") {
            it("should return serviceNeeded and synchronized") {
                self.sut = SILESLBasicStateResponse(bits: 3, activeLed: 0)
                
                var description = "The ESL has detected a condition that needs service"
                description.append("\nThe ESL is synchronized to the AP")
                expect(self.sut.description).to(equal(description))
            }
            
            it("should return synchronized and activeLED") {
                self.sut = SILESLBasicStateResponse(bits: 6, activeLed: 0)
                
                var description = "The ESL is synchronized to the AP"
                description.append("\nThe ESL has an active LED: index 0")
                expect(self.sut.description).to(equal(description))
            }
            
            it("should return activeLED and serviceNeeded and pendingDisplayUpdate") {
                self.sut = SILESLBasicStateResponse(bits: 21, activeLed: 2)
                
                var description = "The ESL has detected a condition that needs service"
                description.append("\nThe ESL has an active LED: index 2")
                description.append("\nThe ESL has a timed display update pending")
                expect(self.sut.description).to(equal(description))
            }
            
            it("should return pendingLEDUpdate and serviceNeeded and synchronized and pendingDisplayUpdate") {
                self.sut = SILESLBasicStateResponse(bits: 27, activeLed: 0)
                
                var description = "The ESL has detected a condition that needs service"
                description.append("\nThe ESL is synchronized to the AP")
                description.append("\nThe ESL has a timed LED update pending")
                description.append("\nThe ESL has a timed display update pending")
                expect(self.sut.description).to(equal(description))
            }
        }
    }
}
