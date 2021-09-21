//
//  SILGattProjectMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 2.8.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattProjectMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    
    typealias GattConfigurationEntity = SILGattProjectEntity

    let helper = SILGattImportHelper.shared
    
    func parse() -> Result<SILGattProjectEntity, SILGattXmlParserError> {
        var projectEntity = SILGattProjectEntity()
        
        guard element.name == "project" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<project>")))
        }
        
        guard element.children.count == 1 else {
            return .failure(.parsingError(description: helper.errorMustContainElementInside(name: "<gatt>", inMarker: "<project>", onlyOne: true)))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "gatt", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<gatt>", inMarker: "<project>")))
        }
        
        for (_, attribute) in element.attributes.enumerated() {
            let attributeName = attribute.key as String
            let attributeValue = attribute.value as String
            
            if attributeName == "device" {
                projectEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<project>")))
            }
        }
        
        return .success(projectEntity)
    }
}
