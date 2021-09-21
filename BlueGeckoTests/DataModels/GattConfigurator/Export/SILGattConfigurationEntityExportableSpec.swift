//
//  SILGattConfigurationEntityExportableSpec.swift
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

class SILGattConfigurationEntityExportableSpec: QuickSpec {
    
    override func spec() {
        let falseString = SILGattConfiguratorXmlDatabase.falseString
        
        let primaryTypeString = SILGattConfiguratorXmlDatabase.GattConfigurationService.primaryType
        
        context("SILGattConfigurationEntity") {
            var configuration: SILGattConfigurationEntity!
            var xmlElementResult: AEXMLElement?
            var gattMarkerXmlResult: AEXMLElement?
            
            let outAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.outAttribute
            let headerAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.headerAttribute
            let nameAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.nameAttribute
            let prefixAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.prefixAttribute
            let genericAttributeServiceAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.genericAttributeServiceAttribute

            describe("not imported SILGattConfigurationEntity") {
                let serviceName = "Generic Access"
                let serviceUuid = "1800"
                
                let characteristicInitialValue = "value"
                let characteristicName = "Appearance"
                let characteristicUuid = "2A01"
                
                let descriptorUuid = UUID().uuidString
                
                var descriptor: SILGattConfigurationDescriptorEntity!
                var characteristic: SILGattConfigurationCharacteristicEntity!
                var service: SILGattConfigurationServiceEntity!
                
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
                    
                    service = SILGattConfigurationServiceEntity()
                    service.name = serviceName
                    service.cbuuidString = serviceUuid
                    service.isPrimary = true
                    service.characteristics.append(characteristic)
                    
                    configuration = SILGattConfigurationEntity()
                    configuration.services.append(service)
                    
                    var projectEntity = SILGattProjectEntity()
                    projectEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: "device", value: "iOS"))
                    
                    configuration.projectEntity = projectEntity
                    
                    xmlElementResult = configuration.export()
                    gattMarkerXmlResult = xmlElementResult?.children.first
                }
                
                it("should return proper format") {
                    debugPrint(xmlElementResult!.xml as NSString)
                    expect(xmlElementResult).notTo(beNil())
                    expect(xmlElementResult!.xmlCompact).to(equal("""
<project device="iOS">
    <gatt generic_attribute_service="\(genericAttributeServiceAttribute.defaultValue!)" header="\(headerAttribute.defaultValue!)" name="\(nameAttribute.defaultValue!)" out="\(outAttribute.defaultValue!)" prefix="\(prefixAttribute.defaultValue!)">
        <service name="\(serviceName)" type="\(primaryTypeString)" uuid="\(serviceUuid)">
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
        </service>
    </gatt>
</project>
""".replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "    ", with: "")))
                }
                
                it("should root element to be project and has one children") {
                    expect(xmlElementResult?.name).to(equal("project"))
                    expect(xmlElementResult?.children.count).to(equal(1))
                }
                
                it("should have 5 attributes and 1 child") {
                    expect(gattMarkerXmlResult?.attributes.count).to(equal(5))
                    expect(gattMarkerXmlResult?.children.count).to(equal(1))
                }
                
                it("should have one service child nodes") {
                    expect(gattMarkerXmlResult?[SILGattConfiguratorXmlDatabase.GattConfigurationService.name].count).to(equal(1))
                }
                
                it("should have out attribute proper set") {
                    expect(gattMarkerXmlResult!.attributes[outAttribute.name]).to(equal(outAttribute.defaultValue!))
                }
                
                it("should have header attribute proper set") {
                    expect(gattMarkerXmlResult!.attributes[headerAttribute.name]).to(equal(headerAttribute.defaultValue!))
                }
                
                it("should have name attribute proper set") {
                    expect(gattMarkerXmlResult!.attributes[nameAttribute.name]).to(equal(nameAttribute.defaultValue!))
                }
                
                it("should have prefix attribute proper set") {
                    expect(gattMarkerXmlResult!.attributes[prefixAttribute.name]).to(equal(prefixAttribute.defaultValue!))
                }
                
                it("should have genericAttributeService attribute proper set") {
                    expect(gattMarkerXmlResult!.attributes[genericAttributeServiceAttribute.name]).to(equal(genericAttributeServiceAttribute.defaultValue!))
                }
                
                it("should have two services child when second is appended") {
                    let secondService = SILGattConfigurationServiceEntity()
                    secondService.cbuuidString = UUID().uuidString
                    secondService.name = nil
                    secondService.isPrimary = true
                    
                    configuration.services.append(secondService)
                    xmlElementResult = configuration.export()
                    gattMarkerXmlResult = xmlElementResult?.children.first
                    expect(gattMarkerXmlResult?[SILGattConfiguratorXmlDatabase.GattConfigurationService.name].count).to(equal(2))
                }
            }
                
            describe("imported SILGattConfigurationEntity") {
                
                let importedOutAttribute = SILGattXMLAttribute(name: outAttribute.name, value: "custom_gatt_db.c")
                let importedHeaderAttribute = SILGattXMLAttribute(name: headerAttribute.name, value: "custom_gatt_db.h")
                let importedPrefixAttribute = SILGattXMLAttribute(name: prefixAttribute.name, value: "custom_")
                let importedGenericAttributeServiceAttribute = SILGattXMLAttribute(name: genericAttributeServiceAttribute.name, value: falseString)
                let importedInAttribute = SILGattXMLAttribute(name: "in", value: "input.txt")
                let importedGattCachingAttribute = SILGattXMLAttribute(name: "gatt_caching", value: falseString)
                let importedIdAttribute = SILGattXMLAttribute(name: "id", value: "5")
                
                let capabilitesXMLNode = AEXMLElement(name: "capabilities")
                capabilitesXMLNode.addChild(name: "capability", value: "custom_capability", attributes: [:])
                capabilitesXMLNode.addChild(name: "capability", value: "custom_capability2", attributes: [:])
                
                var service: SILGattConfigurationServiceEntity!


                beforeEach {
                    configuration = SILGattConfigurationEntity()
                    configuration.name = "custom_gattdb"
                    
                    configuration.additionalXmlChildren = [
                        capabilitesXMLNode
                    ]
                    
                    configuration.additionalXmlAttributes = [
                        importedOutAttribute,
                        importedHeaderAttribute,
                        importedPrefixAttribute,
                        importedGenericAttributeServiceAttribute,
                        importedInAttribute,
                        importedGattCachingAttribute,
                        importedIdAttribute
                    ]
                    
                    service = SILGattConfigurationServiceEntity()
                    service.name = "service"
                    service.cbuuidString = UUID().uuidString
                    service.isPrimary = true
                    configuration.services.append(service)

                    xmlElementResult = configuration.export()
                }

                it("should have 5 attributes and 2 children") {
                    expect(xmlElementResult?.attributes.count).to(equal(8))
                    expect(xmlElementResult?.children.count).to(equal(2))
                }

                it("should have one service child nodes") {
                    expect(xmlElementResult?[SILGattConfiguratorXmlDatabase.GattConfigurationService.name].count).to(equal(1))
                }
                
                it("should have out attribute proper set") {
                    expect(xmlElementResult!.attributes[importedOutAttribute.name]).to(equal(importedOutAttribute.value))
                }
                
                it("should have header attribute proper set") {
                    expect(xmlElementResult!.attributes[importedHeaderAttribute.name]).to(equal(importedHeaderAttribute.value))
                }
                
                it("should have name attribute proper set") {
                    expect(xmlElementResult!.attributes["name"]).to(equal("custom_gattdb"))
                }
                
                it("should have prefix attribute proper set") {
                    expect(xmlElementResult!.attributes[importedPrefixAttribute.name]).to(equal(importedPrefixAttribute.value))
                }
                
                it("should have genericAttributeService attribute proper set") {
                    expect(xmlElementResult!.attributes[importedGenericAttributeServiceAttribute.name]).to(equal(importedGenericAttributeServiceAttribute.value))
                }
                
                it("should have in attribute proper set") {
                    expect(xmlElementResult!.attributes[importedInAttribute.name]).to(equal(importedInAttribute.value))
                }
                
                it("should have gatt_caching attribute proper set") {
                    expect(xmlElementResult!.attributes[importedGattCachingAttribute.name]).to(equal(importedGattCachingAttribute.value))
                }

                it("should have id attribute proper set") {
                    expect(xmlElementResult!.attributes[importedIdAttribute.name]).to(equal(importedIdAttribute.value))
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
