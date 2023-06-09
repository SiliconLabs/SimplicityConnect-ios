//
//  SILESLCommandListTestSpec.swift
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

class SILESLCommandListTestSpec: QuickSpec {
    var sut: SILESLCommandList!
    
    override func spec() {
        describe("list s") {
            it("should prepare correct data") {
                self.sut = SILESLCommandList()
                
                let dataToSend = "list s".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
    }
}
