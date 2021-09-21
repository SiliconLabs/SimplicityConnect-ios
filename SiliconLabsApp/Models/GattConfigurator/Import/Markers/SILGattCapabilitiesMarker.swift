//
//  SILGattCapabilitiesMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 24.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattCapabilitiesEntity {
    var capabilityNames = [String]()
}

struct SILGattCapabilitiesMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    private let helper = SILGattImportHelper.shared
    
    typealias GattConfigurationEntity = SILGattCapabilitiesEntity
    func parse() -> Result<SILGattCapabilitiesEntity, SILGattXmlParserError> {
        var capabilities = SILGattCapabilitiesEntity()
        
        guard element.name == "capabilities" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<capabilities>")))
        }
        
        guard element.attributes.isEmpty else {
            return .failure(.parsingError(description: helper.errorCantHaveAnyAttributes(element: element, name: "<capabilities>")))
        }
        
        guard !element.children.isEmpty else {
            return .failure(.parsingError(description: helper.errorMustContainElementInside(name: "<capability>", inMarker: "<capabilities>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "capability", count: 16) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<capability>", inMarker: "<capabilities>")))
        }
        
        for child in element.children {
            if child.name == "capability" {
                guard child.attributes.isEmpty else {
                    return .failure(.parsingError(description: helper.errorCantHaveAnyAttributes(element: child, name: "<capability>")))
                }
                
                let value = child.value ?? ""
                
                guard matchEntireName(value) else {
                    return .failure(.parsingError(description: helper.errorNotAllowedCharacters(name: "<capability", value: value, inMarker: "<capabilities>")))
                }
                
                capabilities.capabilityNames.append(value)
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedChildName(inMarker: "<capabilities", childName: child.name)))
            }
        }
        
        return .success(capabilities)
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
