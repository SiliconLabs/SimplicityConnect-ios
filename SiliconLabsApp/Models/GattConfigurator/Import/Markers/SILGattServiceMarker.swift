//
//  SILGattServiceMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 31.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattServiceMarker: SILGattXmlMarkerType {    
    var element: AEXMLElement
    var gattAssignedRepository: SILGattAssignedNumbersRepository
    
    typealias GattConfigurationEntity = SILGattConfigurationServiceEntity
    
    private let additionalAllowedChildrenNames = ["informativeText", "description", "uri", "include", "capabilities"]
    private let allowedAttributes = ["uuid", "id", "sourceId", "type", "requirement", "advertise", "name", "instance_id"]
    
    private var capabilitiesDeclareEntity: SILGattCapabilitiesDeclareEntity!
    private var servicesIDs = [String]()
    private var ownServiceID = ""
    private let helper = SILGattImportHelper.shared
    
    init(element: AEXMLElement, gattAssignedRepository: SILGattAssignedNumbersRepository) {
        self.element = element
        self.gattAssignedRepository = gattAssignedRepository
    }
    
    // Due to requirements - capabilities aren't hiding elements, it is only checked if service contains only inherited capabilities
    mutating func parse(withCapabilites capabilites: SILGattCapabilitiesDeclareEntity, andServicesIDs: [String]) -> Result<SILGattConfigurationServiceEntity, SILGattXmlParserError> {
        self.servicesIDs = andServicesIDs
        
        guard element.name == "service" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<service>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "capabilities", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<capabilities>", inMarker: "<service>")))
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
    
    mutating func parse() -> Result<SILGattConfigurationServiceEntity, SILGattXmlParserError> {
        var serviceEntity = SILGattConfigurationServiceEntity()
        serviceEntity.name = "Unknown Service"
        serviceEntity.cbuuidString = ""
        serviceEntity.isPrimary = true
        serviceEntity.characteristics = List<SILGattConfigurationCharacteristicEntity>()
        serviceEntity.additionalXmlAttributes = [SILGattXMLAttribute]()
        serviceEntity.additionalXmlChildren = [AEXMLElement]()
  
        guard element.name == "service" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<service>")))
        }
        
        guard helper.containsAttribute(in: element, withName: "uuid") else {
            return .failure(.parsingError(description: helper.errorMissingAttribute(name: "uuid", inMarker: "<service>")))
        }
        
        for (_, attribute) in element.attributes.enumerated() {
            let attributeName = attribute.key as String
            let attributeValue = attribute.value as String

            guard allowedAttributes.contains(attributeName) else {
                return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<service>")))
            }
            
            if attributeName == "name" {
                serviceEntity.name = attributeValue
            } else if attributeName == "uuid" {
                guard helper.validateUUID(stringUUID: attributeValue) else {
                    return .failure(.parsingError(description: helper.errorInvalidUUID(stringUUID: attributeValue, inMarker: "<service>")))
                }
        
                serviceEntity.cbuuidString = attributeValue.hasPrefix("0x") ? String(attributeValue.dropFirst(2)) : attributeValue
            } else if attributeName == "type" {
                guard helper.isAttributeValueForServiceType(attributeValue) else {
                    return .failure(.parsingError(description: "Not allowed attribute value \(attributeValue)"))
                }
                
                if attributeValue == "secondary" {
                    serviceEntity.isPrimary = false
                }
            } else if attributeName == "advertise" {
                guard helper.isAttributeValueBoolean(attributeValue) else {
                    return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<service>")))
                }
                
                serviceEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            } else if attributeName == "requirement" {
                if helper.isAttributeValueForServiceRequirement(attributeValue) {
                    serviceEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
                } else {
                    return .failure(.parsingError(description: "Not allowed attribute value \(attributeValue)"))
                }
            } else if attributeName == "id" {
                self.ownServiceID = attributeValue
                serviceEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            } else {
                serviceEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            }
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "informativeText", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<informativeText>", inMarker: "<service>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "description", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<description>", inMarker: "<service>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "uri", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<uri>", inMarker: "<service>")))
        }
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "capabilities", count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<capabilities>", inMarker: "<service>")))
        }
        
        for child in element.children {
            if child.name == "characteristic" {
                var characteristicMarker = SILGattCharacteristicMarker(element: child, gattAssignedRepository: gattAssignedRepository)
                var result: Result<SILGattConfigurationCharacteristicEntity, SILGattXmlParserError>
                
                if let capabilitiesDeclareEntity = capabilitiesDeclareEntity {
                    result = characteristicMarker.parse(withCapabilites: capabilitiesDeclareEntity)
                } else {
                    result = characteristicMarker.parse()
                }
             
                switch result {
                case let .success(characteristicEntity):
                    serviceEntity.characteristics.append(characteristicEntity)
                case let .failure(error):
                    return .failure(error)
                }
            } else if child.name == "include" {
                // Simplicity Studio doesn't allow to include something what doesn't exist in the configuration
                guard helper.areIncludedServicesCorrect(element: child, serviceID: self.ownServiceID, allServicesIDs: self.servicesIDs) else {
                    return .failure(.parsingError(description: "Incorrect included services"))
                }
                
                serviceEntity.additionalXmlChildren.append(child)
            } else if additionalAllowedChildrenNames.contains(child.name) {
                serviceEntity.additionalXmlChildren.append(child)
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedChildName(inMarker: "<service>", childName: child.name)))
            }
        }
        
        if let namedService = gattAssignedRepository.getService(byUuid: serviceEntity.cbuuidString) {
            serviceEntity.name = namedService.name
        }
        
        return .success(serviceEntity)
    }
    
    private func matchCapabilitesWithInherited(_ capabilitesEntity: SILGattCapabilitiesEntity, inherited: SILGattCapabilitiesDeclareEntity) ->  Result<SILGattCapabilitiesDeclareEntity, SILGattXmlParserError> {
        var supportedCapabilities = [SILGattCapabilityEntity]()
        
        for name in capabilitesEntity.capabilityNames {
            if let capability = inherited.capabilities.first(where: { capability in capability.name == name }) {
                supportedCapabilities.append(capability)
            } else {
                return .failure(.parsingError(description: "Not inherited capability \(name) in the <service> marker"))
            }
        }
        
        return .success(SILGattCapabilitiesDeclareEntity(capabilities: supportedCapabilities))
    }
}
