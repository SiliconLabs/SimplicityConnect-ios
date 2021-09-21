//
//  SILGattMarkerTest.swift
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

class SILGattMarkerTest : QuickSpec {
    private var testObject: SILGattMarker!
    private var testedElement: AEXMLElement!
    private var gattAssignedRepository = SILGattAssignedNumbersRepository()
    
    private func containsAttribute(entity: SILGattConfigurationEntity, name: String, value: String) -> Bool {
        return entity.additionalXmlAttributes.contains(where: { attribute in attribute.name == name && attribute.value == value })
    }
    
    private func containsChild(entity: SILGattConfigurationEntity, name: String) -> Bool {
        return entity.additionalXmlChildren.contains(where: { child in child.name == name })
    }
    
    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }
        
        // required attributes: out, header, name, prefix, generic_attribute_service
        describe("should parse element to desired model entity - without services") {
            it("should return error when xml name is wrong") {
                let attributes = ["in": "gattIn",
                                  "gatt_caching": "true",
                                  "id": "5"]
                self.testedElement = AEXMLElement(name: "element", value: nil, attributes: attributes)
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong xml element name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element without any of required attributes") {
                let attributes = ["in": "gattIn",
                                  "gatt_caching": "true",
                                  "id": "5"]
                self.testedElement = AEXMLElement(name: "gatt", value: nil, attributes: attributes)
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.name).to(equal("Custom BLE GATT"))
                    expect(entity.services.count).to(equal(0))
                    expect(entity.xmlNodeName).to(equal("gatt"))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(7))
                    expect(entity.projectEntity).to(beNil())
                    expect(self.containsAttribute(entity: entity, name: "in", value: "gattIn")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "gatt_caching", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "5")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "out", value: "gatt_db.c")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "header", value: "gatt_db.h")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "prefix", value: "gattdb_")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "generic_attribute_service", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with not each of required attributes") {
                let attributes = ["in": "gattInt",
                                  "gatt_caching": "false",
                                  "id": "55",
                                  "name": "GATTFirst",
                                  "out": "gatt_out",
                                  "header": "gatt_header"]
                self.testedElement = AEXMLElement(name: "gatt", value: nil, attributes: attributes)
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.name).to(equal("GATTFirst"))
                    expect(entity.services.count).to(equal(0))
                    expect(entity.xmlNodeName).to(equal("gatt"))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(7))
                    expect(entity.projectEntity).to(beNil())
                    expect(self.containsAttribute(entity: entity, name: "in", value: "gattInt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "gatt_caching", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "55")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "out", value: "gatt_out")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "header", value: "gatt_header")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "prefix", value: "gattdb_")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "generic_attribute_service", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with all required attributes") {
                let attributes = ["in": "gattInt",
                                  "gatt_caching": "false",
                                  "id": "0",
                                  "name": "GATTFirst",
                                  "out": "gatt_out",
                                  "header": "gatt_header",
                                  "prefix": "abc",
                                  "generic_attribute_service": "false"]
                self.testedElement = AEXMLElement(name: "gatt", value: nil, attributes: attributes)
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.name).to(equal("GATTFirst"))
                    expect(entity.services.count).to(equal(0))
                    expect(entity.xmlNodeName).to(equal("gatt"))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(7))
                    expect(entity.projectEntity).to(beNil())
                    expect(self.containsAttribute(entity: entity, name: "in", value: "gattInt")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "gatt_caching", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "id", value: "0")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "out", value: "gatt_out")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "header", value: "gatt_header")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "prefix", value: "abc")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "generic_attribute_service", value: "false")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error when parsing not allowed attribute") {
                let attributes = ["in": "gattIn",
                                  "gatt_caching": "true",
                                  "id": "5",
                                  "suffix": "true"]
                self.testedElement = AEXMLElement(name: "gatt", value: nil, attributes: attributes)
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return error when parsing attribute with not allowed value") {
                let attributes = ["in": "gattIn",
                                  "gatt_caching": "tak",
                                  "id": "5",
                                  "generic_attribute_service": "nie" ]
                self.testedElement = AEXMLElement(name: "gatt", value: nil, attributes: attributes)
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute value!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
        
        describe("should parse element to desired model entity - with services") {
            it("import element with services") {
                self.testedElement = AEXMLElement(name: "gatt")
                let service = AEXMLElement(name: "service", attributes: ["name": "Custom service", "uuid": "1800"])
                let service2 = AEXMLElement(name: "service", attributes: ["uuid": "1900"])
                self.testedElement.addChildren([service, service2])
                
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.name).to(equal("Custom BLE GATT"))
                    expect(entity.services.count).to(equal(2))
                    expect(entity.xmlNodeName).to(equal("gatt"))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.additionalXmlAttributes.count).to(equal(4))
                    expect(entity.projectEntity).to(beNil())
                    expect(self.containsAttribute(entity: entity, name: "out", value: "gatt_db.c")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "header", value: "gatt_db.h")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "prefix", value: "gattdb_")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "generic_attribute_service", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error on import element with wrong child name") {
                self.testedElement = AEXMLElement(name: "gatt")
                let service = AEXMLElement(name: "service22", attributes: ["name": "Custom service", "uuid": "1800"])
                self.testedElement.addChildren([service])
                
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong element name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
        
        describe("should parse element to desired model entity - with capabilities") {
            it("import element with capabilities") {
                self.testedElement = AEXMLElement(name: "gatt")
                let capability = AEXMLElement(name: "capability", value: "first", attributes: ["enable": "true"])
                let capabilities_declare = AEXMLElement(name: "capabilities_declare")
                capabilities_declare.addChild(capability)
                self.testedElement.addChild(capabilities_declare)
                
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.name).to(equal("Custom BLE GATT"))
                    expect(entity.services.count).to(equal(0))
                    expect(entity.xmlNodeName).to(equal("gatt"))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(4))
                    expect(entity.projectEntity).to(beNil())
                    expect(self.containsAttribute(entity: entity, name: "out", value: "gatt_db.c")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "header", value: "gatt_db.h")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "prefix", value: "gattdb_")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "generic_attribute_service", value: "true")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "capabilities_declare")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error on import wrong capabilities element") {
                self.testedElement = AEXMLElement(name: "gatt")
                let capabilities_declare = AEXMLElement(name: "capabilities_declare")
                self.testedElement.addChild(capabilities_declare)
                
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong capablities_declare element!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element with capabilities and service") {
                self.testedElement = AEXMLElement(name: "gatt")
                let capability = AEXMLElement(name: "capability", value: "first", attributes: ["enable": "true"])
                let capabilities_declare = AEXMLElement(name: "capabilities_declare")
                capabilities_declare.addChild(capability)
                
                let service = AEXMLElement(name: "service", attributes: ["uuid": "1900"])
                self.testedElement.addChildren([capabilities_declare, service])
                
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.name).to(equal("Custom BLE GATT"))
                    expect(entity.services.count).to(equal(1))
                    expect(entity.xmlNodeName).to(equal("gatt"))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(4))
                    expect(entity.projectEntity).to(beNil())
                    expect(self.containsAttribute(entity: entity, name: "out", value: "gatt_db.c")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "header", value: "gatt_db.h")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "prefix", value: "gattdb_")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "generic_attribute_service", value: "true")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "capabilities_declare")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should return error when too many capablities_declare markers") {
                self.testedElement = AEXMLElement(name: "gatt")
                let capabilities_declare = AEXMLElement(name: "capabilities_declare")
                let capabilities_declare2 = AEXMLElement(name: "capabilities_declare")
                self.testedElement.addChildren([capabilities_declare, capabilities_declare2])
                
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many capabilities declare markers!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should return entity that has set projectEntity") {
                self.testedElement = AEXMLElement(name: "gatt")
                let capability = AEXMLElement(name: "capability", value: "first", attributes: ["enable": "true"])
                let capabilities_declare = AEXMLElement(name: "capabilities_declare")
                capabilities_declare.addChild(capability)
                
                let service = AEXMLElement(name: "service", attributes: ["uuid": "1900"])
                self.testedElement.addChildren([capabilities_declare, service])
                
                self.testObject = SILGattMarker(element: self.testedElement, gattAssignedRepository: self.gattAssignedRepository)
                
                let projectEntity = SILGattProjectEntity()
                
                let result = self.testObject.parse(withProjectEntity: projectEntity)
                switch result {
                case let .success(entity):
                    expect(entity.name).to(equal("Custom BLE GATT"))
                    expect(entity.services.count).to(equal(1))
                    expect(entity.xmlNodeName).to(equal("gatt"))
                    expect(entity.additionalXmlChildren.count).to(equal(1))
                    expect(entity.additionalXmlAttributes.count).to(equal(4))
                    expect(entity.projectEntity).notTo(beNil())
                    expect(self.containsAttribute(entity: entity, name: "out", value: "gatt_db.c")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "header", value: "gatt_db.h")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "prefix", value: "gattdb_")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "generic_attribute_service", value: "true")).to(equal(true))
                    expect(self.containsChild(entity: entity, name: "capabilities_declare")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
        }
    }
}
