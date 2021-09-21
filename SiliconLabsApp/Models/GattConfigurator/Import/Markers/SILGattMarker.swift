//
//  SILGattMarker.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 31.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML
import RealmSwift

struct SILGattMarker: SILGattXmlMarkerType {
    var element: AEXMLElement
    var gattAssignedRepository: SILGattAssignedNumbersRepository
    
    typealias GattConfigurationEntity = SILGattConfigurationEntity
    
    let allowedAttributes = ["in", "out", "header", "db_name", "prefix", "generic_attribute_service", "gatt_caching", "name", "id"]
    private let helper = SILGattImportHelper.shared
    private var projectEntity: SILGattProjectEntity?
    
    init(element: AEXMLElement, gattAssignedRepository: SILGattAssignedNumbersRepository) {
        self.element = element
        self.gattAssignedRepository = gattAssignedRepository
    }
    
    mutating func parse(withProjectEntity: SILGattProjectEntity) -> Result<SILGattConfigurationEntity, SILGattXmlParserError> {
        self.projectEntity = withProjectEntity
        return self.parse()
    }
    
    func parse() -> Result<SILGattConfigurationEntity, SILGattXmlParserError> {
        var gattEntity = SILGattConfigurationEntity()
        gattEntity.services = List<SILGattConfigurationServiceEntity>()
        gattEntity.name = "Custom BLE GATT"
        gattEntity.additionalXmlAttributes = [SILGattXMLAttribute]()
        gattEntity.additionalXmlChildren = [AEXMLElement]()

        var capabilitiesDeclare: SILGattCapabilitiesDeclareEntity?
        
        guard element.name == "gatt" else {
            return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: element, expectedName: "<gatt>")))
        }
        
        for (_, attribute) in element.attributes.enumerated() {
            let attributeName = attribute.key as String
            let attributeValue = attribute.value as String
 
            guard allowedAttributes.contains(attributeName) else {
                return .failure(.parsingError(description: helper.errorNotAllowedAttributeName(name: attributeName, inMarker: "<gatt>")))
            }
            
            if attributeName == "name" {
                gattEntity.name = attributeValue
            } else if attributeName == "generic_attribute_service" || attributeName == "gatt_caching" {
                guard helper.isAttributeValueBoolean(attributeValue) else {
                    return .failure(.parsingError(description: helper.errorAttributeValueIsNotBoolean(attributeName: attributeName, attributeValue: attributeValue, inMarker: "<gatt>")))
                }
                
                gattEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            } else {
                gattEntity.additionalXmlAttributes.append(SILGattXMLAttribute(name: attributeName, value: attributeValue))
            }
        }
        
        appendAttributeIfNeeded(name: "out", value: "gatt_db.c", additionalXmlAttibutes: &gattEntity.additionalXmlAttributes)
        appendAttributeIfNeeded(name: "header", value: "gatt_db.h", additionalXmlAttibutes: &gattEntity.additionalXmlAttributes)
        appendAttributeIfNeeded(name: "prefix", value: "gattdb_", additionalXmlAttibutes: &gattEntity.additionalXmlAttributes)
        appendAttributeIfNeeded(name: "generic_attribute_service", value: "true", additionalXmlAttibutes: &gattEntity.additionalXmlAttributes)
        
        guard helper.hasLessOrEqualThanChild(element: element, childName: "capabilities_declare" , count: 1) else {
            return .failure(.parsingError(description: helper.errorTooManyMarkers(name: "<capabilities_declare>", inMarker: "<gatt>")))
        }
        
        if let capabilitiesDeclareChild = helper.firstChild(in: element, withName: "capabilities_declare" ) {
            let capabilitiesDeclareMarker = SILGattCapabilitiesDeclareMarker(element: capabilitiesDeclareChild)
            let result = capabilitiesDeclareMarker.parse()
            switch result {
            case let .success(capabilitiesDeclareEntity):
                capabilitiesDeclare = capabilitiesDeclareEntity
            case let .failure(error):
                return .failure(error)
            }
        }
        
        let servicesIDs = element.children
            .filter({ element in element.name == "service" })
            .filter({ element in element.attributes.enumerated().first(where: { (_, attribute) in attribute.key == "id" }) != nil })
            .compactMap({ element in element.attributes["id"] })
        
        for child in element.children {
            if child.name == "service" {
                var serviceMarker = SILGattServiceMarker(element: child, gattAssignedRepository: gattAssignedRepository)
                var result: Result<SILGattConfigurationServiceEntity, SILGattXmlParserError>
                
                if let capabilitiesDeclare = capabilitiesDeclare {
                    result = serviceMarker.parse(withCapabilites: capabilitiesDeclare, andServicesIDs: servicesIDs)
                } else {
                    result = serviceMarker.parse()
                }
                
                switch result {
                case let .success(serviceEntity):
                    gattEntity.services.append(serviceEntity)
                case let .failure(error):
                    return .failure(error)
                }
            } else if child.name == "capabilities_declare" {
                gattEntity.additionalXmlChildren.append(child)
            } else {
                return .failure(.parsingError(description: helper.errorNotAllowedChildName(inMarker: "<gatt>", childName: child.name)))
            }
        }
        
        if let projectEntity = projectEntity {
            gattEntity.projectEntity = projectEntity
        } else {
            gattEntity.projectEntity = nil
        }
        
        return .success(gattEntity)
    }
    
    private func appendAttributeIfNeeded(name: String, value: String, additionalXmlAttibutes: inout [SILGattXMLAttribute]) {
        if !additionalXmlAttibutes.contains(where: { attribute in attribute.name == name }) {
            additionalXmlAttibutes.append(SILGattXMLAttribute(name: name, value: value))
        }
    }
}
