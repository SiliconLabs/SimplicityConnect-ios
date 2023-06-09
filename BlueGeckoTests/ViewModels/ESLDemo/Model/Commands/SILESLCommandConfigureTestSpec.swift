//
//  SILESLCommandConfigureTestSpec.swift
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

class SILESLCommandConfigureTestSpec: QuickSpec {
    var sut: SILESLCommandConfigure!
    
    override func spec() {
        describe("config full") {
            it("should prepare correct data") {
                self.sut = SILESLCommandConfigure()
                
                let dataToSend = "config full".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
    }
}
