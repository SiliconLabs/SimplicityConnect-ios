//
//  SILGattPropertiesMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 24.6.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattPropertiesEntity {
    var properties: [SILGattConfigurationProperty] = [SILGattConfigurationProperty]()
    var additionalXmlAttributes: [SILGattXMLAttribute] = [SILGattXMLAttribute]()
    var additionalXmlChildren: [AEXMLElement] = [AEXMLElement]()
}

struct SILGattPropertiesMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    
    typealias GattConfigurationEntity = SILGattPropertiesEntity

    let allowedAttributesNames = ["read", "bonded_read", "write", "write_no_response",
                                  "bonded_write", "notify", "indicate", "bonded_notify",
                                  "const", "authenticated_read", "encrypted_read",
                                  "authenticated_write", "encrypted_write", "reliable_write",
                                  "discoverable", "encrypted_notify", "authenticated_notify",
                                  "read_requirement", "const_requirement", "write_requirement",
                                  "write_no_response_requirement", "notify_requirement", "indicate_requirement",
                                  "authenticated_read_requirement", "bonded_read_requirement", "encrypted_read_requirement",
                                  "authenticated_write_requirement", "bonded_write_requirement", "encrypted_write_requirement",
                                  "reliable_write_requirement","discoverable_requirement", "encrypted_notify_requirement",
                                  "authenticated_notify_requirement", "bonded_notify_requirement"]
    
    private let helper = SILGattImportHelper.shared
    
    func parseForDescriptor() -> Result<SILGattPropertiesEntity, SILGattXmlParserError> {
        if !element.children.isEmpty {
            guard element.children.contains(where: { child in ["read", "write"].contains(child.name) }) else {
                return .failure(.parsingError(description: "Not allowed properties for descriptors"))
            }
        }

        if !element.attributes.isEmpty {
            guard element.attributes.enumerated().contains(where: { (_ , attribute) -> Bool in
                attribute.key.contains("read") || attribute.key.contains("write") && !attribute.key.contains("write_no_response") && !attribute.key.contains("reliable_write")
            }) else {
                return .failure(.parsingError(description: "Properties contains not allowed attributes for descriptors"))
            }
        }
        
        return self.parse()
    }
    
    // assume that elements are more important than attributes, attributes are parsed only when no elements is here
    func parse() -> Result<SILGattPropertiesEntity, SILGattXmlParserError> {
        var propertiesEntity = SILGattPropertiesEntity()
        
        guard element.name == "properties" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<properties>")))
        }
        
        if element.children.count == 0 {
            guard element.attributes.count > 0 else {
                return .failure(.parsingError(description: helper.errorMustContainsAnyAttributes(markerName: "<properties>")))
            }
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "read", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<read>", inMarker: "<properties>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "write", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<write>", inMarker: "<properties>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "write_no_response", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<write_no_response>", inMarker: "<properties>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "notify", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<notify>", inMarker: "<properties>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "indicate", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<indicate>", inMarker: "<properties>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "reliable_write", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<reliable_write>", inMarker: "<properties>")))
        }

        for child in element.children {
            switch child.name {
            case "read":
                let propertyMarker = SILGattPropertyMarker(element: child)
                let result = propertyMarker.parse()
                switch result {
                case let .success(propertyEntity):
                    propertiesEntity.properties.append(SILGattConfigurationProperty(type: .read, permission: propertyEntity.isBonded ? .bonded : .none))
                    for attribute in propertyEntity.additionalXmlAttributes {
                        propertiesEntity.additionalXmlAttributes.append(attribute)
                    }
                        
                case let .failure(error):
                    return .failure(error)
                }
            
            case "write":
                let propertyMarker = SILGattPropertyMarker(element: child)
                let result = propertyMarker.parse()
                switch result {
                case let .success(propertyEntity):
                    propertiesEntity.properties.append(SILGattConfigurationProperty(type: .write, permission: propertyEntity.isBonded ? .bonded : .none))
                    for attribute in propertyEntity.additionalXmlAttributes {
                        propertiesEntity.additionalXmlAttributes.append(attribute)
                    }
                    
                case let .failure(error):
                    return .failure(error)
                }
             
            case "write_no_response":
                let propertyMarker = SILGattPropertyMarker(element: child)
                let result = propertyMarker.parse()
                switch result {
                case let .success(propertyEntity):
                    propertiesEntity.properties.append(SILGattConfigurationProperty(type: .writeWithoutResponse, permission: propertyEntity.isBonded ? .bonded : .none))
                    for attribute in propertyEntity.additionalXmlAttributes {
                        propertiesEntity.additionalXmlAttributes.append(attribute)
                    }
                    
                case let .failure(error):
                    return .failure(error)
                }
                
            case "notify":
                let propertyMarker = SILGattPropertyMarker(element: child)
                let result = propertyMarker.parse()
                switch result {
                case let .success(propertyEntity):
                    propertiesEntity.properties.append(SILGattConfigurationProperty(type: .notify, permission: propertyEntity.isBonded ? .bonded : .none))
                    for attribute in propertyEntity.additionalXmlAttributes {
                        propertiesEntity.additionalXmlAttributes.append(attribute)
                    }
                    
                case let .failure(error):
                    return .failure(error)
                }
                
            case "indicate":
                let propertyMarker = SILGattPropertyMarker(element: child)
                let result = propertyMarker.parse()
                switch result {
                case let .success(propertyEntity):
                    propertiesEntity.properties.append(SILGattConfigurationProperty(type: .indicate, permission: propertyEntity.isBonded ? .bonded : .none))
                    for attribute in propertyEntity.additionalXmlAttributes {
                        propertiesEntity.additionalXmlAttributes.append(attribute)
                    }
                    
                case let .failure(error):
                    return .failure(error)
                }
                
            default:
                if child.name != "reliable_write" {
                    return .failure(.parsingError(description: helper.errorNotAllowedChildName(inMarker: "<properties>", childName: child.name)))
                }
                
                propertiesEntity.additionalXmlChildren.append(child)
            }
        }
        
        if element.children.isEmpty {
            var read: Bool?
            var bonded_read: Bool?
            var write: Bool?
            var write_no_response: Bool?
            var bonded_write: Bool?
            var notify: Bool?
            var indicate: Bool?
            var bonded_notify: Bool?
            
            for (_, attribute) in element.attributes.enumerated() {
                let attributeName = attribute.key as String
                let attributeValue = attribute.value as String
                
                switch attributeName {
                case "read":
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }
                    
                    read = attributeValue == "true" ? true : false
                    
                case "bonded_read":
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }
                    
                    bonded_read = attributeValue == "true" ? true : false
                    
                case "write":
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }
              
                    write = attributeValue == "true" ? true : false
                    
                case "write_no_response":
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }
                    
                    write_no_response = attributeValue == "true" ? true : false
                  
                case "bonded_write":
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }
       
                    bonded_write = attributeValue == "true" ? true : false
                    
                case "notify":
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }
                    
                    notify = attributeValue == "true" ? true : false
       
                case "indicate":
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }
              
                    indicate = attributeValue == "true" ? true : false
                 
                case "bonded_notify":
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }

                    bonded_notify = attributeValue == "true" ? true : false
                
                default:
                    guard allowedAttributesNames.contains(attributeName) else {
                        return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<properties>")))
                    }
                    
                    if attributeName.contains("requirement") {
                        guard helper.isRequirementAttributeValid(attributeValue: attributeValue) else {
                            return .failure(.parsingError(description: "Attribute value not allowed \(attributeValue)"))
                        }
                    } else {
                        guard helper.isAttributeValueBoolean(attributeValue) else {
                            return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                        }
                    }
                    
                    propertiesEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: "properties_\(attributeName)", value: attributeValue))
                }
            }
            
            if let readProperty = propertyFrom(read: read, bonded_read: bonded_read) {
                propertiesEntity.properties.append(readProperty)
            }
            
            if let writeProperty = propertyFrom(write: write, bonded_write: bonded_write) {
                propertiesEntity.properties.append(writeProperty)
            }
            
            if let writeNoResponseProperty = propertyFrom(write_no_response: write_no_response, bonded_write: bonded_write) {
                propertiesEntity.properties.append(writeNoResponseProperty)
            }
                        
            if let notifyProperty = propertyFrom(notify: notify, bonded_notify: bonded_notify) {
                propertiesEntity.properties.append(notifyProperty)
            }
            
            if let indicateProperty =  propertyFrom(indicate: indicate, bonded_notify: bonded_notify) {
                propertiesEntity.properties.append(indicateProperty)
            }
        } else {
            for (_, attribute) in element.attributes.enumerated() {
                let attributeName = attribute.key as String
                let attributeValue = attribute.value as String
                
                guard allowedAttributesNames.contains(attributeName) else {
                    return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<properties>")))
                }
            
                if attributeName.contains("requirement") {
                    guard helper.isRequirementAttributeValid(attributeValue: attributeValue) else {
                        return .failure(.parsingError(description: "Attribute value not allowed \(attributeValue)"))
                    }
                } else {
                    guard helper.isAttributeValueBoolean(attributeValue) else {
                        return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<properties>")))
                    }
                }
            
                propertiesEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: "properties_\(attributeName)", value: attributeValue))
            }
        }
        
        guard propertiesEntity.properties.count > 0 else {
            return .failure(.parsingError(description: "Must contain at least one property"))
        }
        
        return .success(propertiesEntity)
    }
    
    private func propertyFrom(read: Bool?, bonded_read: Bool?) -> SILGattConfigurationProperty? {
        if let read = read, let bonded_read = bonded_read {
            if read {
                if bonded_read {
                    return SILGattConfigurationProperty(type: .read, permission: .bonded)
                } else {
                    return SILGattConfigurationProperty(type: .read, permission: .none)
                }
            }
        } else if let bonded_read = bonded_read, read == nil {
            if bonded_read {
                return SILGattConfigurationProperty(type: .read, permission: .bonded)
            }
        } else if let read = read, bonded_read == nil {
            if read {
                return SILGattConfigurationProperty(type: .read, permission: .none)
            }
        }
        
        return nil
    }
    
    private func propertyFrom(write: Bool?, bonded_write: Bool?) -> SILGattConfigurationProperty? {
        if let write = write, let bonded_write = bonded_write {
            if write {
                if bonded_write {
                    return SILGattConfigurationProperty(type: .write, permission: .bonded)
                } else {
                    return SILGattConfigurationProperty(type: .write, permission: .none)
                }
            }
        } else if let bonded_write = bonded_write, write == nil {
            if bonded_write {
                return SILGattConfigurationProperty(type: .write, permission: .bonded)
            }
        } else if let write = write, bonded_write == nil {
            if write {
                return SILGattConfigurationProperty(type: .write, permission: .none)
            }
        }
        
        return nil
    }
    
    private func propertyFrom(write_no_response: Bool?, bonded_write: Bool?) -> SILGattConfigurationProperty? {
        if let write_no_response = write_no_response, let bonded_write = bonded_write {
            if write_no_response {
                if bonded_write {
                    return SILGattConfigurationProperty(type: .writeWithoutResponse, permission: .bonded)
                } else {
                    return SILGattConfigurationProperty(type: .writeWithoutResponse, permission: .none)
                }
            }
        } else if let bonded_write = bonded_write, write_no_response == nil {
            if bonded_write {
                // not specified what doing in this case
                return nil
            }
        } else if let write_no_response = write_no_response, bonded_write == nil {
            if write_no_response {
                return SILGattConfigurationProperty(type: .writeWithoutResponse, permission: .none)
            }
        }
        
        return nil
    }
    
    private func propertyFrom(notify: Bool?, bonded_notify: Bool?) -> SILGattConfigurationProperty? {
        if let notify = notify, let bonded_notify = bonded_notify {
            if notify {
                if bonded_notify {
                    return SILGattConfigurationProperty(type: .notify, permission: .bonded)
                } else {
                    return SILGattConfigurationProperty(type: .notify, permission: .none)
                }
            }
        } else if let bonded_notify = bonded_notify, notify == nil {
            if bonded_notify {
                return SILGattConfigurationProperty(type: .notify, permission: .bonded)
            }
        } else if let notify = notify, bonded_notify == nil {
            if notify {
                return SILGattConfigurationProperty(type: .notify, permission: .none)
            }
        }
        
        return nil
    }
    
    private func propertyFrom(indicate: Bool?, bonded_notify: Bool?) -> SILGattConfigurationProperty? {
        if let indicate = indicate, let bonded_notify = bonded_notify {
            if indicate {
                if bonded_notify {
                    return SILGattConfigurationProperty(type: .indicate, permission: .bonded)
                } else {
                    return SILGattConfigurationProperty(type: .indicate, permission: .none)
                }
            }
        } else if let bonded_notify = bonded_notify, indicate == nil {
            if bonded_notify {
                // not specified what doing in this case
                return nil
            }
        } else if let indicate = indicate, bonded_notify == nil {
            if indicate {
                return SILGattConfigurationProperty(type: .indicate, permission: .none)
            }
        }
        
        return nil
    }
}
