//
//  SILGattValueMarkerTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 24.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
import AEXML
import RealmSwift
@testable import BlueGecko

class SILGattValueMarkerTest : QuickSpec {
    private var testObject: SILGattValueMarker!
    private var testedElement: AEXMLElement!
    
    private func containsAttribute(entity: SILGattValueEntity, name: String, value: String) -> Bool {
        return entity.additionalXmlAttributes.contains(where: { attribute in attribute.name == name && attribute.value == value })
    }
    
    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }

        describe("should parse element to desired model entity") {
            it("should return error when xml name is wrong") {
                let attributes = ["length" : "255",
                                  "type": "hex",
                                  "variable_length" : "false"]
                self.testedElement = AEXMLElement(name: "val", value: nil, attributes: attributes)
                self.testedElement.value = "44"
                self.testObject = SILGattValueMarker(element: self.testedElement)
                    
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong xml element name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element with length, type = hex and variable_length = false") {
                let attributes = ["length" : "255",
                                  "type": "hex",
                                  "variable_length" : "false"]
                self.testedElement = AEXMLElement(name: "value", value: nil, attributes: attributes)
                self.testedElement.value = "44"
                self.testObject = SILGattValueMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(1))
                    expect(entity.value).to(equal("44"))
                    expect(entity.valueType).to(equal(.hex))
                    expect(entity.fixedVariableLength).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "value_length", value: "255")).to(equal(true))
                
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with length, type = none and variable_length = true") {
                let attributes = ["type": "user",
                                  "variable_length" : "true"]
                self.testedElement = AEXMLElement(name: "value", value: nil, attributes: attributes)
                self.testedElement.value = "0"
                self.testObject = SILGattValueMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.value).to(equal("0"))
                    expect(entity.valueType).to(equal(SILGattConfigurationValueType.none))
                    expect(entity.fixedVariableLength).to(equal(false))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with type = text") {
                let attributes = ["type": "utf-8"]
                self.testedElement = AEXMLElement(name: "value", value: nil, attributes: attributes)
                self.testedElement.value = "11"
                self.testObject = SILGattValueMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.value).to(equal("11"))
                    expect(entity.valueType).to(equal(SILGattConfigurationValueType.text))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
        }
        
        describe("should fail on parsing marker") {
            it("fail on wrong attribute name") {
                let attributes = ["length" : "255",
                                  "type": "newType",
                                  "variable_length" : "false",
                                  "new_attribute": "true"]
                self.testedElement = AEXMLElement(name: "value", value: nil, attributes: attributes)
                self.testObject = SILGattValueMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Attribute name not allowed")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("fail on wrong value in attribute type") {
                let attributes = ["length" : "255",
                                  "type": "newType",
                                  "variable_length" : "false"]
                self.testedElement = AEXMLElement(name: "value", value: nil, attributes: attributes)
                self.testObject = SILGattValueMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Attribute type value not allowed")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("fail on having any child by element") {
                let attributes = ["length" : "255",
                                  "type": "hex",
                                  "variable_length" : "false"]
                self.testedElement = AEXMLElement(name: "value", value: nil, attributes: attributes)
                self.testedElement.value = "33"
                
                let element = AEXMLElement(name: "child")
                
                self.testedElement.addChild(element)
                self.testObject = SILGattValueMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Marker can't have any children")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("fail when hex value is invalid") {
                let attributes = ["length": "1",
                                  "type": "hex"]
                self.testedElement = AEXMLElement(name: "value", value: "xd", attributes: attributes)
                self.testObject = SILGattValueMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Hex value is invalid")
                
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
    }
}
