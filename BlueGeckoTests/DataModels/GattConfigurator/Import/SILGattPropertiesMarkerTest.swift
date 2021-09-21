//
//  SILGattPropertiesMarkerTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 25.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
import AEXML
import RealmSwift
@testable import BlueGecko

class SILGattPropertiesMarkerTest: QuickSpec {
    private var testObject: SILGattPropertiesMarker!
    private var testedElement: AEXMLElement!
    
    private func containsChild(entity: SILGattPropertiesEntity, name: String) -> Bool {
        return entity.additionalXmlChildren.contains(where: { element in element.name == name })
    }
    
    private func containsAttribute(entity: SILGattPropertiesEntity, name: String, value: String) -> Bool {
        return entity.additionalXmlAttributes.contains(where: { attribute in attribute.name == name && attribute.value == value })
    }

    private func constainsProperty(entity: SILGattPropertiesEntity, type: SILGattConfigurationPropertyType, permission: SILGattConfigurationAttributePermission) -> Bool {
        return entity.properties.contains(where: { property in property.type == type && property.permission == permission })
    }
    
    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }
        
        describe("should parse element to desired model entity only from attributes") {
            it("import element with read attribute = true") {
                let attributes = ["read": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with read attribute = false") {
                let attributes = ["read": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with bonded_read attribute = true") {
                let attributes = ["bonded_read": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_read attribute = false") {
                let attributes = ["bonded_read": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with read and bonded_read attribute = true") {
                let attributes = ["read": "true",
                                  "bonded_read": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with bonded_read = false, read = true") {
                let attributes = ["bonded_read": "false",
                                  "read": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return errorr when import element with bonded_read = true, read = false") {
                let attributes = ["bonded_read": "true",
                                  "read": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_read = false, read = false") {
                let attributes = ["bonded_read": "false",
                                  "read": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }


            // for write command
            it("import element with write attribute = true") {
                let attributes = ["write": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with write attribute = false") {
                let attributes = ["write": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with bonded_write attribute = true") {
                let attributes = ["bonded_write": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_write attribute = false") {
                let attributes = ["bonded_write": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with write and bonded_write attribute = true") {
                let attributes = ["write": "true",
                                  "bonded_write": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with bonded_write = false, write = true") {
                let attributes = ["bonded_write": "false",
                                  "write": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with bonded_write = true, write = false") {
                let attributes = ["bonded_write": "true",
                                  "write": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_write = false, write = false") {
                let attributes = ["bonded_write": "false",
                                  "write": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            // for write no response
            it("import element with write_no_response attribute = true") {
                let attributes = ["write_no_response": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .writeWithoutResponse, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with write_no_response attribute = false") {
                let attributes = ["write_no_response": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with write_no_response and bonded_write attribute = true") {
                let attributes = ["write_no_response": "true",
                                  "bonded_write": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(2))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .bonded)).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .writeWithoutResponse, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with bonded_write = false, write_no_response = true") {
                let attributes = ["bonded_write": "false",
                                  "write_no_response": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .writeWithoutResponse, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with bonded_write = true, write_no_response = false") {
                let attributes = ["bonded_write": "true",
                                  "write_no_response": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_write = false, write_no_response = false") {
                let attributes = ["bonded_write": "false",
                                  "write_no_response": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }


            // notify
            it("import element with notify attribute = true") {
                let attributes = ["notify": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .notify, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with notify attribute = false") {
                let attributes = ["notify": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with bonded_notify attribute = true") {
                let attributes = ["bonded_notify": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .notify, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_notify attribute = false") {
                let attributes = ["bonded_notify": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with notify and bonded_notify attribute = true") {
                let attributes = ["notify": "true",
                                  "bonded_notify": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .notify, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with bonded_notify = false, notify = true") {
                let attributes = ["bonded_notify": "false",
                                  "notify": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .notify, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_notify = true, notify = false") {
                let attributes = ["bonded_notify": "true",
                                  "notify": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_notify = false, notify = false") {
                let attributes = ["bonded_notify": "false",
                                  "notify": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            //indicate
            it("import element with indicate attribute = true") {
                let attributes = ["indicate": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .indicate, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with indicate attribute = false") {
                let attributes = ["indicate": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with indicate and bonded_notify attribute = true") {
                let attributes = ["indicate": "true",
                                  "bonded_notify": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(2))
                    expect(self.constainsProperty(entity: entity, type: .notify, permission: .bonded)).to(equal(true))
                    expect(self.constainsProperty(entity: entity, type: .indicate, permission: .bonded)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with bonded_notify = false, indicate = true") {
                let attributes = ["bonded_notify": "false",
                                  "indicate": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .indicate, permission: .none)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("import element with bonded_notify = true, indicate = false") {
                let attributes = ["bonded_notify": "true",
                                  "indicate": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .notify, permission: .bonded)).to(equal(true))


                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("should return error when import element with bonded_notify = false, indicate = false") {
                let attributes = ["bonded_notify": "false",
                                  "notify": "false"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("should reaturn error when import element with not parsed attributes but allowed") {
                let attributes = ["const": "true",
                                  "authenticated_read": "true",
                                  "encrypted_read": "true",
                                  "authenticated_write": "true",
                                  "encrypted_write": "true",
                                  "reliable_write": "true",
                                  "discoverable": "true",
                                  "encrypted_notify": "true",
                                  "authenticated_notify": "true",
                                  "read_requirement": "mandatory",
                                  "const_requirement": "optional",
                                  "write_requirement": "excluded",
                                  "write_no_response_requirement": "c1",
                                  "notify_requirement": "c2",
                                  "indicate_requirement": "c3",
                                  "authenticated_read_requirement": "c4",
                                  "bonded_read_requirement": "c5",
                                  "encrypted_read_requirement": "c6",
                                  "authenticated_write_requirement": "c7",
                                  "bonded_write_requirement": "c8",
                                  "encrypted_write_requirement": "c9",
                                  "reliable_write_requirement": "c10",
                                  "discoverable_requirement": "c10",
                                  "encrypted_notify_requirement": "c10",
                                  "authenticated_notify_requirement": "c10",
                                  "bonded_notify_requirement": "c10"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error wrong requirement set") {
                let attributes = ["const": "true",
                                  "authenticated_read": "true",
                                  "encrypted_read": "true",
                                  "authenticated_write": "true",
                                  "encrypted_write": "true",
                                  "reliable_write": "true",
                                  "discoverable": "true",
                                  "encrypted_notify": "true",
                                  "authenticated_notify": "true",
                                  "read_requirement": "important"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong value in requirement")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("return error on non-boolean value in attribute") {
                let attributes = ["const": "true",
                                  "authenticated_read": "true",
                                  "encrypted_read": "tak",
                                  "authenticated_write": "true",
                                  "encrypted_write": "true",
                                  "reliable_write": "true",
                                  "discoverable": "true",
                                  "encrypted_notify": "true",
                                  "authenticated_notify": "true",]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong value in attribute")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("should return error on import element with non allowed attribute") {
                let attributes = ["feature": "true"]
                self.testedElement = AEXMLElement(name: "properties", value: nil, attributes: attributes)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }

        describe("import element with children") {
            it("import element with child for read") {
                self.testedElement = AEXMLElement(name: "properties")

                let read = AEXMLElement(name: "read", attributes: ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(read)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "read_encrypted", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "read_authenticated", value: "true")).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }

            it("return error on import read element with not allowed attribute") {
                self.testedElement = AEXMLElement(name: "properties")

                let read = AEXMLElement(name: "read", attributes: ["feature": "true"])
                self.testedElement.addChild(read)

                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed attribute in child")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("import element with child for reliable_write") {
                self.testedElement = AEXMLElement(name: "properties")

                let reliable_write = AEXMLElement(name: "reliable_write", attributes: ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(reliable_write)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    fail("Must contain at least one property")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error on import element with not allowed name") {
                self.testedElement = AEXMLElement(name: "properties")

                let element = AEXMLElement(name: "element", attributes: ["bonded": "true"])
                self.testedElement.addChild(element)

                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Not allowed element name")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            //too many elements
            it("return error on import element with too many read options") {
                self.testedElement = AEXMLElement(name: "properties")

                let read = AEXMLElement(name: "read", attributes: ["bonded": "true"])
                let read2 = AEXMLElement(name: "read", attributes: ["bonded": "false"])
                self.testedElement.addChildren([read, read2])

                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many elements with name read")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error on import element with too many write options") {
                self.testedElement = AEXMLElement(name: "properties")

                let write = AEXMLElement(name: "write", attributes: ["bonded": "true"])
                let write2 = AEXMLElement(name: "write", attributes: ["bonded": "false"])
                self.testedElement.addChildren([write, write2])

                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many elements with name write")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error on import element with too many write_no_response options") {
                self.testedElement = AEXMLElement(name: "properties")

                let write_no_response = AEXMLElement(name: "write_no_response", attributes: ["bonded": "true"])
                let write_no_response2 = AEXMLElement(name: "write_no_response", attributes: ["bonded": "false"])
                self.testedElement.addChildren([write_no_response, write_no_response2])

                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many elements with name write_no_response")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error on import element with too many indicate options") {
                self.testedElement = AEXMLElement(name: "properties")

                let indicate = AEXMLElement(name: "indicate", attributes: ["bonded": "true"])
                let indicate2 = AEXMLElement(name: "indicate", attributes: ["bonded": "false"])
                self.testedElement.addChildren([indicate, indicate2])

                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many elements with name indicate")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error on import element with too many notify options") {
                self.testedElement = AEXMLElement(name: "properties")

                let notify = AEXMLElement(name: "notify", attributes: ["bonded": "true"])
                let notify2 = AEXMLElement(name: "notify", attributes: ["bonded": "false"])
                self.testedElement.addChildren([notify, notify2])

                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many elements with name notify")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("return error on import element with too many reliable_write options") {
                self.testedElement = AEXMLElement(name: "properties")

                let reliable_write = AEXMLElement(name: "reliable_write", attributes: ["bonded": "true"])
                let reliable_write2 = AEXMLElement(name: "reliable_write", attributes: ["bonded": "false"])
                self.testedElement.addChildren([reliable_write, reliable_write2])

                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many elements with name reliable_write")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
        
        describe("import with elements and attributes") {
            it("should use read configuration from children") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["read": "true", "bonded_read": "true", "encrypted_read": "false"])

                let read = AEXMLElement(name: "read", attributes: ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(read)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .none)).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_encrypted_read", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_bonded_read", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_read", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "read_encrypted", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "read_authenticated", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should use read configuration from children even when attributes tells that property is unavailable") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["read": "false", "bonded_read": "false", "encrypted_read": "false"])

                let read = AEXMLElement(name: "read", attributes: ["bonded": "true", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(read)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .bonded)).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_encrypted_read", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_read", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_bonded_read", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "read_encrypted", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "read_authenticated", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should use write configuration from children even when attributes tells that property is unavailable") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["write": "false", "bonded_write": "true", "encrypted_write": "false"])
                
                let write = AEXMLElement(name: "write", attributes: ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(write)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .none)).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_encrypted_write", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_write", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_bonded_write", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "write_encrypted", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "write_authenticated", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should use write_no_response configuration from children even when attributes tells that property is unavailable") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["write_no_response": "false", "bonded_write": "true", "encrypted_write": "false"])
                
                let write_no_response = AEXMLElement(name: "write_no_response", attributes: ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(write_no_response)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .writeWithoutResponse, permission: .none)).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_encrypted_write", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_write_no_response", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_bonded_write", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "write_no_response_encrypted", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "write_no_response_authenticated", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should use notify configuration from children even when attributes tells that property is unavailable") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["notify": "false", "bonded_notify": "true", "encrypted_notify": "false"])
                
                let notify = AEXMLElement(name: "notify", attributes: ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(notify)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .notify, permission: .none)).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_encrypted_notify", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_notify", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_bonded_notify", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "notify_encrypted", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "notify_authenticated", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should use indicate configuration from children even when attributes tells that property is unavailable") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["indicate": "false", "bonded_notify": "true", "encrypted_notify": "false"])
                
                let indicate = AEXMLElement(name: "indicate", attributes: ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(indicate)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(5))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .indicate, permission: .none)).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_encrypted_notify", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_indicate", value: "false")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "properties_bonded_notify", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "indicate_encrypted", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "indicate_authenticated", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
        }
        
        describe("import properties element for descriptors") {
            it("should import element without error") {
                self.testedElement = AEXMLElement(name: "properties")
                let write = AEXMLElement(name: "write", attributes:  ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(write)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parseForDescriptor()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(2))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .none)).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "write_encrypted", value: "true")).to(equal(true))
                    expect(self.containsAttribute(entity: entity, name: "write_authenticated", value: "true")).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
                
            it("return error when import not allowed property for descriptors") {
                self.testedElement = AEXMLElement(name: "properties")
                let notify = AEXMLElement(name: "notify", attributes: ["bonded": "false", "encrypted": "true", "authenticated": "true"])
                self.testedElement.addChild(notify)
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parseForDescriptor()
                switch result {
                case .success(_):
                    fail("Notify isn't allowed for descriptors")
                
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("should import read property using attributes") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["read": "true", "bonded_read": "true"])
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parseForDescriptor()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .read, permission: .bonded)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("should import write property using attributes") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["write": "true", "bonded_write": "true"])
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parseForDescriptor()
                switch result {
                case let .success(entity):
                    expect(entity.additionalXmlAttributes.count).to(equal(0))
                    expect(entity.additionalXmlChildren.count).to(equal(0))
                    expect(entity.properties.count).to(equal(1))
                    expect(self.constainsProperty(entity: entity, type: .write, permission: .bonded)).to(equal(true))
                    
                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("return error when importing not-allowed reliable_write") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["reliable_write": "true"])
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parseForDescriptor()
                switch result {
                case .success(_):
                    fail("Reliable write isn't allowed")
                    
                case let .failure(error):
                   debugPrint(error.localizedDescription)
                }
            }
            
            it("return error when importing not-allowed write_no_response") {
                self.testedElement = AEXMLElement(name: "properties", attributes: ["write_no_response": "true"])
                self.testObject = SILGattPropertiesMarker(element: self.testedElement)
                
                let result = self.testObject.parseForDescriptor()
                switch result {
                case .success(_):
                    fail("Write no response isn't allowed")
                    
                case let .failure(error):
                   debugPrint(error.localizedDescription)
                }
            }
        }
    }
}
