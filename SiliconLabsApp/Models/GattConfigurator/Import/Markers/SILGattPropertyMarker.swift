//
//  SILGattPropertyMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 31.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattPropertyEntity {
    var isBonded: Bool = false
    var additionalXmlAttributes: [SILGattXMLAttribute] = [SILGattXMLAttribute]()
}

struct SILGattPropertyMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    
    typealias GattConfigurationEntity = SILGattPropertyEntity
        
    let allowedAttributes = ["authenticated", "bonded", "encrypted"]
    let allowedMarkerNames = ["read", "write", "write_no_response", "indicate", "notify"]
    private let helper = SILGattImportHelper.shared
    
    func parse() -> Result<SILGattPropertyEntity, SILGattXmlParserError> {
        var propertyEntity = SILGattPropertyEntity()
        
        guard allowedMarkerNames.contains(element.name) else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "property name")))
        }
        
        guard element.children.isEmpty else {
            return .failure(.parsingError(description: helper.errorCantHaveAnyChildren(element: element, name: "<\(element.name)>")))
        }
        
        for (_, attribute) in element.attributes.enumerated() {
            let attributeName = attribute.key as String
            let attributeValue = attribute.value as String
            
            guard allowedAttributes.contains(attributeName) else {
                return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<\(element.name)>")))
            }
            
            guard helper.isAttributeValueBoolean(attributeValue) else {
                return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<\(element.name)>")))
            }
            
            if attributeName == "bonded" {
                if attributeValue == "true" {
                    propertyEntity.isBonded = true
                }
            } else {
                propertyEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: "\(element.name)_\(attributeName)", value: attributeValue))
            }
        }
        
        return .success(propertyEntity)
    }
}
