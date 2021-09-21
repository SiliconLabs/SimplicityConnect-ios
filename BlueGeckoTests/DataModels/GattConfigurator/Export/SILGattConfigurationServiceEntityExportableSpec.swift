//
//  SILGattConfigurationServiceEntityExportableSpec.swift
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

class SILGattConfigurationServiceEntityExportableSpec: QuickSpec {
    
    override func spec() {
        let falseString = SILGattConfiguratorXmlDatabase.falseString
        let trueString = SILGattConfiguratorXmlDatabase.trueString
        
        context("SILGattConfigurationServiceEntity") {
            var service: SILGattConfigurationServiceEntity!
            var xmlElementResult: AEXMLElement?
            
            let nameAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.nameAttribute
            let uuidAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.uuidAttribute
            let typeAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationService.typeAttribute
            
            let primaryTypeString = SILGattConfiguratorXmlDatabase.GattConfigurationService.primaryType
            let secondaryTypeString = SILGattConfiguratorXmlDatabase.GattConfigurationService.secondaryType
            
            describe("not imported SILGattConfigurationServiceEntity") {
                let serviceName = "Generic Access"
                let serviceUuid = "1800"
                
                let characteristicInitialValue = "value"
                let characteristicName = "Appearance"
                let characteristicUuid = "2A01"
                let descriptorUuid = UUID().uuidString
                let secondCharacteristicUuid = UUID().uuidString
                var descriptor: SILGattConfigurationDescriptorEntity!
                var characteristic: SILGattConfigurationCharacteristicEntity!
                var secondCharacteristic: SILGattConfigurationCharacteristicEntity!
                
                beforeEach {
                    descriptor = SILGattConfigurationDescriptorEntity()
                    descriptor.initialValueType = .none
                    descriptor.initialValue = nil
                    descriptor.cbuuidString = descriptorUuid
                    descriptor.name = nil
                    descriptor.properties = [SILGattConfigurationProperty(type: .read, permission: .none)]
                    
                    characteristic = SILGattConfigurationCharacteristicEntity()
                    characteristic.initialValueType = .text
                    characteristic.initialValue = characteristicInitialValue
                    characteristic.cbuuidString = characteristicUuid
                    characteristic.name = characteristicName
                    characteristic.properties = [
                        SILGattConfigurationProperty(type: .read, permission: .bonded),
                        SILGattConfigurationProperty(type: .write, permission: .none),
                        SILGattConfigurationProperty(type: .notify, permission: .bonded)
                    ]
                    characteristic.descriptors.append(descriptor)
                    
                    secondCharacteristic = SILGattConfigurationCharacteristicEntity()
                    secondCharacteristic.initialValueType = .none
                    secondCharacteristic.initialValue = nil
                    secondCharacteristic.cbuuidString = secondCharacteristicUuid
                    secondCharacteristic.name = nil
                    secondCharacteristic.properties = [SILGattConfigurationProperty(type: .notify, permission: .none)]
                    
                    service = SILGattConfigurationServiceEntity()
                    service.name = serviceName
                    service.cbuuidString = serviceUuid
                    service.isPrimary = false
                    service.characteristics.append(characteristic)
                    service.characteristics.append(secondCharacteristic)
                    
                    xmlElementResult = service.export()
                }
                
                it("should return proper format") {
                    debugPrint(xmlElementResult!.xml as NSString)
                    expect(xmlElementResult).notTo(beNil())
                    expect(xmlElementResult!.xmlCompact).to(equal("""
<service name="\(serviceName)" type="\(secondaryTypeString)" uuid="\(serviceUuid)">
    <characteristic name="\(characteristicName)" uuid="\(characteristicUuid)">
        <properties>
            <read authenticated="false" bonded="true" encrypted="false" />
            <write authenticated="false" bonded="false" encrypted="false" />
            <notify authenticated="false" bonded="true" encrypted="false" />
        </properties>
        <value length="\(characteristicInitialValue.utf8.count)" type="utf-8" variable_length="true">\(characteristicInitialValue)</value>
        <descriptor uuid="\(descriptorUuid)">
            <properties>
                <read authenticated="false" bonded="false" encrypted="false" />
            </properties>
        </descriptor>
    </characteristic>
    <characteristic uuid="\(secondCharacteristicUuid)">
        <properties>
            <notify authenticated="false" bonded="false" encrypted="false" />
        </properties>
    </characteristic>
</service>
""".replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "    ", with: "")))
                }
                
                it("should have 3 attributes and 2 children") {
                    expect(xmlElementResult?.attributes.count).to(equal(3))
                    expect(xmlElementResult?.children.count).to(equal(2))
                }
                
                it("should have to charactieristic child nodes") {
                    expect(xmlElementResult?[SILGattConfiguratorXmlDatabase.GattConfigurationCharacteristic.name].count).to(equal(2))
                }
                
                it("should have name attribute set as GenericAccess") {
                    expect(xmlElementResult!.attributes[nameAttribute.name]).to(equal(serviceName))
                }
                
                it("should have uuid attribute set as 1800") {
                    expect(xmlElementResult!.attributes[uuidAttribute.name]).to(equal(serviceUuid))
                }
                
                it("should have type attribute set as secondary") {
                    expect(xmlElementResult!.attributes[typeAttribute.name]).to(equal(secondaryTypeString))
                }
                
                it("should not have name attribute when name is nil") {
                    service.name = nil
                    xmlElementResult = service.export()
                    expect(xmlElementResult!.attributes[nameAttribute.name]).to(beNil())
                }
                
                it("should have three characteristics when third is appended") {
                    let thirdCharacteristic = SILGattConfigurationCharacteristicEntity()
                    thirdCharacteristic.initialValueType = .none
                    thirdCharacteristic.initialValue = nil
                    thirdCharacteristic.cbuuidString = descriptorUuid
                    thirdCharacteristic.name = nil
                    thirdCharacteristic.properties = [SILGattConfigurationProperty(type: .write, permission: .none)]
                    
                    service.characteristics.append(thirdCharacteristic)
                    xmlElementResult = service.export()
                    expect(xmlElementResult?[SILGattConfiguratorXmlDatabase.GattConfigurationCharacteristic.name].count).to(equal(3))
                }
            }
                
            describe("imported SILGattConfigurationServiceEntity") {
                let uuid = UUID().uuidString

                let advertiseAttribute = SILGattXMLAttribute(name: "advertise", value: falseString)
                let idAttribute = SILGattXMLAttribute(name: "id", value: "custom_id")
                let requirementAttribute = SILGattXMLAttribute(name: "requirement", value: "mandatory")

                let informativeTextXMLNode = AEXMLElement(name: "informativeText", value: "Some info about service", attributes: [:])

                let capabilitesXMLNode = AEXMLElement(name: "capabilities")
                capabilitesXMLNode.addChild(name: "capability", value: "custom_capability", attributes: [:])

                beforeEach {
                    service = SILGattConfigurationServiceEntity()
                    service.cbuuidString = uuid
                    service.additionalXmlChildren = [
                        informativeTextXMLNode,
                        capabilitesXMLNode
                    ]
                    service.additionalXmlAttributes = [
                        advertiseAttribute,
                        idAttribute,
                        requirementAttribute
                    ]
                    service.isPrimary = true
                    
                    xmlElementResult = service.export()
                }

                it("should have 5 attributes and 3 children") {
                    expect(xmlElementResult?.attributes.count).to(equal(5))
                    expect(xmlElementResult?.children.count).to(equal(2))
                }

                it("should not have any characteristic child when there is no characteristic") {
                    expect(xmlElementResult?[SILGattConfiguratorXmlDatabase.GattConfigurationCharacteristic.name].error).to(equal(AEXMLError.elementNotFound))
                }

                it("should have uuid attribute set as random uuid") {
                    expect(xmlElementResult!.attributes[uuidAttribute.name]).to(equal(uuid))
                }
                
                it("should have type attribute set as primary") {
                    expect(xmlElementResult!.attributes[typeAttribute.name]).to(equal(primaryTypeString))
                }

                it("should have advertise attribute proper set") {
                    expect(xmlElementResult!.attributes[advertiseAttribute.name]).to(equal(advertiseAttribute.value))
                }

                it("should have id attribute proper set") {
                    expect(xmlElementResult!.attributes[idAttribute.name]).to(equal(idAttribute.value))
                }

                it("should have requirement attribute proper set") {
                    expect(xmlElementResult!.attributes[requirementAttribute.name]).to(equal(requirementAttribute.value))
                }

                it("should have informative text node") {
                    let informativeTextNode = xmlElementResult?[informativeTextXMLNode.name]
                    expect(informativeTextNode?.error).to(beNil())
                    expect(informativeTextNode?.xml).to(equal(informativeTextXMLNode.xml))
                }

                it("should have capabilites node") {
                    let capabilitiesNode = xmlElementResult?[capabilitesXMLNode.name]
                    expect(capabilitiesNode?.error).to(beNil())
                    expect(capabilitiesNode?.xmlCompact).to(equal(capabilitesXMLNode.xmlCompact))
                }
            }
        }
    }
}
