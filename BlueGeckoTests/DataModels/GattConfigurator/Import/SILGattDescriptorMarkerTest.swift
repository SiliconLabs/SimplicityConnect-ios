//
//  SILGattDescriptorMarkerTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 28.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
import AEXML
import RealmSwift
@testable import BlueGecko

class SILGattDescriptorMarkerTest: QuickSpec {
    private var testObject: SILGattDescriptorMarker!
    private var testedElement: AEXMLElement!
    private var gattAssignedRepository = SILGattAssignedNumbersRepository()
    
    private func containsAttribute(entity: SILGattConfigurationDescriptorEntity, name: String, value: String) -> Bool {
        return entity.additionalXmlAttributes.contains(where: { attribute in attribute.name == name && attribute.value == value })
    }
    
    private func containsChild(entity: SILGattConfigurationDescriptorEntity, name: String) -> Bool {
        return entity.additionalXmlChildren.contains(where: { child in child.name == name })
    }
    
    private func constainsProperty(entity: SILGattConfigurationDescriptorEntity, type: SILGattConfigurationPropertyType, permission: SILGattConfigurationAttributePermission) -> Bool {
        return entity.properties.contains(where: { property in property.type == type && property.permission == permission })
    }
    
    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }
        
        describe("should parse element to desired model entity - without children") {
            it("should return error when xml name is wrong") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor"]
                self.testedElement = AEXMLElement(name: "element", value: nil, attributes: attributes)
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong xml element name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid is wrong (16 bit)") {
                let attributes = ["uuid" : "180 "]
                self.testedElement = AEXMLElement(name: "descriptor", value: nil, attributes: attributes)
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong UUID!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid is wrong (128 bit)") {
                let attributes = ["uuid" : "16b90591-c54a- e7c9-413e-a82748a1e783"]
                self.testedElement = AEXMLElement(name: "descriptor", value: nil, attributes: attributes)
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong UUID!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid attribute is missing") {
                let attributes = ["name": "First desciptor"]
                self.testedElement = AEXMLElement(name: "descriptor", value: nil, attributes: attributes)
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Uuid attribute is missing!")
                
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element with allowed attributes (descirptor not named)") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",
                                  "name": "First descriptor",
                                  "const": "true",
                                  "discoverable": "true",
                                  "instance_id": "gatt_id"]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                self.testedElement.addChild(properties)
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("First descriptor"))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.canBeModified).to(equal(false))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "descriptor")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "discoverable", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "instance_id", value: "gatt_id")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed attribute") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",
                                  "attribute": "true"]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed value for const") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",
                                  "const": "tak"]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed value for const")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed value for discoverable") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",
                                  "discoverable": "nie"]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed value for discoverable")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element and allow modifying a descriptor") {
                let attributes = ["uuid": "2901",
                                  "id": "descriptor",
                                  "sourceId": "gatt"]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2901"))
                    expect(entity.name).to(equal("Characteristic User Description"))
                    expect(entity.properties.count).to(equal(0))
                    expect(entity.canBeModified).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "descriptor")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt")).to(equal(true))
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
        
        describe("should parse element to desired model entity - with children") {
            it("import element with children") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "utf-8"])
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                let informativeText = AEXMLElement(name: "informativeText")
                
                self.testedElement.addChildren([value, properties, informativeText])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Unknown Descriptor"))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.initialValue).to(equal("44"))
                    expect(entity.canBeModified).to(equal(false))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "descriptor")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "informativeText")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("return error when value returns error") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "new"])
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                let informativeText = AEXMLElement(name: "informativeText")
                
                self.testedElement.addChildren([value, properties, informativeText])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Value marker returns error")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when properties returns error") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "hex"])
                let properties = AEXMLElement(name: "properties", attributes: ["read_value": "true"])
                let informativeText = AEXMLElement(name: "informativeText")
                
                self.testedElement.addChildren([value, properties, informativeText])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Properties marker returns error")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when too many informative text markers") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "hex"])
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                let informativeText = AEXMLElement(name: "informativeText")
                let informativeText2 = AEXMLElement(name: "informativeText")
                
                self.testedElement.addChildren([value, properties, informativeText, informativeText2])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many informativeText markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when too many properties markers") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "hex"])
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                let properties2 = AEXMLElement(name: "properties", attributes: ["write": "true"])
                
                self.testedElement.addChildren([value, properties, properties2])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many properties markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when too many value markers") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "hex"])
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                let value2 = AEXMLElement(name: "value", value: "33", attributes: ["type": "hex"])
                
                self.testedElement.addChildren([value, properties, value2])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many value markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when importing not-allowed properties") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                let properties = AEXMLElement(name: "properties",  attributes: ["reliable_write": "true"])
                self.testedElement.addChild(properties)
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Reliable write isn't allowed")
                    
                case let .failure(error):
                   debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when element doesn't contain properties marker") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "hex"])

                self.testedElement.addChildren([value])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain properties marker inside")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when element contains empty properties marker") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "hex"])
                let properties = AEXMLElement(name: "properties")
                
                self.testedElement.addChildren([value, properties])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain any attribute in the properties marker")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing properties marker doesn't return any properties") {
                let attributes = ["uuid": "2000",
                                  "id": "descriptor",
                                  "sourceId": "gatt",]
                
                self.testedElement = AEXMLElement(name: "descriptor", attributes: attributes)
                
                let value = AEXMLElement(name: "value", value: "44", attributes: ["type": "hex"])
                let properties = AEXMLElement(name: "properties", attributes: ["read": "false"])
                
                self.testedElement.addChildren([value, properties])
                
                self.testObject = SILGattDescriptorMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
    }
}
