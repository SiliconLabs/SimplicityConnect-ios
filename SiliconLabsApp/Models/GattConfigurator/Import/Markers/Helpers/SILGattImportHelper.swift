//
//  SILGattImportHelper.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

class SILGattImportHelper {
    static let shared = SILGattImportHelper()
    
    private init() { }
    
    func isAttributeValueBoolean(_ attributeValue: String) -> Bool {
        return ["true", "false"].contains(attributeValue)
    }
    
    func hasLessOrEqualThanChild(element: AEXMLElement, childName: String, count: Int) -> Bool {
        return element.children.filter( { child in child.name == childName }).count <= count
    }
    
    func firstChild(in element: AEXMLElement, withName: String) -> AEXMLElement? {
        return element.children.first(where: { child in child.name == withName })
    }
    
    func containsAttribute(in element: AEXMLElement, withName: String) -> Bool {
        for (_, attribute) in element.attributes.enumerated() {
            if attribute.key == withName {
                return true
            }
        }
        
        return false
    }
    
    // Service marker
    
    func isAttributeValueForServiceType(_ attributeValue: String) -> Bool {
        return ["primary", "secondary"].contains(attributeValue)
    }
    
    func isAttributeValueForServiceRequirement(_ attributeValue: String) -> Bool {
        return ["mandatory", "optional", "conditional", "c1", "c2", "c2_or_c3", "c3", "c4", "c5", "c6", "c7", "c8", "c9", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "c17", "c18", "c19", "c20"].contains(attributeValue)
    }
    
    func areIncludedServicesCorrect(element: AEXMLElement, serviceID: String, allServicesIDs: [String]) -> Bool {
        guard element.attributes.count == 1 || element.attributes.count == 2 else {
            return false
        }
        
        var allServicesIDs = allServicesIDs
        
        if let ownIDIndex = allServicesIDs.firstIndex(where: { id in id == serviceID }) {
            allServicesIDs.remove(at: ownIDIndex)
        }
        
        for (_, attribute) in element.attributes.enumerated() {
            let attributeName = attribute.key as String
            let attributeValue = attribute.value as String
            
            guard ["id", "sourceId"].contains(attributeName) else {
                return false
            }
            
            if attributeName == "id" {
                guard allServicesIDs.contains(attributeValue) else {
                    return false
                }
            }
        }
    
        return true
    }
    
    // Characteristic marker
    
    func isAggregateCharacteristicMarkerCorrect(element: AEXMLElement) -> Bool {
        guard element.attributes.count <= 1 else {
            return false
        }
        
        if let attribute = element.attributes.first, attribute.key != "id" {
            return false
        }
        
        for child in element.children {
            guard child.name == "attribute" else {
                return false
            }
            
            for (_, attribute) in child.attributes.enumerated() {
                let attributeName = attribute.key as String
                
                guard attributeName == "id" else {
                    return false
                }
            }
        }
        
        return true
    }
    
    // Properities marker
    
    func isRequirementAttributeValid(attributeValue: String) -> Bool {
        return ["mandatory", "optional", "excluded", "c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "c9", "c10"].contains(attributeValue)
    }
    
    // UUID
    
    func validateUUID(stringUUID: String) -> Bool {
        let stringUUID = stringUUID.hasPrefix("0x") ? String(stringUUID.dropFirst(2)) : stringUUID
        
        if stringUUID.count == 4 {
            return validate16BitUUID(stringUUID: stringUUID)
        } else if stringUUID.count == 36 {
            return validate128BitUUID(stringUUID: stringUUID)
        }
        
        return false
    }
    
    private func validate16BitUUID(stringUUID: String) -> Bool {
        for character in stringUUID {
            if !isValidHexCharacter(character) {
                return false
            }
        }
        
        return true
    }
    
    private func validate128BitUUID(stringUUID: String) -> Bool {
        for (i, character) in stringUUID.enumerated() {
            if i == 8 || i == 13 || i == 18 || i == 23 {
                if character != "-" {
                    return false
                }
            } else {
                if !isValidHexCharacter(character) {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func isValidHexCharacter(_ character: Character) -> Bool {
        return ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "A", "B", "C", "D", "E", "F"].contains(character)
    }
    
    func isValidHexValue(_ hexValue: String) -> Bool {
        let hexValue = hexValue.hasPrefix("0x") ? String(hexValue.dropFirst(2)) : hexValue
        
        for hexChar in hexValue {
            if !isValidHexCharacter(hexChar) {
                return false
            }
        }
        
        return true
    }
    
    // error descriptions
    
    func errorNotAllowedElementName(element: AEXMLElement, expectedName: String) -> String {
        return "Not allowed element name \(element.name), expected \(expectedName)"
    }
    
    func errorNotAllowedChildName(inMarker: String, childName: String) -> String {
        return "Not allowed \(childName) name in \(inMarker)"
    }
    
    func errorCantHaveAnyAttributes(element: AEXMLElement, name: String) -> String {
        return "\(name) can't have any attributes, but have \(element.attributes.count) attributes"
    }
    
    func errorCantHaveAnyChildren(element: AEXMLElement, name: String) -> String {
        return "\(name) can't have any children, but have \(element.children.count) children"
    }
    
    func errorMissingAttribute(name: String, inMarker: String) -> String {
        return "Missing \(name) attribute in \(inMarker)"
    }
    
    func errorMissingElement(name: String, inMarker: String) -> String {
        return "Missing element \(name) in \(inMarker)"
    }
    
    func errorNotAllowedAttributeName(name: String, inMarker: String) -> String {
        return "Not allowed attribute \(name) in \(inMarker) marker"
    }
    
    func errorAttributeValueIsNotBoolean(attributeName: String, attributeValue: String, inMarker: String) -> String {
        return "Attribute \(attributeName) value \(attributeValue) is not boolean in marker \(inMarker)"
    }
    
    func errorTooManyMarkers(name: String = "", inMarker: String) -> String {
        return "Too many \(name) markers inside \(inMarker)"
    }
    
    func errorNotAllowedCharacters(name: String, value: String, inMarker: String) -> String {
        return "Not allowed characters \(value) in \(name) in \(inMarker)"
    }
    
    func errorMustContainElementInside(name: String, inMarker: String, onlyOne: Bool = false) -> String {
        let words = onlyOne ? "only" : "at least"
        return "\(inMarker) must contain \(words) one \(name) element inside itself"
    }
    
    func errorMustContainsAnyAttributes(markerName: String) -> String {
        return "Marker \(markerName) has to contain any attributes"
    }
    
    func errorInvalidUUID(stringUUID: String, inMarker: String) -> String {
        return "Invalid \(inMarker) UUID: \(stringUUID)"
    }
}
