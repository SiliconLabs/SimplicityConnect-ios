//
//  SILESLCommandLedTestSpec.swift
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

class SILESLCommandLedTestSpec: QuickSpec {
    var sut: SILESLCommandLed!

    override func spec() {
        describe("led on") {
            it("should prepare correct data for esl_id") {
                let ledState = SILESLLedState.on
                let id: UInt = 10
                let address = SILESLIdAddress.unicast(id: id)
                let index: UInt = 5
                
                self.sut = SILESLCommandLed(ledState: ledState, address: address, index: index)
                
                let dataToSend = "led on \(id) index=\(index)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare correct data for all") {
                let ledState = SILESLLedState.on
                let address = SILESLIdAddress.broadcast
                let index: UInt = 4
                
                self.sut = SILESLCommandLed(ledState: ledState, address: address, index: index)
                
                let dataToSend = "led on all index=\(index)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
        
        describe("led off") {
            it("should prepare correct data for esl_id") {
                let ledState = SILESLLedState.off
                let id: UInt = 12
                let address = SILESLIdAddress.unicast(id: id)
                let index: UInt = 3
                
                self.sut = SILESLCommandLed(ledState: ledState, address: address, index: index)
                
                let dataToSend = "led off \(id) index=\(index)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
            
            it("should prepare correct data for all") {
                let ledState = SILESLLedState.off
                let address = SILESLIdAddress.broadcast
                let index: UInt = 2
                
                self.sut = SILESLCommandLed(ledState: ledState, address: address, index: index)
                
                let dataToSend = "led off all index=\(index)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
    }
}
