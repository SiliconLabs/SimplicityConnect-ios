//
//  SILESLCommandDisplayImageTestSpec.swift
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

class SILESLCommandDisplayImageTestSpec: QuickSpec {
    var sut: SILESLCommandDisplayImage!
    
    override func spec() {
        describe("display_image esl_id") {
            it("should prepare correct data") {
                let id: UInt = 50
                let eslId = SILESLIdAddress.unicast(id: id)
                let imageIndex: UInt = 0
                let displayIndex: UInt = 1
                self.sut = SILESLCommandDisplayImage(eslId: eslId,
                                                     imageIndex: imageIndex,
                                                     displayIndex: displayIndex)
                
                let dataToSend = "display_image \(id) \(imageIndex) \(displayIndex)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
        
        describe("display_image all") {
            it("should prepare correct data") {
                let eslId = SILESLIdAddress.broadcast
                let imageIndex: UInt = 5
                let displayIndex: UInt = 4
                self.sut = SILESLCommandDisplayImage(eslId: eslId,
                                                     imageIndex: imageIndex,
                                                     displayIndex: displayIndex)
                
                let dataToSend = "display_image all \(imageIndex) \(displayIndex)".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
    }
}
