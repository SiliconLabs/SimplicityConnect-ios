//
//  SILGattCapabilitiesDeclareMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 24.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattCapabilityEntity {
    var name: String
    var enabled: Bool
}

struct SILGattCapabilitiesDeclareEntity {
    var capabilities: [SILGattCapabilityEntity]
}

struct SILGattCapabilitiesDeclareMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    private let helper = SILGattImportHelper.shared
    
    typealias GattConfigurationEntity = SILGattCapabilitiesDeclareEntity
    func parse() -> Result<SILGattCapabilitiesDeclareEntity, SILGattXmlParserError> {
        var capabilities = [SILGattCapabilityEntity]()
        
        guard element.name == "capabilities_declare" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<capabilities_declare>")))
        }
        
        guard element.attributes.isEmpty else {
            return .failure(.parsingError(description: helper.errorCantHaveAnyAttributes(element: element, name: "<capabilities_declare>")))
        }
        
        guard !element.children.isEmpty else {
            return .failure(.parsingError(description: helper.errorMustContainElementInside(name: "<capability>", inMarker: "<capabilities_declare>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "capability", count: 16) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<capability>", inMarker: "<capabilities_declare>")))
        }
        
        for child in element.children {
            let name = child.value ?? ""
            var enabled = true
            
            guard matchEntireName(name) else {
                return .failure(.parsingError(description: helper.errorNotAllowedCharacters(name: "<capability", value: name, inMarker: "<capabilities_declare>")))
            }
            
            if child.name == "capability" {
                for (_, attribute) in child.attributes.enumerated() {
                    let attributeName = attribute.key as String
                    let attributeValue = attribute.value as String
                    if attributeName == "enable" {
                        enabled = attributeValue == "true" ? true : false
                    } else {
                        return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<capabilities_declare>")))
                    }
                }
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedChildName(inMarker: "<capabilities_declare>", childName: child.name)))
            }
            
            capabilities.append(SILGattCapabilityEntity(name: name, enabled: enabled))
        }
        
        let capabilitiesDeclare = SILGattCapabilitiesDeclareEntity(capabilities: capabilities)
        
        return .success(capabilitiesDeclare)
    }
    
    private func matchEntireName(_ name: String) -> Bool {
        let range = NSRange(location: 0, length: name.utf16.count)
        let regex = try! NSRegularExpression(pattern: "([a-zA-Z_])([0-9a-zA-Z_]*)")
        if let result = regex.matches(in: name, range: range).first.map({ String(name[Range($0.range, in: name)!]) }) {
            return result == name
        }
        
        return false
    }
}
