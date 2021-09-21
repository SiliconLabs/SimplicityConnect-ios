//
//  SILGattConfigurationDescriptorEntity+SILGattXMLExportable.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 21/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

extension SILGattConfigurationDescriptorEntity: SILGattXmlExportable {
    
    private func divideAttributes(propertiesChildrenAttributes: inout [SILGattXMLAttribute], descriptorAttributes: inout [SILGattXMLAttribute], propertiesAttributes: inout [SILGattXMLAttribute]) {
        let allowedPropertiesNames =  SILGattConfiguratorXmlDatabase.GattConfigurationDescriptor.allowedPropertiesNames
    
        var aldreadyUsedIndices = [Int]()
        for (index, attribute) in self.additionalXmlAttributes.enumerated() {
            for propertyName in allowedPropertiesNames {
                if attribute.name.hasPrefix("\(propertyName)_") {
                    propertiesChildrenAttributes.append(attribute)
                    aldreadyUsedIndices.append(index)
                    break
                }
            }
        }
        
        for (index, attribute) in self.additionalXmlAttributes.enumerated() {
            if !aldreadyUsedIndices.contains(index) && attribute.name.hasPrefix("properties_") {
                propertiesAttributes.append(attribute)
                aldreadyUsedIndices.append(index)
            }
        }
        
        for (index, attribute) in self.additionalXmlAttributes.enumerated() {
            if !aldreadyUsedIndices.contains(index) && !attribute.name.hasPrefix("value_") {
                descriptorAttributes.append(attribute)
                aldreadyUsedIndices.append(index)
            }
        }
    }
        
    func export() -> AEXMLElement {
        let nameAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.nameAttribute
        let uuidAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.uuidAttribute
        let propertiesName = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.propertiesName
        
        let descriptorXML = AEXMLElement(name: SILGattConfiguratorXmlDatabase.GattConfigurationDescriptor.name, value: nil, attributes: [
            uuidAttribute.name: self.cbuuidString
        ])
        
        if let name = self.name {
            descriptorXML.attributes[nameAttribute.name] = name
        }
        
        var propertiesChildrenAttributes = [SILGattXMLAttribute]()
        var descriptorAttributes = [SILGattXMLAttribute]()
        var propertiesAttributes = [SILGattXMLAttribute]()
        divideAttributes(propertiesChildrenAttributes: &propertiesChildrenAttributes, descriptorAttributes: &descriptorAttributes, propertiesAttributes: &propertiesAttributes)
        
        for additionalAttribute in descriptorAttributes {
            descriptorXML.attributes[additionalAttribute.name] = additionalAttribute.value
        }
        
        if let informativeText = self.additionalXmlChildren.first(where: { child in child.name == "informativeText" }) {
            descriptorXML.addChild(informativeText)
        }
        
        descriptorXML.addChild(name: propertiesName)
        
        let prefix = "properties_"
        if let properties = descriptorXML.children.first(where: { child in child.name == "properties" }) {
            for attribute in propertiesAttributes {
                let attributeName = String(attribute.name.dropFirst(prefix.count))
                properties.attributes[attributeName] = attribute.value
            }
            
            if self.properties.count > 0 {
                for index in self.properties.indices {
                    var property = self.properties[index]
                    let propertyPrefix = "\(property.xmlNodeName)_"
                    var attributesOfProperty = property.additionalXmlAttributes
                    propertiesChildrenAttributes.filter({ $0.name.hasPrefix(propertyPrefix) })
                        .forEach( { attributesOfProperty.append(SILGattXMLAttribute(name: String($0.name.dropFirst(propertyPrefix.count)), value: $0.value)) })
                    property.additionalXmlAttributes = attributesOfProperty
                
                    if SILGattConfiguratorXmlDatabase.GattConfigurationDescriptor.allowedPropertiesNames.contains(property.xmlNodeName) {
                        properties.addChild(property.export())
                    }
                }
            }
        }
        
        if !(self.initialValue == "N/A - managed by system" && self.canBeModified == false) {
            let length = self.additionalXmlAttributes.first(where: { attribute in attribute.name == "value_length" })?.value ?? ""
            
            
            if let valueChild = SILGattConfiguratorExportValueHelper(node: self, initialValueType: self.initialValueType, initialValue: self.initialValue, fixedVariableLength: self.fixedVariableLength, length: length).export() {
                descriptorXML.addChild(valueChild)
            }
        }
        
        return descriptorXML
    }
}
