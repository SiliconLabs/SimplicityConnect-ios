//
//  SILGattConfigurationPropertyExportableSpec.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 22/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@testable import BlueGecko

import Foundation
import Quick
import Nimble
import RealmSwift
import AEXML

class SILGattConfigurationPropertyExportableSpec: QuickSpec {
    
    override func spec() {
        let falseString = SILGattConfiguratorXmlDatabase.falseString
        let trueString = SILGattConfiguratorXmlDatabase.trueString
        
        let encryptedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.encryptedAttribute
        let authenticatedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.authenticatedAttribute
        let bondedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.bondedAttribute
        
        context("SILGattConfigurationProperty") {
            var configurationProperty: SILGattConfigurationProperty!
            
            
            describe("is not imported") {
                var xmlElementResult: AEXMLElement!
                beforeEach {
                    configurationProperty = SILGattConfigurationProperty(type: .read, permission: .none)
                    xmlElementResult = configurationProperty.export()
                }
                
                it("should have empty attributes and children") {
                    expect(configurationProperty.additionalXmlChildren).to(beEmpty())
                    expect(configurationProperty.additionalXmlAttributes).to(beEmpty())
                }
                
                it("should have attributes authenticated and encrypted as false") {
                    expect(xmlElementResult!.attributes[encryptedAttribute.name]).to(equal(falseString))
                    expect(xmlElementResult!.attributes[authenticatedAttribute.name]).to(equal(falseString))
                }
                
                it("should have 3 attributes") {
                    expect(xmlElementResult.attributes.count).to(equal(3))
                }
                
                it("should have right property name") {
                    expect(xmlElementResult.name).to(equal("read"))
                }
                
                it("should have right property name for writeWithoutResponse") {
                    configurationProperty = SILGattConfigurationProperty(type: .writeWithoutResponse, permission: .none)
                    xmlElementResult = configurationProperty.export()
                    expect(xmlElementResult.name).to(equal("write_no_response"))
                }
                
                it("should have bonded set to true when permisson is set to bonded") {
                    configurationProperty = SILGattConfigurationProperty(type: .writeWithoutResponse, permission: .bonded)
                    xmlElementResult = configurationProperty.export()
                    expect(xmlElementResult!.attributes[bondedAttribute.name]).to(equal(trueString))
                }
                
                it("xml should have proper form") {
                    expect(xmlElementResult.xml).to(equal("<read authenticated=\"false\" bonded=\"false\" encrypted=\"false\" />"))
                }
            }
            
            describe("is imported") {
                var xmlElementResult: AEXMLElement!
                let additionalAttributes = [
                    SILGattXMLAttribute(name: bondedAttribute.name, value: falseString),
                    SILGattXMLAttribute(name: authenticatedAttribute.name, value: trueString),
                    SILGattXMLAttribute(name: encryptedAttribute.name, value: trueString)
                ]
                beforeEach {
                    configurationProperty = SILGattConfigurationProperty(type: .writeWithoutResponse, permission: .bonded)
                    configurationProperty.additionalXmlAttributes.append(contentsOf: additionalAttributes)
                    xmlElementResult = configurationProperty.export()
                }
                
                it("should have 3 attributes and none child") {
                    expect(configurationProperty.additionalXmlChildren).to(beEmpty())
                    expect(configurationProperty.additionalXmlAttributes.count).to(equal(3))
                }
                
                it("should have attributes authenticated and encrypted as true") {
                    expect(xmlElementResult!.attributes[encryptedAttribute.name]).to(equal(trueString))
                    expect(xmlElementResult!.attributes[authenticatedAttribute.name]).to(equal(trueString))
                }
                
                it("should have attribute bonded not from additionalAttributes") {
                    expect(xmlElementResult!.attributes[bondedAttribute.name]).notTo(equal(falseString))
                    expect(xmlElementResult!.attributes[bondedAttribute.name]).to(equal(trueString))
                }
                
                it("xml should have proper form") {
                    expect(xmlElementResult.xml).to(equal("<write_no_response authenticated=\"true\" bonded=\"true\" encrypted=\"true\" />"))
                }
            }
        }
    }
}
