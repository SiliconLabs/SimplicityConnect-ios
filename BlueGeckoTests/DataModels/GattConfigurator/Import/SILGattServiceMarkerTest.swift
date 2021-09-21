//
//  SILGattServiceMarkerTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 21.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
import AEXML
import RealmSwift
@testable import BlueGecko

class SILGattServiceMarkerTest : QuickSpec {
    private var testObject: SILGattServiceMarker!
    private var testedElement: AEXMLElement!
    private var gattAssignedRepository = SILGattAssignedNumbersRepository()
    
    private func containsAttribute(entity: SILGattConfigurationServiceEntity, name: String, value: String) -> Bool {
        return entity.additionalXmlAttributes.contains(where: { attribute in attribute.name == name && attribute.value == value })
    }
    
    private func containsChild(entity: SILGattConfigurationServiceEntity, name: String) -> Bool {
        return entity.additionalXmlChildren.contains(where: { element in element.name == name })
    }
    
    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }
        
        describe("should parse element to desired model entity - without children") {
            it("should return error when xml name is wrong") {
                let attributes = ["uuid" : "1905"]
                self.testedElement = AEXMLElement(name: "element", value: nil, attributes: attributes)
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong xml element name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid is wrong (16 bit)") {
                let attributes = ["uuid" : "tttt"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong UUID!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid is wrong (128 bit)") {
                let attributes = ["uuid" : "2 5 7 f 9 9 3 d - 7 5 6 e - b a a 6 - e 6 9 c - 8b101e4e6b3f"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong UUID!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when uuid attribute is missing") {
                let attributes = ["name": "My service"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Uuid attribute is missing!")
                
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element only with uuid defined (service not named)") {
                let attributes = ["uuid" : "1905"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1905"))
                    expect(entity.name).to(equal("Unknown Service"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.characteristics.count).to(equal(0))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with non-required attributes") {
                let attributes = ["uuid": "1004",
                                  "id": "55",
                                  "sourceId": "111",
                                  "type": "secondary",
                                  "requirement": "c5",
                                  "advertise": "true",
                                  "name": "Custom service",
                                  "instance_id": "100"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1004"))
                    expect(entity.name).to(equal("Custom service"))
                    expect(entity.isPrimary).to(equal(false))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.characteristics.count).to(equal(0))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "55")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "111")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "requirement", value: "c5")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "advertise", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "instance_id", value: "100")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with additional children and additional attributes") {
                let attributes = ["uuid": "1800",
                                  "id": "0",
                                  "sourceId": "1",
                                  "type": "primary",
                                  "requirement": "mandatory",
                                  "advertise": "false",
                                  "name": "Generic Attribute",
                                  "instance_id": "2"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
                
                let informativeText = AEXMLElement(name: "informativeText")
                let description = AEXMLElement(name: "description")
                let uri = AEXMLElement(name: "uri")
                let include = AEXMLElement(name: "include", attributes: ["id": "ota"])
                self.testedElement.addChildren([informativeText, description, uri, include])
                
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse(withCapabilites: SILGattCapabilitiesDeclareEntity(capabilities: []), andServicesIDs: ["ota"])
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1800"))
                    expect(entity.name).to(equal("Generic Access"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(4))
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.characteristics.count).to(equal(0))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "0")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "1")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "requirement", value: "mandatory")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "advertise", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "instance_id", value: "2")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "informativeText")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "description")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "uri")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "include")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed attribute") {
                let attributes = ["uuid": "1800",
                                  "id": "0",
                                  "source": "gatt"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
           
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed value in attribute type") {
                let attributes = ["uuid": "1800",
                                  "id": "0",
                                  "type": "first"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
           
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute value!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed value in attribute requirement") {
                let attributes = ["uuid": "1800",
                                  "id": "0",
                                  "requirement": "important"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
           
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute value!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed value in attribute advertise") {
                let attributes = ["uuid": "1800",
                                  "id": "0",
                                  "advertise": "first"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
           
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute value!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
        
        describe("should parse element to desired model entity - with children") {
            it("import service with characteristics") {
                let attributes = ["uuid": "1800",
                                  "id": "0",
                                  "sourceId": "1",
                                  "type": "primary",
                                  "requirement": "mandatory",
                                  "advertise": "false",
                                  "name": "Generic Attribute",
                                  "instance_id": "2"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let characteristic = AEXMLElement(name: "characteristic", attributes: ["name": "First", "uuid": "2330"])
                let properties = AEXMLElement(name: "properties", attributes: ["read": "true"])
                characteristic.addChild(properties)
                let characteristic2 = AEXMLElement(name: "characteristic", attributes: ["name": "Second", "uuid": "2000"])
                let properties2 = AEXMLElement(name: "properties", attributes: ["write": "true"])
                characteristic2.addChild(properties2)
                self.testedElement.addChildren([characteristic, characteristic2])

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1800"))
                    expect(entity.name).to(equal("Generic Access"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.characteristics.count).to(equal(2))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "0")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "1")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "requirement", value: "mandatory")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "advertise", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "instance_id", value: "2")).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when element is not allowed") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let characteristic = AEXMLElement(name: "characteristic222", attributes: ["name": "First", "uuid": "2330"])
                let characteristic2 = AEXMLElement(name: "characteristic", attributes: ["name": "Second", "uuid": "2000"])
                self.testedElement.addChildren([characteristic, characteristic2])

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Element not allowed!")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("should return error when too many informativeTexts") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let informativeText = AEXMLElement(name: "informativeText")
                let informativeText2 = AEXMLElement(name: "informativeText")
                self.testedElement.addChildren([informativeText, informativeText2])

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many informativeText markers")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("should return error when too many descriptions") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let description = AEXMLElement(name: "description")
                let description2 = AEXMLElement(name: "description")
                self.testedElement.addChildren([description, description2])

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many description markers")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("should return error when too many uris") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let uri = AEXMLElement(name: "uri")
                let uri2 = AEXMLElement(name: "uri")
                self.testedElement.addChildren([uri, uri2])

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many uri markers")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when too many capabilities") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let capabilities = AEXMLElement(name: "capabilities")
                let capabilities2 = AEXMLElement(name: "capabilities")
                self.testedElement.addChildren([capabilities, capabilities2])

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many capabilities markers")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import with correct include services") {
                let attributes = ["uuid": "1800",
                                  "id": "generic_attribute",
                                  "sourceId": "1",
                                  "type": "primary",
                                  "requirement": "mandatory",
                                  "advertise": "false",
                                  "name": "Generic Attribute",
                                  "instance_id": "2"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let include = AEXMLElement(name: "include", attributes: ["id": "ota", "sourceId": "ota_source"])
                let include2 = AEXMLElement(name: "include", attributes: ["id": "generic_access"])
                self.testedElement.addChildren([include, include2])

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse(withCapabilites: SILGattCapabilitiesDeclareEntity(capabilities: []), andServicesIDs: ["generic_access", "blinky", "ota"])
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1800"))
                    expect(entity.name).to(equal("Generic Access"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(2))
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.characteristics.count).to(equal(0))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "generic_attribute")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "sourceId", value: "1")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "requirement", value: "mandatory")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "advertise", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "instance_id", value: "2")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "include")).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import with correct include services when service ID not set") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let include = AEXMLElement(name: "include", attributes: ["id": "ota", "sourceId": "ota_source"])
                let include2 = AEXMLElement(name: "include", attributes: ["id": "generic_access"])
                self.testedElement.addChildren([include, include2])

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse(withCapabilites: SILGattCapabilitiesDeclareEntity(capabilities: []), andServicesIDs: ["generic_access", "blinky", "ota"])
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1800"))
                    expect(entity.name).to(equal("Generic Access"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(2))
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.characteristics.count).to(equal(0))
                    expect(self.containsChild(entity: entity, name: "include")).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("return error when include services are incorrect") {
                let attributes = ["uuid": "1800",
                                  "id": "0",
                                  "sourceId": "1",
                                  "type": "primary",
                                  "requirement": "mandatory",
                                  "advertise": "false",
                                  "name": "Generic Attribute",
                                  "instance_id": "2"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)
                
                let include = AEXMLElement(name: "include", attributes: ["id": "ota", "sourceId": "ota_source"])
                let include2 = AEXMLElement(name: "include", attributes: ["id": "generic_access", "id2": "generic_attribute"])
                self.testedElement.addChildren([include, include2])
                
                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Incorrect include services")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
        
        describe("should parse element to desired model entity - with capabilities") {
            it("should parse capabilities and not change visibility of service") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "first")
                capabilities.addChild(capability)

                self.testedElement.addChild(capabilities)

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1800"))
                    expect(entity.name).to(equal("Generic Access"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(self.containsChild(entity: entity, name: "capabilities")).to(equal(true))
                    expect(entity.characteristics.count).to(equal(0))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should parse capabilities with capabilities_declare and show service") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "first")
                capabilities.addChild(capability)

                self.testedElement.addChild(capabilities)

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let inheritedCapabilities = [SILGattCapabilityEntity(name: "first", enabled: true),
                                    SILGattCapabilityEntity(name: "second", enabled: false)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)

                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare, andServicesIDs: [])
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1800"))
                    expect(entity.name).to(equal("Generic Access"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(self.containsChild(entity: entity, name: "capabilities")).to(equal(true))
                    expect(entity.characteristics.count).to(equal(0))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should parse capabilities with capabilities_declare and not hide service, due to ignoring capabilities") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "first")
                capabilities.addChild(capability)

                self.testedElement.addChild(capabilities)

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let inheritedCapabilities = [SILGattCapabilityEntity(name: "first", enabled: false),
                                    SILGattCapabilityEntity(name: "second", enabled: false)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)

                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare, andServicesIDs: [])
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1800"))
                    expect(entity.name).to(equal("Generic Access"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(self.containsChild(entity: entity, name: "capabilities")).to(equal(true))
                    expect(entity.characteristics.count).to(equal(0))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when element contains capabilities that aren't inherited") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "third")
                capabilities.addChild(capability)

                self.testedElement.addChild(capabilities)

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let inheritedCapabilities = [SILGattCapabilityEntity(name: "first", enabled: false),
                                    SILGattCapabilityEntity(name: "second", enabled: false)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)

                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare, andServicesIDs: [])
                switch result {
                case .success(_):
                    fail("Element contains not inherited capabilities")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should parse capabilities with capabilities_declare and show service") {
                let attributes = ["uuid": "1800"]
                self.testedElement = AEXMLElement(name: "service", value: nil, attributes: attributes)

                let capabilities = AEXMLElement(name: "capabilities")
                let capability = AEXMLElement(name: "capability", value: "first")
                let capability2 = AEXMLElement(name: "capability", value: "second")
                capabilities.addChildren([capability, capability2])

                self.testedElement.addChild(capabilities)

                self.testObject = SILGattServiceMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)

                let inheritedCapabilities = [SILGattCapabilityEntity(name: "first", enabled: false),
                                    SILGattCapabilityEntity(name: "second", enabled: true)]
                let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: inheritedCapabilities)

                let result = self.testObject.parse(withCapabilites: capabilitiesDeclare, andServicesIDs: [])
                switch result {
                case let .success(entity):
                    expect(entity.cbuuidString).to(equal("1800"))
                    expect(entity.name).to(equal("Generic Access"))
                    expect(entity.isPrimary).to(equal(true))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(self.containsChild(entity: entity, name: "capabilities")).to(equal(true))
                    expect(entity.characteristics.count).to(equal(0))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
        }
    }
}
