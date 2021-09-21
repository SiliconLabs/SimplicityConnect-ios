//
//  SILGattProjectMarkerTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 2.8.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
import AEXML
import RealmSwift
@testable import BlueGecko

class SILGattProjectMarkerTest: QuickSpec {
    private var testObject: SILGattProjectMarker!
    private var testedElement: AEXMLElement!
    
    private func containsAttribute(entity: SILGattProjectEntity, name: String, value: String) -> Bool {
        return entity.additionalXmlAttributes.contains(where: { attribute in attribute.name == name && attribute.value == value })
    }

    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }
        describe("should parse element to desired model entity") {
            it("should return error when xml name is wrong") {
                let attributes = ["device": "iOS"]
                self.testedElement = AEXMLElement(name: "element", value: nil, attributes: attributes)
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong xml element name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element without any attributes") {
                self.testedElement = AEXMLElement(name: "project")
                let gatt = AEXMLElement(name: "gatt")
                self.testedElement.addChild(gatt)
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.xmlNodeName).to(equal("project"))
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with attribute") {
                let attributes = ["device": "iOS"]
                self.testedElement = AEXMLElement(name: "project", value: nil, attributes: attributes)
                let gatt = AEXMLElement(name: "gatt")
                self.testedElement.addChild(gatt)
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.xmlNodeName).to(equal("project"))
                    expect(entity.additionalXmlAttributes.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(self.containsAttribute(entity: entity, name: "device", value: "iOS")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed attributes") {
                let attributes = ["device": "iOS",
                                  "brand": "Apple"]
                self.testedElement = AEXMLElement(name: "project", value: nil, attributes: attributes)
                let gatt = AEXMLElement(name: "gatt")
                self.testedElement.addChild(gatt)
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Element contains not allowed attributes")
          
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed children element") {
                self.testedElement = AEXMLElement(name: "project")
                let gatt = AEXMLElement(name: "gatt")
                let service = AEXMLElement(name: "service")
                self.testedElement.addChildren([gatt, service])
                
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed children element")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing too many gatt children") {
                self.testedElement = AEXMLElement(name: "project")
                let gatt = AEXMLElement(name: "gatt")
                let gatt2 = AEXMLElement(name: "gatt")
                self.testedElement.addChildren([gatt, gatt2])
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many <gatt> children")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should parse marker with gatt children") {
                self.testedElement = AEXMLElement(name: "project")
                let gatt = AEXMLElement(name: "gatt")
                self.testedElement.addChild(gatt)
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(projectEntity):
                    expect(projectEntity.xmlNodeName).to(equal("project"))
                    expect(projectEntity.additionalXmlChildren.count).to(equal(0))
                    expect(projectEntity.additionalXmlAttributes.count).to(equal(0))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should parse marker with gatt children and attribute") {
                self.testedElement = AEXMLElement(name: "project", attributes: ["device": "Android"])
                let gatt = AEXMLElement(name: "gatt")
                self.testedElement.addChild(gatt)
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(projectEntity):
                    expect(projectEntity.xmlNodeName).to(equal("project"))
                    expect(projectEntity.additionalXmlChildren.count).to(equal(0))
                    expect(projectEntity.additionalXmlAttributes.count).to(equal(1))
                    expect(self.containsAttribute(entity: projectEntity, name: "device", value: "Android")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error when gatt marker is missing") {
                self.testedElement = AEXMLElement(name: "project", attributes: ["device": "Android"])
                self.testObject = SILGattProjectMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("<gatt> marker is missing")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
    }
}

