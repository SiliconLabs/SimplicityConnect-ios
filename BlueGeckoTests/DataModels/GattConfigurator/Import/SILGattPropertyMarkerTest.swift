//
//  SILGattPropertyMarkerTest.swift
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

class SILGattPropertyMarkerTest: QuickSpec {
    private var testObject: SILGattPropertyMarker!
    private var testedElement: AEXMLElement!
    
    private func containsAttribute(entity: SILGattPropertyEntity, name: String, value: String) -> Bool {
        return entity.additionalXmlAttributes.contains(where: { attribute in attribute.name == name && attribute.value == value })
    }

    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }
        
        describe("should parse element to desired model entity") {
            it("import element with authenticated = false, bonded = false, encrypted = false for read marker") {
                let attributes = ["authenticated": "false",
                                  "bonded": "false",
                                  "encrypted": "false"]
                self.testedElement = AEXMLElement(name: "read", value: nil, attributes: attributes)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.isBonded).to(equal(false))
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(self.containsAttribute(entity: entity, name: "read_authenticated", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "read_encrypted", value: "false")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with authenticated = true, bonded = false, encrypted = false for write marker") {
                let attributes = ["authenticated": "true",
                                  "bonded": "false",
                                  "encrypted": "false"]
                self.testedElement = AEXMLElement(name: "write", value: nil, attributes: attributes)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.isBonded).to(equal(false))
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(self.containsAttribute(entity: entity, name: "write_authenticated", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "write_encrypted", value: "false")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with authenticated = false, bonded = true, encrypted = false for write_no_response marker") {
                let attributes = ["authenticated": "false",
                                  "bonded": "true",
                                  "encrypted": "false"]
                self.testedElement = AEXMLElement(name: "write_no_response", value: nil, attributes: attributes)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.isBonded).to(equal(true))
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(self.containsAttribute(entity: entity, name: "write_no_response_authenticated", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "write_no_response_encrypted", value: "false")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with authenticated = false, bonded = true, encrypted = true for indicate marker") {
                let attributes = ["authenticated": "false",
                                  "bonded": "true",
                                  "encrypted": "true"]
                self.testedElement = AEXMLElement(name: "indicate", value: nil, attributes: attributes)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.isBonded).to(equal(true))
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(self.containsAttribute(entity: entity, name: "indicate_authenticated", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "indicate_encrypted", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with authenticated = true, bonded = true, encrypted = true for notify marker") {
                let attributes = ["authenticated": "true",
                                  "bonded": "true",
                                  "encrypted": "true"]
                self.testedElement = AEXMLElement(name: "notify", value: nil, attributes: attributes)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.isBonded).to(equal(true))
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(self.containsAttribute(entity: entity, name: "notify_authenticated", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "notify_encrypted", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
        }
        
        describe("should fail on parsing marker") {
            it("fail on wrong marker name (especially not supported reliable_write)") {
                let attributes = ["authenticated": "true",
                                  "bonded": "true",
                                  "encrypted": "true"]
                self.testedElement = AEXMLElement(name: "reliable_write", value: nil, attributes: attributes)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Marker name not allowed")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("fail on wrong attribute name") {
                let attributes = ["authenticated": "true",
                                  "bonded": "true",
                                  "encrypted": "true",
                                  "name": "test"]
                self.testedElement = AEXMLElement(name: "read", value: nil, attributes: attributes)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Attribute name not allowed")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("fail on having any child by element") {
                let attributes = ["authenticated": "true",
                                  "bonded": "true",
                                  "encrypted": "true"]
                self.testedElement = AEXMLElement(name: "read", value: nil, attributes: attributes)
                
                let element = AEXMLElement(name: "child")
                
                self.testedElement.addChild(element)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Marker can't have any children")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when attribute value is wrong") {
                let attributes = ["authenticated": "tak",
                                  "bonded": "true",
                                  "encrypted": "true"]
                self.testedElement = AEXMLElement(name: "read", value: nil, attributes: attributes)
                
                let element = AEXMLElement(name: "child")
                
                self.testedElement.addChild(element)
                self.testObject = SILGattPropertyMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Attribute value is wrong")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
    }
}
