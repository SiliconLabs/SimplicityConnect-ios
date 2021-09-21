//
//  SILGattDescriptorMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 31.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattDescriptorMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    var gattAssignedRepository: SILGattAssignedNumbersRepository
    
    typealias GattConfigurationEntity = SILGattConfigurationDescriptorEntity
    
    private let additionalAllowedChildrenNames = ["informativeText"]
    private let allowedAtrributeNames = ["uuid", "id", "sourceId", "name", "const", "discoverable", "instance_id"]
    private let characteristicUserDescriptionUUID = "2901"
    private let characteristicPresentationFormatUUID = "2904"
    private let helper = SILGattImportHelper.shared
    
    func parse() -> Result<SILGattConfigurationDescriptorEntity, SILGattXmlParserError> {
        var descriptorEntity = SILGattConfigurationDescriptorEntity()
        descriptorEntity.name = "Unknown Descriptor"
        descriptorEntity.cbuuidString = ""
        descriptorEntity.initialValue = ""
        descriptorEntity.initialValueType = .none
        descriptorEntity.fixedVariableLength = false
        descriptorEntity.properties = [SILGattConfigurationProperty]()
        descriptorEntity.additionalXmlChildren = [AEXMLElement]()
        descriptorEntity.additionalXmlAttributes = [SILGattXMLAttribute]()

        guard element.name == "descriptor" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<descriptor>")))
        }
        
        guard helper.containsAttribute(in: element, withName: "uuid") else {
            return .failure(.parsingError(description: helper.errorMissingAttribute(name: "uuid", inMarker: "<descriptor>")))
        }
        
        for (_, attribute) in element.attributes.enumerated() {
            let attributeName = attribute.key as String
            let attributeValue = attribute.value as String
            
            if attributeName == "name" {
                descriptorEntity.name = attributeValue
            } else if attributeName == "uuid" {
                guard helper.validateUUID(stringUUID: attributeValue) else {
                    return .failure(.parsingError(description: helper.errorInvalidUUID(stringUUID: attributeValue, inMarker: "<descriptor>")))
                }
                
                descriptorEntity.cbuuidString = attributeValue.hasPrefix("0x") ? String(attributeValue.dropFirst(2)) : attributeValue
            } else if attributeName == "const" || attributeName == "discoverable" {
                guard helper.isAttributeValueBoolean(attributeValue) else {
                    return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<descriptor>")))
                }
                    
                descriptorEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            } else if allowedAtrributeNames.contains(attributeName) {
                descriptorEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<descriptor>")))
            }
        }
        
        guard let _ = helper.firstChild(in: element, withName: "properties") else {
            return .failure(.parsingError(description: helper.errorMissingElement(name: "properties", inMarker: "<descriptor>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "properties", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<properties>", inMarker: "<descriptor>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "value", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<value>", inMarker: "<descriptor>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "informativeText", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<informativeText>", inMarker: "<descriptor>")))
        }
        
        for child in element.children {
            if child.name == "properties" {
                let propertiesMarker = SILGattPropertiesMarker(element: child)
                let result = propertiesMarker.parseForDescriptor()
                switch result {
                case let .success(propertiesEntity):
                    descriptorEntity.properties = propertiesEntity.properties
                    for additionalChild in propertiesEntity.additionalXmlChildren {
                        descriptorEntity.additionalXmlChildren.append(additionalChild)
                    }
                    for additionalAttribute in propertiesEntity.additionalXmlAttributes {
                        descriptorEntity.additionalXmlAttributes.append(additionalAttribute)
                    }
                case let .failure(error):
                    return .failure(error)
                }

            } else if child.name == "value" {
                let valueMarker = SILGattValueMarker(element: child)
                let result = valueMarker.parse()
                switch result {
                case let .success(valueEntity):
                    descriptorEntity.initialValue = valueEntity.value
                    descriptorEntity.initialValueType = valueEntity.valueType
                    descriptorEntity.fixedVariableLength = valueEntity.fixedVariableLength
                    for valueAttribute in valueEntity.additionalXmlAttributes {
                        descriptorEntity.additionalXmlAttributes.append(valueAttribute)
                    }
                    
                case let .failure(error):
                    return .failure(error)
                }
                
            } else if additionalAllowedChildrenNames.contains(child.name) {
                descriptorEntity.additionalXmlChildren.append(child)
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedChildName(inMarker: "<descriptor>", childName: child.name)))
            }
        }
        
        if let namedDescriptor = gattAssignedRepository.getDescriptor(byUuid: descriptorEntity.cbuuidString) {
            descriptorEntity.name = namedDescriptor.name
        }
        
        disableModyfingIfNeeded(descriptorEntity: descriptorEntity)
        
        return .success(descriptorEntity)
    }
    
    private func disableModyfingIfNeeded(descriptorEntity: SILGattConfigurationDescriptorEntity) {
        if descriptorEntity.cbuuidString.count == 4 {
            if descriptorEntity.cbuuidString == characteristicUserDescriptionUUID || descriptorEntity.cbuuidString == characteristicPresentationFormatUUID {
                descriptorEntity.canBeModified = true
            } else {
                descriptorEntity.canBeModified = false
            }
        } else {
            descriptorEntity.canBeModified = true
        }
        
    }
}
