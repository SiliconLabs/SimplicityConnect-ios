//
//  SILGattConfigurationCharacteristicEntity+SILGattXMLExportable.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 22/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

extension SILGattConfigurationCharacteristicEntity: SILGattXmlExportable {
    
    private func addAdditionalNodesExceptReliableWrite(characteristicXML: AEXMLElement) {
        let reliableWritePropertyName = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.reliableWriteName
        for additionalNode in self.additionalXmlChildren {
            if !reliableWritePropertyName.contains(additionalNode.name) {
                characteristicXML.addChild(additionalNode)
            }
        }
    }
    
    private func addReliableWriteIfExists(propertiesXML: AEXMLElement) {
        let reliableWritePropertyName = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.reliableWriteName
        for additionalNode in self.additionalXmlChildren {
            if reliableWritePropertyName.contains(additionalNode.name) {
                propertiesXML.addChild(additionalNode)
            }
        }
    }
    
    private func divideAttributes(propertiesChildrenAttributes: inout [SILGattXMLAttribute], characteristicAttributes: inout [SILGattXMLAttribute], propertiesAttributes: inout [SILGattXMLAttribute]) {
        let allowedPropertiesNames =  SILGattConfiguratorXmlDatabase.GattConfigurationCharacteristic.allowedPropertiesNames
    
        var alreadyUsedIndices = [Int]()
        for (index, attribute) in self.additionalXmlAttributes.enumerated() {
            for propertyName in allowedPropertiesNames {
                if attribute.name.hasPrefix("\(propertyName)_") {
                    propertiesChildrenAttributes.append(attribute)
                    alreadyUsedIndices.append(index)
                    break
                }
            }
        }
        
        for (index, attribute) in self.additionalXmlAttributes.enumerated() {
            if !alreadyUsedIndices.contains(index) && attribute.name.hasPrefix("properties_") {
                propertiesAttributes.append(attribute)
                alreadyUsedIndices.append(index)
            }
        }
        
        for (index, attribute) in self.additionalXmlAttributes.enumerated() {
            if !alreadyUsedIndices.contains(index) && !attribute.name.hasPrefix("value_") {
                characteristicAttributes.append(attribute)
            }
        }
    }
        
    // divide on characteristic attributes, properties attributes, value attributes, properties children
    func export() -> AEXMLElement {
        let nameAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.nameAttribute
        let uuidAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.uuidAttribute
        let propertiesName = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.propertiesName
        
        let characteristicXML = AEXMLElement(name: SILGattConfiguratorXmlDatabase.GattConfigurationCharacteristic.name, value: nil, attributes: [
            uuidAttribute.name: self.cbuuidString
        ])
        
        if let name = self.name {
            characteristicXML.attributes[nameAttribute.name] = name
        }
        
        var propertiesChildrenAttributes = [SILGattXMLAttribute]()
        var characteristicAttributes = [SILGattXMLAttribute]()
        var propertiesAttributes = [SILGattXMLAttribute]()
        divideAttributes(propertiesChildrenAttributes: &propertiesChildrenAttributes, characteristicAttributes: &characteristicAttributes, propertiesAttributes: &propertiesAttributes)
        
        for additionalAttribute in characteristicAttributes {
            characteristicXML.attributes[additionalAttribute.name] = additionalAttribute.value
        }
        
        addAdditionalNodesExceptReliableWrite(characteristicXML: characteristicXML)
        
        characteristicXML.addChild(name: propertiesName)
        
        let prefix = "properties_"
        if let properties = characteristicXML.children.first(where: { child in child.name == "properties" }) {
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
                    
                    if SILGattConfiguratorXmlDatabase.GattConfigurationCharacteristic.allowedPropertiesNames.contains(property.xmlNodeName) {
                        properties.addChild(property.export())
                    }
                }
                addReliableWriteIfExists(propertiesXML: properties)
            }
        }
        
        let length = self.additionalXmlAttributes.first(where: { attribute in attribute.name == "value_length" })?.value ?? ""
        
        if let valueChild = SILGattConfiguratorExportValueHelper(node: self, initialValueType: self.initialValueType, initialValue: self.initialValue, fixedVariableLength: self.fixedVariableLength, length: length).export() {
            characteristicXML.addChild(valueChild)
        }
        
        for descriptor in self.descriptors {
            characteristicXML.addChild(descriptor.export())
        }
        
        return characteristicXML
    }
}
