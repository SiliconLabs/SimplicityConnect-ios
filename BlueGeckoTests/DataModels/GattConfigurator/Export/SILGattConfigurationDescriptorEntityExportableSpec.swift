//
//  SILGattConfigurationDescriptorEntityExportableSpec.swift
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

class SILGattConfigurationDescriptorEntityExportableSpec: QuickSpec {
    
    override func spec() {
        let falseString = SILGattConfiguratorXmlDatabase.falseString
        let trueString = SILGattConfiguratorXmlDatabase.trueString
        
        context("SILGattConfigurationDescriptorEntity") {
            var descriptor: SILGattConfigurationDescriptorEntity!
            var xmlElementResult: AEXMLElement?
            
            let nameAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.nameAttribute
            let uuidAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.uuidAttribute
            let lengthAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.lengthAttribute
            let variableLengthAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.variableLengthAttribute
            let typeAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.typeAttribute
            
            let propertiesName = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.propertiesName
            let valueChildName = SILGattConfiguratorXmlDatabase.GattConfigurationValue.name
            
            describe("not imported SILGattConfigurationDescriptorEntity") {
                let initialValue = "N/A - managed by system"
                let name = "Characteristic User Description"
                let uuid = "2901"
                let properties = [SILGattConfigurationProperty(type: .read, permission: .bonded), SILGattConfigurationProperty(type: .write, permission: .none)]
                
                beforeEach {
                    descriptor = SILGattConfigurationDescriptorEntity()
                    descriptor.initialValueType = .text
                    descriptor.initialValue = initialValue
                    descriptor.cbuuidString = uuid
                    descriptor.name = name
                    descriptor.canBeModified = true
                    descriptor.properties = properties
                    xmlElementResult = descriptor.export()
                }
                
                it("should return proper format") {
                    expect(xmlElementResult).notTo(beNil())
                    expect(xmlElementResult!.xmlCompact).to(equal("""
<descriptor name="\(name)" uuid="\(uuid)">
<properties>
<read authenticated="false" bonded="true" encrypted="false" />
<write authenticated="false" bonded="false" encrypted="false" />
</properties>
<value length="\(initialValue.utf8.count)" type="utf-8" variable_length="true">\(initialValue)</value>
</descriptor>
""".replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\n", with: "")))
                }
                
                it("should have 2 attributes and 2 children") {
                    expect(xmlElementResult?.children.count).to(equal(2))
                    expect(xmlElementResult?.attributes.count).to(equal(2))
                }
                
                it("should have child node name properties with two properties") {
                    let propertiesChild = xmlElementResult?[propertiesName]
                    expect(propertiesChild).notTo(beNil())
                    expect(propertiesChild!.children.count).to(equal(2))
                    expect(propertiesChild![SILGattConfiguratorXmlDatabase.GattConfigurationProperty.readName]).notTo(beNil())
                    expect(propertiesChild![SILGattConfiguratorXmlDatabase.GattConfigurationProperty.writeName]).notTo(beNil())
                }
                
                it("should have child node value") {
                    let valueChild = xmlElementResult?[SILGattConfiguratorXmlDatabase.GattConfigurationValue.name]
                    expect(valueChild).notTo(beNil())
                }
                
                it("should have name attribute set as Characteristic User Description") {
                    expect(xmlElementResult!.attributes[nameAttribute.name]).to(equal(name))
                }
                
                it("should have uuid attribute set as 2901") {
                    expect(xmlElementResult!.attributes[uuidAttribute.name]).to(equal(uuid))
                }
                
                it("should not have name attribute when name is nil") {
                    descriptor.name = nil
                    xmlElementResult = descriptor.export()
                    expect(xmlElementResult!.attributes[nameAttribute.name]).to(beNil())
                }
                
                it("should not import any property except write and read") {
                    descriptor.properties = [SILGattConfigurationProperty(type: .write, permission: .none), SILGattConfigurationProperty(type: .notify, permission: .none)]
                    xmlElementResult = descriptor.export()
                    let propertiesChild = xmlElementResult?[propertiesName]
                    expect(propertiesChild?.children.count).to(equal(1))
                    expect(propertiesChild?[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.writeName].error).to(beNil())
                    expect(propertiesChild?[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.notifyName].error).to(equal(AEXMLError.elementNotFound))
                }
                
                it("should contain value child") {
                    expect(xmlElementResult?.children.first(where: { child in child.name == "value" })).notTo(beNil())
                }
                
            }
            
            it("should not have value child when initial value is nil and type is none") {
                descriptor = SILGattConfigurationDescriptorEntity()
                descriptor.initialValue = nil
                descriptor.initialValueType = .none
                descriptor.cbuuidString = UUID().uuidString
                descriptor.properties = [SILGattConfigurationProperty(type: .write, permission: .none)]
                xmlElementResult = descriptor.export()
                expect(xmlElementResult?.children.count).to(equal(1))
                expect(xmlElementResult?[propertiesName].error).to(beNil())
                expect(xmlElementResult?[valueChildName].error).to(equal(AEXMLError.elementNotFound))
            }
                
            describe("imported SILGattConfigurationCharacteristicEntity") {
                let initialValue = "N/A - managed by system"
                let uuid = UUID().uuidString
                let properties = [SILGattConfigurationProperty(type: .read, permission: .bonded), SILGattConfigurationProperty(type: .write, permission: .none)]
                let importedLength = "20"
                let constAttribute = SILGattXMLAttribute(name: "const", value: falseString)
                let discoverableAttribute = SILGattXMLAttribute(name: "discoverable", value: trueString)
                let sourceIdAttribute = SILGattXMLAttribute(name: "sourceId", value: "")
                
                beforeEach {
                    descriptor = SILGattConfigurationDescriptorEntity()
                    descriptor.initialValueType = .text
                    descriptor.initialValue = initialValue
                    descriptor.cbuuidString = uuid
                    descriptor.properties = properties
                    descriptor.canBeModified = false
                    descriptor.additionalXmlChildren = [AEXMLElement(name: SILGattConfiguratorXmlDatabase.GattConfigurationValue.name, value: nil, attributes: [
                        lengthAttribute.name: importedLength,
                        typeAttribute.name: SILGattConfiguratorXmlDatabase.GattConfigurationValue.hexTypeString,
                        variableLengthAttribute.name: SILGattConfiguratorXmlDatabase.trueString
                    ])]
                    descriptor.additionalXmlAttributes = [
                        constAttribute,
                        discoverableAttribute,
                        sourceIdAttribute
                    ]
                    xmlElementResult = descriptor.export()
                }
                
                it("should have 5 attributes and 1 children") {
                    expect(xmlElementResult?.children.count).to(equal(1))
                    expect(xmlElementResult?.attributes.count).to(equal(4))
                }
                
                it("should have uuid attribute set as random uuid") {
                    expect(xmlElementResult!.attributes[uuidAttribute.name]).to(equal(uuid))
                }
                
                it("should have const attribute proper set") {
                    expect(xmlElementResult!.attributes[constAttribute.name]).to(equal(constAttribute.value))
                }
                
                it("should have discoverable attribute proper set") {
                    expect(xmlElementResult!.attributes[discoverableAttribute.name]).to(equal(discoverableAttribute.value))
                }
                
                it("should have sourceId attribute proper set") {
                    expect(xmlElementResult!.attributes[sourceIdAttribute.name]).to(equal(sourceIdAttribute.value))
                }
                
                it("should not contain value child") {
                    expect(xmlElementResult?.children.first?.name).notTo(equal("value"))
                }
            }
        }
    }
}
