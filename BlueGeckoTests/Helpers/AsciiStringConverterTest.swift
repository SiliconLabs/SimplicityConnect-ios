//
//  AsciiStringConverterTest.swift
//  BlueGeckoTests
//
//  Created by Hubert Drogosz on 29/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import BlueGecko

class AsciiStringConverterTest : QuickSpec {
    override func spec() {
        let fieldModel = SILBluetoothFieldModel()
        let converter = AsciiStringConverter()
        
        it("dataToString should change non-ascii characters to replacement character") {
            let nonAsciiText = "Aąb"
            let d = nonAsciiText.data(using: .utf8)!
            
            expect(try? converter.dataToString(d, fieldModel: fieldModel)
                .get()
                .unicodeScalars.map { $0.value }) == [0x41, 0xFFFD, 0xFFFD, 0x62]
            
        }
        it("stringToData should fail with wrong characters") {
            let nonAsciiText = "Aąb"
            
            expect(try? converter.stringToData(nonAsciiText, fieldModel: fieldModel).get()) == nil
        }
        
        it("should return the same string after stringToData and dataToString") {
            let inputString : String = "Abcdefghijklmn opqrstuwxyz\n"
            
            let result = try! converter.stringToData(inputString, fieldModel: fieldModel)
                .flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                .get()
            
            expect(result) == inputString
        }
    }
}
