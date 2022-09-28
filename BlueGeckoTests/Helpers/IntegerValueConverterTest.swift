//
//  IntegerValueConverterTest.swift
//  BlueGeckoTests
//
//  Created by Hubert Drogosz on 05/08/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import BlueGecko

class IntegerValueConverterTest : QuickSpec {
    override func spec() {
        
        var fieldModel = SILBluetoothFieldModel()
        
        beforeEach {
            fieldModel = SILBluetoothFieldModel()
            fieldModel.invertedBytesOrder = false
            fieldModel.decimalExponent = 0
            fieldModel.multiplier = 1
        }
        
        describe("UInt8") {
            let converter = IntegerValueConverter<UInt8>(resultBitLength: 8)
            
            it("should return correct string for data") {
                let inputData = Data(bytes: [123, 64])
                expect(try? converter.dataToString(inputData, fieldModel: fieldModel).get()) == "123"
            }
            it("should return the same string after stringToData and dataToString") {
                let inputString = "254"
                let result = try? converter.stringToData(inputString, fieldModel: fieldModel)
                    .flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString
            }
        }
        
        describe("Int8") {
            let converter = IntegerValueConverter<Int8>(resultBitLength: 8)
            
            it("should return correct string for data") {
                let inputData = Data(bytes: [254, 64])
                expect(try? converter.dataToString(inputData, fieldModel: fieldModel).get()) == "-2"
            }
            it("should return the same string after stringToData and dataToString") {
                let inputString = "-120"
                let result = try? converter.stringToData(inputString, fieldModel: fieldModel)
                    .flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString
            }
        }
        
        describe("UInt16") {
            let converter = IntegerValueConverter<UInt16>(resultBitLength: 16)
            
            it("should return correct value") {
                fieldModel.decimalExponent = 2
                let inputData = Data(bytes: [0b11010100,0b10101001])
                expect(try? converter.dataToString(inputData, fieldModel: fieldModel).get()) == "4347600"
            }
            
            it("should return correctValue with invertedBytesOrder") {
                fieldModel.invertedBytesOrder = true
                fieldModel.multiplier = -1
                let inputData = Data(bytes: [0b10101001, 0b11010100])
                expect(try? converter.dataToString(inputData, fieldModel: fieldModel).get()) == "-43476"
            }
            
            it("should return the same string after stringToData and dataToString") {
                fieldModel.decimalExponent = 2
                let inputString = "64500"
                let result = try? converter.stringToData(inputString, fieldModel: fieldModel)
                    .flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString
            }
        }
        
        describe("UInt48") {
            let converter = IntegerValueConverter<UInt64>(resultBitLength: 48)
            
            it("should return correct value") {
                let inputData = Data(bytes: withUnsafeBytes(of: 0b101101111010111110011111001110000110110100110110.littleEndian, Array.init))
                expect(try? converter.dataToString(inputData, fieldModel: fieldModel).get()) == "201964918435126"
            }
            
            it("should return correct value with all modifiers") {
                fieldModel.multiplier = 200
                fieldModel.decimalExponent = -2
                fieldModel.invertedBytesOrder = true
                
                let inputData = Data(bytes: withUnsafeBytes(of: 0b101101111010111110011111001110000110110100110110.bigEndian, Array.init))
                expect(try? converter.dataToString(inputData, fieldModel: fieldModel).get()) == "403929836870252"
            }
            
            it("should return the same string after stringToData and dataToString") {
                let inputString = "281 471 509 472 188"
                let result = try? converter.stringToData(inputString, fieldModel: fieldModel)
                    .flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString.replacingOccurrences(of: " ", with: "")
            }
            
            it("should return the same string after stringToData and dataToString with modifiers") {
                fieldModel.multiplier = 30
                fieldModel.decimalExponent = -1
                fieldModel.invertedBytesOrder = true
                
                let inputString = "281 471 509 472 100"
                let halfResult = converter.stringToData(inputString, fieldModel: fieldModel)
                let result = try? halfResult.flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString.replacingOccurrences(of: " ", with: "")
            }
        }
        
        describe("Int48") {
            let converter = IntegerValueConverter<Int64>(resultBitLength: 48)
            
            it("should return correct value") {
                let inputData = Data(bytes: withUnsafeBytes(of: 0b101000110100001101110001010000011101001011001010.littleEndian, Array.init))
                expect(try? converter.dataToString(inputData, fieldModel: fieldModel).get()) == "-101964918435126"
            }
            
            it("should return correct value with all modifiers") {
                fieldModel.multiplier = 200
                fieldModel.decimalExponent = -2
                fieldModel.invertedBytesOrder = true
                
                let inputData = Data(bytes: withUnsafeBytes(of: 0b101000110100001101110001010000011101001011001010.bigEndian, Array.init))
                expect(try? converter.dataToString(inputData, fieldModel: fieldModel).get()) == "-203929836870252"
            }
            
            it("should return the same string after stringToData and dataToString") {
                let inputString = "-10 1 9 6 4 9 1  8 4 3 5 126"
                let result = try? converter.stringToData(inputString, fieldModel: fieldModel)
                    .flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString.replacingOccurrences(of: " ", with: "")
            }
            
            it("should return the same string after stringToData and dataToString with modifiers") {
                fieldModel.multiplier = 30
                fieldModel.decimalExponent = -1
                fieldModel.invertedBytesOrder = true
                
                let inputString = "281 471 509 472 100"
                let halfResult = converter.stringToData(inputString, fieldModel: fieldModel)
                let result = try? halfResult.flatMap({ converter.dataToString($0, fieldModel: fieldModel) })
                    .get()
                
                expect(result) == inputString.replacingOccurrences(of: " ", with: "")
            }
        }
    }
}

