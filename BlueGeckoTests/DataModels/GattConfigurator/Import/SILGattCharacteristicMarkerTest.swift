//
//  SILGattCharacteristicMarkerTest.swift
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

class SILGattCharacteristicMarkerTest: QuickSpec {
    private var testObject: SILGattCharacteristicMarker!
    private var testedElement: AEXMLElement!
    private var gattAssignedRepository = SILGattAssignedNumbersRepository()
    
    private func containsAttribute(entity: SILGattConfigurationCharacteristicEntity, name: String, value: String) -> Bool {
        return entity.additionalXmlAttributes.contains(where: { attribute in attribute.name == name && attribute.value == value })
    }
    
    private func containsChild(entity: SILGattConfigurationCharacteristicEntity, name: String) -> Bool {
        return entity.additionalXmlChildren.contains(where: { element in element.name == name })
    }
    
    private func constainsProperty(entity: SILGattConfigurationCharacteristicEntity, type: SILGattConfigurationPropertyType, permission: SILGattConfigurationAttributePermission) -> Bool {
        return entity.properties.contains(where: { property in property.type == type && property.permission == permission })
    }
    
    private func containsDescriptor(entity: SILGattConfigurationCharacteristicEntity, withUUID: String) -> Bool {
        return entity.descriptors.contains(where: { descriptor in descriptor.cbuuidString == withUUID })
    }
    
    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }
        
        describe("should parse element to desired model entity - without children") {
            it("return error when element name is wrong") {
                self.testedElement = AEXMLElement(name: "element")
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong element name")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid is wrong (16 bit)") {
                let attributes = ["uuid" : "180t"]
                self.testedElement = AEXMLElement(name: "characteristic", value: nil, attributes: attributes)
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong UUID!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid is wrong (128 bit)") {
                let attributes = ["uuid" : "2 5 7 f 9 9 3 d  - b a a 6 - e 6 9 c - 8b101e4e6b3f"]
                self.testedElement = AEXMLElement(name: "characteristic", value: nil, attributes: attributes)
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong UUID!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid attribute is missing") {
                let attributes = ["name": "My characteristic"]
                self.testedElement = AEXMLElement(name: "characterisitc", value: nil, attributes: attributes)
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Uuid attribute is missing!")
                
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element allowed attributes (characteristic not named)") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "false",
                                  "instance_id": "1"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                self.testedElement.addChild(properties)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(4))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "instance_id", value: "1")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("return error when parsing non-allowed attribute") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "false",
                                  "instance": "1"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Non-allowed attribute")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when parsing non-allowed const value") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "nie"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Non-allowed attribute value")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
                
        describe("should parse element to desired model entity - with children") {
            it("return error when parsing too many capabilities markers") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let capabilities = AEXMLElement(name: "capabilities")
                let capabilities2 = AEXMLElement(name: "capabilities")
                self.testedElement.addChildren([capabilities, capabilities2])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many capabilities markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when parsing too many properties markers") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let properties = AEXMLElement(name: "properties")
                let properties2 = AEXMLElement(name: "properties")
                self.testedElement.addChildren([properties, properties2])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many properties markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when parsing too many value markers") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let value = AEXMLElement(name: "value")
                let value2 = AEXMLElement(name: "value")
                self.testedElement.addChildren([value, value2])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many value markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error when parsing too many informativeText markers") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let informativeText = AEXMLElement(name: "informativeText")
                let informativeText2 = AEXMLElement(name: "informativeText")
                self.testedElement.addChildren([informativeText, informativeText2])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many informativeText markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error when parsing too many description markers") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let description = AEXMLElement(name: "description")
                let description2 = AEXMLElement(name: "description")
                self.testedElement.addChildren([description, description2])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many description markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error when parsing too many aggregate markers") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let aggregate = AEXMLElement(name: "aggregate")
                let aggregate2 = AEXMLElement(name: "aggregate")
                self.testedElement.addChildren([aggregate, aggregate2])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many aggregate markers")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with informativeText") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let informativeText = AEXMLElement(name: "informativeText")
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                
                self.testedElement.addChildren([informativeText, properties])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(3))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "informativeText")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with description") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let informativeText = AEXMLElement(name: "description")
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                self.testedElement.addChildren([informativeText, properties])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(3))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "description")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with aggregate") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let aggregate = AEXMLElement(name: "aggregate", attributes: ["id": "agr"])
                let attribute = AEXMLElement(name: "attribute", attributes: ["id": "atr"])
                let attribute2 = AEXMLElement(name: "attribute", attributes: ["id": "bcd"])
                aggregate.addChildren([attribute, attribute2])
                
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                
                self.testedElement.addChildren([aggregate, properties])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(3))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "aggregate")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("return error when parsing aggregate with too many attributes") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let informativeText = AEXMLElement(name: "aggregate", attributes: ["id": "agr", "id2": "arg2"])
                let attribute = AEXMLElement(name: "attribute")
                informativeText.addChild(attribute)
                
                self.testedElement.addChild(informativeText)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Aggregate is invalid")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when parsing aggregate with only one attribute on list") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let informativeText = AEXMLElement(name: "aggregate", attributes: ["id": "agr"])
                let attribute = AEXMLElement(name: "attribute")
                informativeText.addChild(attribute)
                
                self.testedElement.addChild(informativeText)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Attribute list has to at least 2 attributes")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element with descriptor") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let descriptor = AEXMLElement(name: "descriptor", attributes: ["uuid": "2001"])
                let descriptorProperties = AEXMLElement(name: "properties", attributes: ["bonded_read": "true"])
                descriptor.addChild(descriptorProperties)
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                
                self.testedElement.addChildren([descriptor, properties])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(1))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(3))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("return error when parsing wrong descriptor") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let descriptor = AEXMLElement(name: "descriptor")
                
                self.testedElement.addChild(descriptor)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Descriptor is incorrect")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element with value") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let descriptor = AEXMLElement(name: "value", value: "44", attributes: ["type": "hex"])
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                
                self.testedElement.addChildren([descriptor, properties])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.initialValue).to(equal("44"))
                    expect(entity.initialValueType).to(equal(SILGattConfigurationValueType.hex))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(3))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("return error when parsing wrong value marker") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let descriptor = AEXMLElement(name: "value", attributes: ["type": "wtf"])
                
                self.testedElement.addChild(descriptor)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Value is incorrect")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element with capabilities, characteristic should be visible") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "second")
                capabilities.addChild(capability)
                
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                self.testedElement.addChildren([capabilities, properties])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let inheritedCapabilities = [SILGattCapabilityEntity(name: "second", enabled: true)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)
                
                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare)
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(3))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "capabilities")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with capabilities, element should not be hidden due to ignoring capabilities") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "first")
                let capability2 = AEXMLElement(name: "capability", value: "second")
                capabilities.addChildren([capability, capability2])
                
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                self.testedElement.addChildren([capabilities, properties])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let inheritedCapabilities = [SILGattCapabilityEntity(name: "first", enabled: false), SILGattCapabilityEntity(name: "second", enabled: false)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)
                
                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare)
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(3))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "capabilities")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error when element contains capabilities that aren't inherited") {
                let attributes = ["uuid": "2000"]
                self.testedElement = AEXMLElement(name: "characteristic", value: nil, attributes: attributes)

                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "third")
                capabilities.addChild(capability)

                self.testedElement.addChild(capabilities)

                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let inheritedCapabilities = [SILGattCapabilityEntity(name: "first", enabled: false),
                                    SILGattCapabilityEntity(name: "second", enabled: false)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)

                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare)
                switch result {
                case .success(_):
                    fail("Element contains not inherited capabilities")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when capabilities are invalid") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "first", attributes: ["enable": "true"])
                let capability2 = AEXMLElement(name: "capability", value: "second")
                capabilities.addChildren([capability, capability2])
                
                self.testedElement.addChild(capabilities)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let inheritedCapabilities = [SILGattCapabilityEntity(name: "first", enabled: true), SILGattCapabilityEntity(name: "second", enabled: true)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)
                
                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare)
                switch result {
                case .success(_):
                    fail("Capabilities are invalid")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with properties") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true", "write": "true"])
                
                self.testedElement.addChild(properties)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let inheritedCapabilities = [SILGattCapabilityEntity(name: "second", enabled: true)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)
                
                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare)
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.name).to(equal("Custom char"))
                    expect(entity.descriptors.count).to(equal(1))
                    expect(entity.properties.count).to(equal(2))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(3))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "gatt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "gatt_source")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "const", value: "true")).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .none)).to(equal(true))
                    expect(self.containsDescriptor(entity: entity, withUUID: "2900")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("return error when parsing properties with error") {
                let attributes = ["uuid": "2000",
                                  "id": "gatt",
                                  "sourceId": "gatt_source",
                                  "name": "Custom char",
                                  "const": "true"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let properties = AEXMLElement(name: "properties", attributes: ["read_bonded": "true", "write": "true"])
                
                self.testedElement.addChild(properties)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let inheritedCapabilities = [SILGattCapabilityEntity(name: "second", enabled: true)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)
                
                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare)
                switch result {
                case .success(_):
                    fail("Properties are invalid")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
        
        describe("import characteristic with descriptors") {
            it("should return characteristic with default descriptors") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let properties = AEXMLElement(name: "properties", attributes: ["notify": "true", "write": "true"])
                
                self.testedElement.addChild(properties)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.descriptors.count).to(equal(2))
                    expect(entity.properties.count).to(equal(2))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(self.constainsProperty(entity: entity, type: .notify, permission: .none)).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .none)).to(equal(true))
                    expect(self.containsDescriptor(entity: entity, withUUID: "2900")).to(equal(true))
                    expect(self.containsDescriptor(entity: entity, withUUID: "2902")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return characteristic only with declared descriptor") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                let descriptor = AEXMLElement(name: "descriptor", attributes: ["uuid": "2903"])
                let descriptorProperties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                descriptor.addChild(descriptorProperties)
                self.testedElement.addChildren([properties, descriptor])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.descriptors.count).to(equal(1))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    expect(self.containsDescriptor(entity: entity, withUUID: "2903")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return characteristic with declared descriptor and defaults") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let properties = AEXMLElement(name: "properties", attributes: ["write": "true", "indicate": "true"])
                let descriptor = AEXMLElement(name: "descriptor", attributes: ["uuid": "2903"])
                let descriptorProperties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                descriptor.addChild(descriptorProperties)
                self.testedElement.addChildren([properties, descriptor])
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.descriptors.count).to(equal(3))
                    expect(entity.properties.count).to(equal(2))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .none)).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .indicate, permission: .none)).to(equal(true))
                    expect(self.containsDescriptor(entity: entity, withUUID: "2903")).to(equal(true))
                    expect(self.containsDescriptor(entity: entity, withUUID: "2900")).to(equal(true))
                    expect(self.containsDescriptor(entity: entity, withUUID: "2902")).to(equal(true))
    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return characteristic with declared descriptor despite it is added automatically") {
                let attributes = ["uuid": "2000"]
                
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let properties = AEXMLElement(name: "properties", attributes: ["write": "true"])
                let descriptor = AEXMLElement(name: "descriptor", attributes: ["uuid": "2900"])
                let value = AEXMLElement(name: "value", value: "0x55", attributes: ["length" : "1",
                                                                                    "type": "hex",
                                                                                    "variable_length" : "false"])
                let descriptorProperties = AEXMLElement(name: "properties", attributes: ["write": "true"])
                descriptor.addChildren([value, descriptorProperties])
                self.testedElement.addChildren([properties, descriptor])
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("2000"))
                    expect(entity.descriptors.count).to(equal(1))
                    expect(entity.properties.count).to(equal(1))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .none)).to(equal(true))
                    expect(self.containsDescriptor(entity: entity, withUUID: "2900")).to(equal(true))
                    expect(entity.descriptors.first?.initialValue).to(equal("55"))
                    expect(entity.descriptors.first?.initialValueType).to(equal(SILGattConfigurationValueType.hex))
                    expect(entity.descriptors.first?.fixedVariableLength).to(equal(true))
                    expect(entity.descriptors.first?.canBeModified).to(equal(false))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error when parsing element without properties marker") {
                let attributes = ["uuid": "2001"]
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Can't parse element without properties")
                
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing element with empty <properties> marker") {
                let attributes = ["uuid": "2001"]
                self.testedElement = AEXMLElement(name: "characteristic", attributes: attributes)
                
                let properties = AEXMLElement(name: "properties")
                self.testedElement.addChild(properties)
                
                self.testObject = SILGattCharacteristicMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Can't parse element with empty properties marker")
                
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
    }
}
