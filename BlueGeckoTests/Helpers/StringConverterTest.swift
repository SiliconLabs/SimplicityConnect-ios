//
//  StringConverterTest.swift
//  BlueGeckoTests
//
//  Created by Hubert Drogosz on 29/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import BlueGecko

class StringConverterTest : QuickSpec {
    override func spec() {
        let inputString : String = "Aąbcćdefghijklmn opqrstuwxyz\n 안녕"
        
        describe("UTF-8") {
            let fieldModel = SILBluetoothFieldModel()
            fieldModel.format = "utf8s"
            let converter = StringConverter(encoding: .utf8)
            
            it("should return the same string after stringToData and dataToString") {
                let result = try! converter.stringToData(inputString, fieldModel: fieldModel)
                    .flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString
            }
        }
        
        describe("UTF-16") {
            let fieldModel = SILBluetoothFieldModel()
            fieldModel.format = "utf16s"
            let converter = StringConverter(encoding: .utf16)
            
            it("should return the same string after stringToData and dataToString") {
                let result = try! converter.stringToData(inputString, fieldModel: fieldModel)
                    .flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString
            }
        }
    }
}

