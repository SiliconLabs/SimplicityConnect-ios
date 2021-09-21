//
//  SILGattConfigurationServiceEntity+SILGattXMLExportable.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 22/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

extension SILGattConfigurationServiceEntity: SILGattXmlExportable {
        
    func export() -> AEXMLElement {
        
        let nameAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.nameAttribute
        let uuidAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationGATTEntity.uuidAttribute
        let typeAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationService.typeAttribute
        
        let primaryTypeString = SILGattConfiguratorXmlDatabase.GattConfigurationService.primaryType
        let secondaryTypeString = SILGattConfiguratorXmlDatabase.GattConfigurationService.secondaryType
        
        let serviceXML = AEXMLElement(name: SILGattConfiguratorXmlDatabase.GattConfigurationService.name, value: nil, attributes: [
            uuidAttribute.name: self.cbuuidString,
            typeAttribute.name: self.isPrimary ? primaryTypeString : secondaryTypeString
        ])
        
        if let name = self.name {
            serviceXML.attributes[nameAttribute.name] = name
        }
        
        for additionalAttribute in self.additionalXmlAttributes {
            serviceXML.attributes[additionalAttribute.name] = additionalAttribute.value
        }
    
        for additionalNode in self.additionalXmlChildren {
            serviceXML.addChild(additionalNode)
        }
        
        for characteristic in self.characteristics {
            serviceXML.addChild(characteristic.export())
        }
        
        return serviceXML
    }
}

