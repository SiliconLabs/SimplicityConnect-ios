//
//  SILGattConfigurationProperty+SILGattXMLExportable.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 18/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

extension SILGattConfigurationProperty: SILGattXmlExportable {
    
    func export() -> AEXMLElement {
        let authenticatedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.authenticatedAttribute
        let encryptedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.encryptedAttribute
        let bondedAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationProperty.bondedAttribute
        
        let authenticatedAttributeValue = self.getAttributeValue(attribute: authenticatedAttribute)!
        let bondedAttributeValue = self.permission == .bonded ? SILGattConfiguratorXmlDatabase.trueString : SILGattConfiguratorXmlDatabase.falseString
        let encryptedAttributeValue = self.getAttributeValue(attribute: encryptedAttribute)!
        
        return AEXMLElement(name: self.type.xmlTag, value: nil, attributes: [
            authenticatedAttribute.name: authenticatedAttributeValue,
            bondedAttribute.name: bondedAttributeValue,
            encryptedAttribute.name: encryptedAttributeValue
        ])
    }
}
