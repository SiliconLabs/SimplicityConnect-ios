//
//  SILGattConfigurationEntity+SILGattXMLExportable.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 22/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

extension SILGattConfigurationEntity: SILGattXmlExportable {
    
    func export() -> AEXMLElement {
        
        let outAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.outAttribute
        let headerAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.headerAttribute
        let nameAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.nameAttribute
        let prefixAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.prefixAttribute
        let genericAttributeServiceAttribute = SILGattConfiguratorXmlDatabase.GattConfiguration.genericAttributeServiceAttribute
        
        let gattXML = AEXMLElement(name: SILGattConfiguratorXmlDatabase.GattConfiguration.name)

        [outAttribute, headerAttribute, prefixAttribute, genericAttributeServiceAttribute]
            .forEach { gattXML.attributes[$0.name] = self.getAttributeValue(attribute: $0) }
        
        gattXML.attributes["name"] = self.name == "" ? nameAttribute.defaultValue : self.name

        for additionalAttribute in self.additionalXmlAttributes {
            if ![outAttribute.name, headerAttribute.name, nameAttribute.name, prefixAttribute.name, genericAttributeServiceAttribute.name].contains(additionalAttribute.name) {
                gattXML.attributes[additionalAttribute.name] = additionalAttribute.value
            }
        }
        
        for additionalNode in self.additionalXmlChildren {
            gattXML.addChild(additionalNode)
        }
        
        for service in self.services {
            gattXML.addChild(service.export())
        }
        
        if let projectEntity = self.projectEntity {
            return createProjectXML(projectEntity: projectEntity, gattXML: gattXML)
        }
        
        return gattXML
    }
    
    private func createProjectXML(projectEntity: SILGattProjectEntity, gattXML: AEXMLElement) -> AEXMLElement {
        let projectXML = AEXMLElement(name: "project")
        for additionalAttributes in projectEntity.additionalXmlAttributes {
            projectXML.attributes[additionalAttributes.name] = additionalAttributes.value
        }
        
        projectXML.addChild(gattXML)
        return projectXML
    }
}
