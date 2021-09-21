//
//  SILGattConfigurationCharacteristicEntityExportableSpec.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 22/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
@testable import BlueGecko

import Foundation
import Quick
import Nimble
import RealmSwift
import AEXML

class SILGattConfigurationCharacteristicEntityExportableSpec: QuickSpec {
    
    override func spec() {
        let falseString = SILGattConfiguratorXmlDatabase.falseString
        let trueString = SILGattConfiguratorXmlDatabase.trueString
        
        let encryptedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.encryptedAttribute
        let authenticatedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.authenticatedAttribute
        let bondedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.bondedAttribute
          
        context("SILGattConfigurationCharacteristicEntity") {
            var characteristic: SILGattConfigurationCharacteristicEntity!
            var xmlElementResult: AEXMLElement?
            
            let nameAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.nameAttribute
            let uuidAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.uuidAttribute
            
            let propertiesName = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.propertiesName
            let valueChildName = SILGattConfiguratorXmlDatabase.GattConfigurationValue.name
            
            describe("not imported SILGattConfigurationCharacteristicEntity") {
                let initialValue = "value"
                let name = "Alert Level"
                let characteristicUuid = "2A06"
                let descriptorUuid = UUID().uuidString
                let properties = [SILGattConfigurationProperty(type: .read, permission: .bonded),
                                  SILGattConfigurationProperty(type: .write, permission: .none),
                                  SILGattConfigurationProperty(type: .notify, permission: .bonded)
                ]
                let descriptor = SILGattConfigurationDescriptorEntity()
                
                beforeEach {
                    descriptor.initialValueType = .none
                    descriptor.initialValue = nil
                    descriptor.cbuuidString = descriptorUuid
                    descriptor.name = nil
                    descriptor.properties = [SILGattConfigurationProperty(type: .read, permission: .none)]
                    
                    characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.initialValueType = .text
                    characteristic.initialValue = initialValue
                    characteristic.cbuuidString = characteristicUuid
                    characteristic.name = name
                    characteristic.properties = properties
                    characteristic.descriptors.append(descriptor)
                    xmlElementResult = characteristic.export()
                }
                
                it("should return proper format") {
                    expect(xmlElementResult).notTo(beNil())
                    expect(xmlElementResult!.xmlCompact).to(equal("""
<characteristic name="\(name)" uuid="\(characteristicUuid)">
    <properties>
        <read authenticated="false" bonded="true" encrypted="false" />
        <write authenticated="false" bonded="false" encrypted="false" />
        <notify authenticated="false" bonded="true" encrypted="false" />
    </properties>
    <value length="\(initialValue.utf8.count)" type="utf-8" variable_length="true">\(initialValue)</value>
    <descriptor uuid="\(descriptorUuid)">
        <properties>
            <read authenticated="false" bonded="false" encrypted="false" />
        </properties>
    </descriptor>
</characteristic>
""".replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "    ", with: "")))
                }
                
                it("should have 2 attributes and 3 children") {
                    expect(xmlElementResult?.attributes.count).to(equal(2))
                    expect(xmlElementResult?.children.count).to(equal(3))
                }
                
                it("should have child node name properties with 3 properties") {
                    let propertiesChild = xmlElementResult![propertiesName]
                    expect(propertiesChild.error).to(beNil())
                    expect(propertiesChild.children.count).to(equal(3))
                    expect(propertiesChild[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.readName].error).to(beNil())
                    expect(propertiesChild[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.writeName].error).to(beNil())
                    expect(propertiesChild[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.notifyName].error).to(beNil())
                }
                
                it("should have child node value") {
                    let valueChild = xmlElementResult?[SILGattConfiguratorXmlDatabase.GattConfigurationValue.name]
                    expect(valueChild?.error).to(beNil())
                }
                
                it("should have name attribute set as Alert Level") {
                    expect(xmlElementResult!.attributes[nameAttribute.name]).to(equal(name))
                }
                
                it("should have uuid attribute set as 2A06") {
                    expect(xmlElementResult!.attributes[uuidAttribute.name]).to(equal(characteristicUuid))
                }
                
                it("should not have name attribute when name is nil") {
                    characteristic.name = nil
                    xmlElementResult = characteristic.export()
                    expect(xmlElementResult!.attributes[nameAttribute.name]).to(beNil())
                }
                
                it("should have two descriptors when second is appended") {
                    let secondDescriptor = SILGattConfigurationDescriptorEntity()
                    secondDescriptor.initialValueType = .none
                    secondDescriptor.initialValue = nil
                    secondDescriptor.cbuuidString = descriptorUuid
                    secondDescriptor.name = nil
                    secondDescriptor.properties = [SILGattConfigurationProperty(type: .write, permission: .none)]
                    
                    characteristic.descriptors.append(secondDescriptor)
                    xmlElementResult = characteristic.export()
                    expect(xmlElementResult?[SILGattConfiguratorXmlDatabase.GattConfigurationDescriptor.name].count).to(equal(2))
                }
            }
            
            it("should not have value child when initial value is nil and type is none") {
                characteristic = SILGattConfigurationCharacteristicEntity()
                characteristic.initialValue = nil
                characteristic.initialValueType = .none
                characteristic.cbuuidString = UUID().uuidString
                characteristic.properties = [SILGattConfigurationProperty(type: .write, permission: .none)]
                xmlElementResult = characteristic.export()
                expect(xmlElementResult?.children.count).to(equal(1))
                expect(xmlElementResult?[propertiesName].error).to(beNil())
                expect(xmlElementResult?[valueChildName].error).to(equal(AEXMLError.elementNotFound))
            }
                
            describe("imported SILGattConfigurationCharacteristicEntity") {
                let initialValue = "initial value"
                let uuid = UUID().uuidString
                let properties = [
                    SILGattConfigurationProperty(type: .read, permission: .bonded),
                    SILGattConfigurationProperty(type: .writeWithoutResponse, permission: .none),
                    SILGattConfigurationProperty(type: .indicate, permission: .none)
                ]
                
                let constAttribute = SILGattXMLAttribute(name: "const", value: falseString)
                let idAttribute = SILGattXMLAttribute(name: "id", value: "custom_id")
                let sourceIdAttribute = SILGattXMLAttribute(name: "sourceId", value: "")
                
                let descriptionXMLNode = AEXMLElement(name: "description", value: "custom description", attributes: [:])
                
                let capabilitesXMLNode = AEXMLElement(name: "capabilities")
                capabilitesXMLNode.addChild(name: "capability", value: "custom_capability", attributes: [:])
                
                let reliableWriteXMLNodeName = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.reliableWriteName
                let reliableWriteXMLNode = AEXMLElement(name: reliableWriteXMLNodeName, value: nil, attributes: [
                    authenticatedAttribute.name: falseString,
                    bondedAttribute.name: falseString,
                    encryptedAttribute.name: trueString
                ])
                
                beforeEach {
                    characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.initialValueType = .text
                    characteristic.initialValue = initialValue
                    characteristic.cbuuidString = uuid
                    characteristic.properties = properties
                    characteristic.additionalXmlChildren = [
                        descriptionXMLNode,
                        capabilitesXMLNode,
                        reliableWriteXMLNode
                    ]
                    characteristic.additionalXmlAttributes = [
                        constAttribute,
                        idAttribute,
                        sourceIdAttribute
                    ]
                    xmlElementResult = characteristic.export()
                    debugPrint(xmlElementResult!.xml as NSString)
                }
                
                it("should have 4 attributes and 4 children") {
                    expect(xmlElementResult?.attributes.count).to(equal(4))
                    expect(xmlElementResult?.children.count).to(equal(4))
                }
                
                it("should not have any descriptor child when there is no descriptors") {
                    expect(xmlElementResult?[SILGattConfiguratorXmlDatabase.GattConfigurationDescriptor.name].error).to(equal(AEXMLError.elementNotFound))
                }
                
                it("should have uuid attribute set as random uuid") {
                    expect(xmlElementResult!.attributes[uuidAttribute.name]).to(equal(uuid))
                }
                
                it("should have const attribute proper set") {
                    expect(xmlElementResult!.attributes[constAttribute.name]).to(equal(constAttribute.value))
                }
                
                it("should have id attribute proper set") {
                    expect(xmlElementResult!.attributes[idAttribute.name]).to(equal(idAttribute.value))
                }
                
                it("should have sourceId attribute proper set") {
                    expect(xmlElementResult!.attributes[sourceIdAttribute.name]).to(equal(sourceIdAttribute.value))
                }
                
                it("should have description node") {
                    let descriptionNode = xmlElementResult?[descriptionXMLNode.name]
                    expect(descriptionNode?.error).to(beNil())
                    expect(descriptionNode?.xml).to(equal(descriptionXMLNode.xml))
                }
                
                it("should have capabilites node") {
                    let capabilitiesNode = xmlElementResult?[capabilitesXMLNode.name]
                    expect(capabilitiesNode?.error).to(beNil())
                    expect(capabilitiesNode?.xmlCompact).to(equal(capabilitesXMLNode.xmlCompact))
                }
                
                it("should have child node name properties with 4 properties and one reliable write from import") {
                    let propertiesChild = xmlElementResult![propertiesName]
                    expect(propertiesChild.error).to(beNil())
                    expect(propertiesChild.children.count).to(equal(4))
                    expect(propertiesChild[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.readName].error).to(beNil())
                    expect(propertiesChild[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.indicateName].error).to(beNil())
                    expect(propertiesChild[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.writeNoResponseName].error).to(beNil())
                    
                    expect(propertiesChild[SILGattConfiguratorXmlDatabase.GattConfigurationProperty.reliableWriteName].error).to(beNil())
                }
            }
        }
        
    }
}
