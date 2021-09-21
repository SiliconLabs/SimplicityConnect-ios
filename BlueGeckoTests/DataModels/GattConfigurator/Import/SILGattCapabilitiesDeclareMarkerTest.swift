//
//  SILGattCapabilitiesDeclareMarkerTest.swift
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

class SILGattCapabilitiesDeclareMarkerTest : QuickSpec {
    private var testObject: SILGattCapabilitiesDeclareMarker!
    private var testedElement: AEXMLElement!
    
    private func containsCapability(entity: SILGattCapabilitiesDeclareEntity, name: String, enabled: Bool) -> Bool {
        return entity.capabilities.contains(where: { capability in capability.name == name && capability.enabled == enabled })
    }
    
    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }

        describe("should parse element to desired model entity") {
            it("should return error when xml name is wrong") {
                self.testedElement = AEXMLElement(name: "capabilities")

                let capabilityEnabled = AEXMLElement(name: "capability",
                                                     value: "first",
                                                     attributes: ["enable": "true"])
                let capabiiityDisabled = AEXMLElement(name: "capability",
                                                      value: "second",
                                                      attributes: ["enable": "false"])

                self.testedElement.addChildren([capabilityEnabled, capabiiityDisabled])

                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong xml element name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element with capability enabled and disabled") {
                self.testedElement = AEXMLElement(name: "capabilities_declare")

                let capabilityEnabled = AEXMLElement(name: "capability",
                                                     value: "first",
                                                     attributes: ["enable": "true"])
                let capabiiityDisabled = AEXMLElement(name: "capability",
                                                      value: "second",
                                                      attributes: ["enable": "false"])

                self.testedElement.addChildren([capabilityEnabled, capabiiityDisabled])

                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.capabilities.count).to(equal(2))
                    expect(self.containsCapability(entity: entity, name: "first", enabled: true)).to(equal(true))
                    expect(self.containsCapability(entity: entity, name: "second", enabled: false)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
            
            it("import element with capability without attribute") {
                self.testedElement = AEXMLElement(name: "capabilities_declare")

                let capabilityEnabled = AEXMLElement(name: "capability",
                                                     value: "first")

                self.testedElement.addChild(capabilityEnabled)

                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.capabilities.count).to(equal(1))
                    expect(self.containsCapability(entity: entity, name: "first", enabled: true)).to(equal(true))

                case let .failure(error):
                    fail(error.localizedDescription)
                }
            }
        }
        
        describe("should fail on parsing marker") {
            it("fail on capabilities with attributes") {
                let attributes = ["authenticated": "true"]
                self.testedElement = AEXMLElement(name: "capabilities", value: nil, attributes: attributes)

                let capability = AEXMLElement(name: "capability", value: "feature_1")

                self.testedElement.addChild(capability)

                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Marker shouldn't have any attributes")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("fail on wrong element name") {
                self.testedElement = AEXMLElement(name: "capabilities")

                let capability = AEXMLElement(name: "feature_1")

                self.testedElement.addChild(capability)

                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Marker name not allowed")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("fail on capabilities doesn't have any children") {
                self.testedElement = AEXMLElement(name: "capabilities")

                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Marker should have any children")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("fail on capabilities with too many children") {
                self.testedElement = AEXMLElement(name: "capabilities")

                for i in 0...16 {
                    let capability = AEXMLElement(name: "feature_\(i)")
                    self.testedElement.addChild(capability)
                }

                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many capbilities in list")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }

            it("fail on capability with not allowed attribute") {
                self.testedElement = AEXMLElement(name: "capabilities")

                let attributes = ["authenticated": "true"]
                let capability = AEXMLElement(name: "capability", value: "feature_1", attributes: attributes)

                self.testedElement.addChild(capability)

                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)

                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Capability has not allowed attribute")

                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("fail on capability with not allowed name") {
                self.testedElement = AEXMLElement(name: "capabilities")
            
                let capability = AEXMLElement(name: "capability", value: "feature+1")
                
                self.testedElement.addChild(capability)
                
                self.testObject = SILGattCapabilitiesDeclareMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Capability has not allowed name")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
    }
}
