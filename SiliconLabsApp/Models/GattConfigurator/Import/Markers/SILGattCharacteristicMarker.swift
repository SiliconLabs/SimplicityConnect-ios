//
//  SILGattCharacteristicMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 31.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattCharacteristicMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    var gattAssignedRepository: SILGattAssignedNumbersRepository
    
    typealias GattConfigurationEntity = SILGattConfigurationCharacteristicEntity
    
    private let additionalAllowedChildrenNames = ["capabilities", "properties", "value", "descriptor", "informativeText", "description", "aggregate"]
    private let allowedAttributes = ["uuid", "id", "sourceId", "name", "const", "instance_id"]
    let helper = SILGattImportHelper.shared
    private var capabilitiesDeclareEntity: SILGattCapabilitiesDeclareEntity!
    
    init(element: AEXMLElement, gattAssignedRepository: SILGattAssignedNumbersRepository) {
        self.element = element
        self.gattAssignedRepository = gattAssignedRepository
    }
    
    // Due to requirements - capabilities aren't hiding elements, it is only checked if characteristic contains only inherited capabilities
    mutating func parse(withCapabilites capabilites: SILGattCapabilitiesDeclareEntity) -> Result<SILGattConfigurationCharacteristicEntity, SILGattXmlParserError> {
        guard element.name == "characteristic" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<characteristic>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "capabilities", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<capabilities>", inMarker: "<characteristic>")))
        }
        
        guard let _ = helper.firstChild(in: element, withName: "properties") else {
            return .failure(.parsingError(description: helper.errorMissingElement(name: "properties", inMarker: "<characteristic>")))
        }
        
        if capabilites.capabilities.isEmpty {
            return self.parse()
        } else {
            if let capabilitiesChild = helper.firstChild(in: element, withName: "capabilities") {
                let capabilitiesMarker = SILGattCapabilitiesMarker(element: capabilitiesChild)
                let result = capabilitiesMarker.parse()
                
                switch result {
                case let .success(capabilitiesEntity):
                    let result = self.matchCapabilitesWithInherited(capabilitiesEntity, inherited: capabilites)
                    switch result {
                    case let .success(entity):
                        capabilitiesDeclareEntity = entity
                    
                    case let .failure(error):
                        return .failure(error)
                    }
                    
                    return self.parse()
                    
                case let .failure(error):
                    return .failure(error)
                }
            }
        }
        
        return self.parse()
    }
    
    func parse() -> Result<SILGattConfigurationCharacteristicEntity, SILGattXmlParserError> {
        var characteristicEntity = SILGattConfigurationCharacteristicEntity()
        characteristicEntity.name = "Unknown Characteristic"
        characteristicEntity.initialValue = ""
        characteristicEntity.initialValueType = .none
        characteristicEntity.fixedVariableLength = false
        characteristicEntity.cbuuidString = ""
        characteristicEntity.additionalXmlChildren = [AEXMLElement]()
        characteristicEntity.additionalXmlAttributes = [SILGattXMLAttribute]()
        characteristicEntity.properties = [SILGattConfigurationProperty]()
        characteristicEntity.descriptors = List<SILGattConfigurationDescriptorEntity>()
        
        guard element.name == "characteristic" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<characteristic>")))
        }
        
        guard helper.containsAttribute(in: element, withName: "uuid") else {
            return .failure(.parsingError(description: helper.errorMissingAttribute(name: "uuid", inMarker: "<characteristic>")))
        }
        
        for (_, attribute) in element.attributes.enumerated() {
            let attributeName = attribute.key as String
            let attributeValue = attribute.value as String
            
            if attributeName == "name" {
                characteristicEntity.name = attributeValue
            } else if attributeName == "uuid" {
                guard helper.validateUUID(stringUUID: attributeValue) else {
                    return .failure(.parsingError(description: helper.errorInvalidUUID(stringUUID: attributeValue, inMarker: "<characteristic>")))
                }
                
                characteristicEntity.cbuuidString = attributeValue.hasPrefix("0x") ? String(attributeValue.dropFirst(2)) : attributeValue
            } else if attributeName == "const" {
                guard helper.isAttributeValueBoolean(attributeValue) else {
                    return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<characteristic>")))
                }
                
                characteristicEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            } else if allowedAttributes.contains(attributeName) {
                characteristicEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<characteristic>")))
            }
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "capabilities", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<capabilities>", inMarker: "<characteristic>")))
        }
        
        guard let _ = helper.firstChild(in: element, withName: "properties") else {
            return .failure(.parsingError(description: helper.errorMissingElement(name: "properties", inMarker: "<characteristic>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "properties", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<properties>", inMarker: "<characteristic>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "value", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<value>", inMarker: "<characteristic>")))
        }
                
        guard helper.hasLessOrEqualThanChild(element: element, childName: "informativeText", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<informativeText>", inMarker: "<characteristic>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "description", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<description>", inMarker: "<characteristic>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "aggregate", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<aggregate>", inMarker: "<characteristic>")))
        }
        
        for child in element.children {
            if child.name == "descriptor" {
                let descriptorMarker = SILGattDescriptorMarker(element: child, gattAssignedRepository: gattAssignedRepository)
                let result = descriptorMarker.parse()
                switch result {
                case let .success(descriptorEntity):
                    characteristicEntity.descriptors.append(descriptorEntity)
                case let .failure(error):
                    return .failure(error)
                }
            } else if child.name == "aggregate" {
                // Simplicity Studio requires at least 2 attributes on aggregate list
                guard !helper.hasLessOrEqualThanChild(element: child, childName: "attribute", count: 1) else {
                    return .failure(.parsingError(description: "Aggregate arribute list must be at least 2 attributes long"))
                }
                
                if helper.isAggregateCharacteristicMarkerCorrect(element: child) {
                    characteristicEntity.additionalXmlChildren.append(child)
                } else {
                    return .failure(.parsingError(description: "Aggregate is invalid"))
                }
            } else if child.name == "properties" {
                let propertiesMarker = SILGattPropertiesMarker(element: child)
                let result = propertiesMarker.parse()
                switch result {
                case let .success(propertiesEntity):
                    characteristicEntity.properties = propertiesEntity.properties
                    for additionalChild in propertiesEntity.additionalXmlChildren {
                        characteristicEntity.additionalXmlChildren.append(additionalChild)
                    }
                    for additionalAttribute in propertiesEntity.additionalXmlAttributes {
                        characteristicEntity.additionalXmlAttributes.append(additionalAttribute)
                    }
                case let .failure(error):
                    return .failure(error)
                }

            } else if child.name == "value" {
                let valueMarker = SILGattValueMarker(element: child)
                let result = valueMarker.parse()
                switch result {
                case let .success(valueEntity):
                    characteristicEntity.initialValue = valueEntity.value
                    characteristicEntity.initialValueType = valueEntity.valueType
                    characteristicEntity.fixedVariableLength = valueEntity.fixedVariableLength
                    for valueAttribute in valueEntity.additionalXmlAttributes {
                        characteristicEntity.additionalXmlAttributes.append(valueAttribute)
                    }
                    
                case let .failure(error):
                    return .failure(error)
                }
                
            } else if additionalAllowedChildrenNames.contains(child.name) {
                characteristicEntity.additionalXmlChildren.append(child)
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedChildName(inMarker: "<characteristic>", childName: child.name)))
            }
        }
        
        if let namedCharacteristic = gattAssignedRepository.getCharacteristic(byUuid: characteristicEntity.cbuuidString) {
            characteristicEntity.name = namedCharacteristic.name
        }
        
        SILDefaultDescriptorsHelper.addDefaultIosDescriptorsIfNeeded(forCharacteristic: characteristicEntity, isImportActive: true)
        
        return .success(characteristicEntity)
    }
    
    private func matchCapabilitesWithInherited(_ capabilitesEntity: SILGattCapabilitiesEntity, inherited: SILGattCapabilitiesDeclareEntity) ->  Result<SILGattCapabilitiesDeclareEntity, SILGattXmlParserError> {
        var supportedCapabilities = [SILGattCapabilityEntity]()
        
        for name in capabilitesEntity.capabilityNames {
            if let capability = inherited.capabilities.first(where: { capability in capability.name == name }) {
                supportedCapabilities.append(capability)
            } else {
                return .failure(.parsingError(description: "Not inherited capability \(name) in the <characteristic> marker"))
            }
        }
        
        return .success(SILGattCapabilitiesDeclareEntity(capabilities: supportedCapabilities))
    }
}
