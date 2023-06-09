//
//  SILESLCommandImageUpdateTestSpec.swift
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

class SILESLCommandImageUpdateTestSpec: QuickSpec {
    var sut: SILESLCommandImageUpdate!
    
    override func spec() {
        describe("image_update") {
            it("should prepare correct data") {
                let imageIndex: UInt = 1
                let imageFile = URL(string: "../apple.png")
                self.sut = SILESLCommandImageUpdate(imageIndex: imageIndex, imageFile: imageFile!)
                
                let dataToSend = "image_update 1 a.png".bytes
                
                expect(self.sut.dataToSend).to(equal(dataToSend))
            }
        }
    }
}
