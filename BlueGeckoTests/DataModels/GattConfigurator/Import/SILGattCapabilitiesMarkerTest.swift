//
//  SILGattCapabilitiesMarkerTest.swift
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

class SILGattCapabilitiesMarkerTest: QuickSpec {
    private var testObject: SILGattCapabilitiesMarker!
    private var testedElement: AEXMLElement!

    override func spec() {
        afterEach {
            self.testObject = nil
            self.testedElement = nil
        }
        
        describe("should parse element to desired model entity") {
            it("should return error when xml name is wrong") {
                self.testedElement = AEXMLElement(name: "feature")
                
                let capability = AEXMLElement(name: "capability", value: "feature_1")
                let capability2 = AEXMLElement(name: "capability", value: "feature_2")
                
                self.testedElement.addChildren([capability, capability2])
                self.testObject = SILGattCapabilitiesMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong xml element name!")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("import element with authenticated = false, bonded = false, encrypted = false for read marker") {
                self.testedElement = AEXMLElement(name: "capabilities")
                
                let capability = AEXMLElement(name: "capability", value: "feature_1")
                let capability2 = AEXMLElement(name: "capability", value: "feature_2")
                
                self.testedElement.addChildren([capability, capability2])
                self.testObject = SILGattCapabilitiesMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case let .success(entity):
                    expect(entity.capabilityNames.count).to(equal(2))
                    expect(entity.capabilityNames.contains("feature_1")).to(equal(true))
                    expect(entity.capabilityNames.contains("feature_2")).to(equal(true))
                    
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
                
                self.testObject = SILGattCapabilitiesMarker(element: self.testedElement)
                
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
                
                self.testObject = SILGattCapabilitiesMarker(element: self.testedElement)
                
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
          
                self.testObject = SILGattCapabilitiesMarker(element: self.testedElement)
                
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
                
                self.testObject = SILGattCapabilitiesMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Too many capbilities in list")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
            
            it("fail on wrong capability name") {
                self.testedElement = AEXMLElement(name: "capabilities")
          
                let capability = AEXMLElement(name: "feature+1")
                self.testedElement.addChild(capability)
                
                self.testObject = SILGattCapabilitiesMarker(element: self.testedElement)
                
                let result = self.testObject.parse()
                switch result {
                case .success(_):
                    fail("Wrong capability name")
                    
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
    }
}

