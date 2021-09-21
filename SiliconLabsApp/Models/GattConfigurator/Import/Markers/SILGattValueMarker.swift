//
//  SILGattValueMarker.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 21.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattValueEntity {
    var value: String = ""
    var valueType: SILGattConfigurationValueType = .none
    var fixedVariableLength: Bool = false
    var additionalXmlAttributes: [SILGattXMLAttribute] = [SILGattXMLAttribute]()
}

struct SILGattValueMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    
    typealias GattConfigurationEntity = SILGattValueEntity
    
    let allowedAttributes = ["type", "length", "variable_length"]
    private let helper = SILGattImportHelper.shared
    
    func parse() -> Result<SILGattValueEntity, SILGattXmlParserError> {
        var valueEntity = SILGattValueEntity()
        
        guard element.name == "value" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<value>")))
        }
        
        guard element.children.isEmpty else {
            return .failure(.parsingError(description: helper.errorCantHaveAnyChildren(element: element, name: "<value>")))
        }
        
        valueEntity.value = element.string.hasPrefix("0x") ? String(element.string.dropFirst(2)) : element.string
        
        for (_, attribute) in element.attributes.enumerated() {
            let attributeName = attribute.key as String
            let attributeValue = attribute.value as String
  
            guard allowedAttributes.contains(attributeName) else {
                return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<value>")))
            }
            
            if attributeName == "type" {
                if attributeValue == "utf-8" {
                    valueEntity.valueType = .text
                } else if attributeValue == "hex" {
                    valueEntity.valueType = .hex
                } else if attributeValue == "user" {
                    valueEntity.valueType = .none
                } else {
                    return .failure(.parsingError(description: "Not allowed attribute value \(attributeValue) for type in <value> marker"))
                }
            } else if attributeName == "variable_length" {
                guard helper.isAttributeValueBoolean(attributeValue) else {
                    return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<value>")))
                }
                
                if attributeValue == "true" {
                    valueEntity.fixedVariableLength = false
                } else {
                    valueEntity.fixedVariableLength = true
                }
            } else {
                valueEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: "value_\(attributeName)", value: attributeValue))
            }
        }
        
        if valueEntity.valueType == .hex {
            guard helper.isValidHexValue(valueEntity.value) else {
                return .failure(.parsingError(description: "Invalid hex value \(valueEntity.value)"))
            }
        }
        
        return .success(valueEntity)
    }
}
