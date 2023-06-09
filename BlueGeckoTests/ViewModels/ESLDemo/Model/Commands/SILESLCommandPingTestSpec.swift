//
//  SILESLCommandPingTestSpec.swift
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

class SILESLCommandPingTestSpec: QuickSpec {
    var sut: SILESLCommandPing!
    
    override func spec() {
        describe("ping") {
            it("should prepare correct data") {
                self.sut = SILESLCommandPing(eslId: .broadcast)
                
                let dataToSend = "ping all".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
    }
}
