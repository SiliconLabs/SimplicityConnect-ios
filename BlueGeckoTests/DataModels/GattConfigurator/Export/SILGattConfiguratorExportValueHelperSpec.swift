//
//  SILGattConfiguratorExportValueHelperSpec.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 22/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@testable import BlueGecko

import Foundation
import Quick
import Nimble
import RealmSwift
import AEXML

class SILGattConfiguratorExportValueHelperSpec: QuickSpec {
    
    override func spec() {
        let falseString = SILGattConfiguratorXmlDatabase.falseString
        let trueString = SILGattConfiguratorXmlDatabase.trueString
        
        context("SILGattConfiguratorExportValueHelper") {
            var helper: SILGattConfiguratorExportValueHelper!
            
            let lengthAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.lengthAttribute
            let variableLengthAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.variableLengthAttribute
            let typeAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.typeAttribute
            
            let hexTypeString = SILGattConfiguratorXmlDatabase.GattConfigurationValue.hexTypeString
            let textTypeString = SILGattConfiguratorXmlDatabase.GattConfigurationValue.textTypeString
            
            describe("not imported SILGattConfigurationDescriptorEntity and text initial value") {
                var descriptor: SILGattConfigurationDescriptorEntity!
                var xmlElementResult: AEXMLElement?
                let initialValue = "initial value"
                
                beforeEach {
                    descriptor = SILGattConfigurationDescriptorEntity()
                    descriptor.initialValueType = .text
                    descriptor.initialValue = initialValue
                    helper = SILGattConfiguratorExportValueHelper(node: descriptor, initialValueType: descriptor.initialValueType, initialValue: descriptor.initialValue, fixedVariableLength: false, length: "5")
                    xmlElementResult = helper.export()
                }
                
                it("should return proper format when type and value set") {
                    expect(xmlElementResult).notTo(beNil())
                    expect(xmlElementResult!.xml).to(equal("<value length=\"\(initialValue.utf8.count)\" type=\"utf-8\" variable_length=\"true\">\(initialValue)</value>"))
                }
                
                it("should have 3 attributes and none child") {
                    expect(xmlElementResult?.children).to(beEmpty())
                    expect(xmlElementResult?.attributes.count).to(equal(3))
                }
                
                it("should have length attribute set with initial value length") {
                    expect(xmlElementResult!.attributes[lengthAttribute.name]).to(equal("\(initialValue.utf8.count)"))
                }
                it("should have variable_length attribute set as true") {
                    expect(xmlElementResult!.attributes[variableLengthAttribute.name]).to(equal(trueString))
                }
                
                it("should have type attribute set as utf-8") {
                    expect(xmlElementResult!.attributes[typeAttribute.name]).to(equal(textTypeString))
                }
            }
                
            describe("not imported SILGattConfigurationDescriptorEntity nil returns") {
                var descriptor: SILGattConfigurationDescriptorEntity!
                
                beforeEach {
                    descriptor = SILGattConfigurationDescriptorEntity()
                }
                
                it("should return nil when type is none") {
                    descriptor.initialValueType = .none
                    helper = SILGattConfiguratorExportValueHelper(node: descriptor, initialValueType: descriptor.initialValueType, initialValue: descriptor.initialValue, fixedVariableLength: false, length: "5")
                    expect(helper.export()).to(beNil())
                }
                
                it("should return nil when value is longer than 255 bytes for text") {
                    let initialValue = String((0..<256).map { _ in "abcdefg".randomElement()! })
                    descriptor.initialValueType = .text
                    descriptor.initialValue = initialValue
                    helper = SILGattConfiguratorExportValueHelper(node: descriptor, initialValueType: descriptor.initialValueType, initialValue: descriptor.initialValue, fixedVariableLength: false, length: "5")
                    expect(helper.export()).to(beNil())
                }
                
                it("should return nil when value is longer than 255 bytes for hex") {
                    let initialValue = String((0..<520).map { _ in "0123456789abcdef".randomElement()! })
                    descriptor.initialValueType = .hex
                    descriptor.initialValue = initialValue
                    helper = SILGattConfiguratorExportValueHelper(node: descriptor, initialValueType: descriptor.initialValueType, initialValue: descriptor.initialValue, fixedVariableLength: false, length: "5")
                    expect(helper.export()).to(beNil())
                }
            }
            
            describe("imported SILGattConfigurationCharacteristicEntity") {
                var characteristic: SILGattConfigurationCharacteristicEntity!
                var xmlElementResult: AEXMLElement?
                
                beforeEach {
                    characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.initialValueType = .none
                    helper = SILGattConfiguratorExportValueHelper(node: characteristic, initialValueType: characteristic.initialValueType, initialValue: characteristic.initialValue, fixedVariableLength: true, length: "5")
                    xmlElementResult = helper.export()
                }
                
                it("should return proper format when imported value") {
                    expect(xmlElementResult).to(beNil())
                }
                
                context("after setting hex value") {
                    let initialValue = "ababcdcd"
                    
                    beforeEach {
                        characteristic.initialValueType = .hex
                        characteristic.initialValue = initialValue
                        helper = SILGattConfiguratorExportValueHelper(node: characteristic, initialValueType: characteristic.initialValueType, initialValue: characteristic.initialValue, fixedVariableLength: true, length: "4")
                        xmlElementResult = helper.export()
                    }
                    
                    it("should have 3 attributes and none child") {
                        expect(xmlElementResult?.children).to(beEmpty())
                        expect(xmlElementResult?.attributes.count).to(equal(3))
                    }
                    
                    it("should have length attribute set with initial value length in bytes") {
                        expect(xmlElementResult!.attributes[lengthAttribute.name]).to(equal("\(initialValue.count / 2)"))
                    }
                    
                    it("should have type attribute set as hex") {
                        expect(xmlElementResult!.attributes[typeAttribute.name]).to(equal(hexTypeString))
                    }
                }
            }
            
            describe("export configuration depends on variable_length value") {
                var characteristic: SILGattConfigurationCharacteristicEntity!
                var xmlElementResult: AEXMLElement?
                
                afterEach {
                    characteristic = nil
                    xmlElementResult = nil
                }
                
                it("should update length when fixedVariableLength = true") {
                    characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.initialValueType = .text
                    characteristic.initialValue = "aaaaaaaaaaaa"
                    helper = SILGattConfiguratorExportValueHelper(node: characteristic, initialValueType: characteristic.initialValueType, initialValue: characteristic.initialValue, fixedVariableLength: true, length: "3")
                    xmlElementResult = helper.export()
                    
                    expect(xmlElementResult?.children).to(beEmpty())
                    expect(xmlElementResult?.attributes.count).to(equal(3))
                    expect(xmlElementResult!.attributes[lengthAttribute.name]).to(equal("12"))
                    expect(xmlElementResult!.attributes[typeAttribute.name]).to(equal(textTypeString))
                    expect(xmlElementResult!.attributes["variable_length"]).to(equal(falseString))
                }
                
                it("should use length from attribute when fixedVariableLength = true") {
                    characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.initialValueType = .text
                    characteristic.initialValue = "a"
                    helper = SILGattConfiguratorExportValueHelper(node: characteristic, initialValueType: characteristic.initialValueType, initialValue: characteristic.initialValue, fixedVariableLength: true, length: "3")
                    xmlElementResult = helper.export()
                    
                    expect(xmlElementResult?.children).to(beEmpty())
                    expect(xmlElementResult?.attributes.count).to(equal(3))
                    expect(xmlElementResult!.attributes[lengthAttribute.name]).to(equal("3"))
                    expect(xmlElementResult!.attributes[typeAttribute.name]).to(equal(textTypeString))
                    expect(xmlElementResult!.attributes["variable_length"]).to(equal(falseString))
                }
                
                it("should calculate length when length is nil") {
                    characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.initialValueType = .text
                    characteristic.initialValue = "a"
                    helper = SILGattConfiguratorExportValueHelper(node: characteristic, initialValueType: characteristic.initialValueType, initialValue: characteristic.initialValue, fixedVariableLength: false, length: "")
                    xmlElementResult = helper.export()
                    
                    expect(xmlElementResult?.children).to(beEmpty())
                    expect(xmlElementResult?.attributes.count).to(equal(3))
                    expect(xmlElementResult!.attributes[lengthAttribute.name]).to(equal("1"))
                    expect(xmlElementResult!.attributes[typeAttribute.name]).to(equal(textTypeString))
                    expect(xmlElementResult!.attributes["variable_length"]).to(equal(trueString))
                }
                
                it("should use length from attribute when length is not nil") {
                    characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.initialValueType = .text
                    characteristic.initialValue = "a"
                    helper = SILGattConfiguratorExportValueHelper(node: characteristic, initialValueType: characteristic.initialValueType, initialValue: characteristic.initialValue, fixedVariableLength: false, length: "255")
                    xmlElementResult = helper.export()
                    
                    expect(xmlElementResult?.children).to(beEmpty())
                    expect(xmlElementResult?.attributes.count).to(equal(3))
                    expect(xmlElementResult!.attributes[lengthAttribute.name]).to(equal("255"))
                    expect(xmlElementResult!.attributes[typeAttribute.name]).to(equal(textTypeString))
                    expect(xmlElementResult!.attributes["variable_length"]).to(equal(trueString))
                }
            }
        }
    }
}
