//
//  SILGattConfiguratorXmlDatabase.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 21/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct DatabaseXmlAttribute {
    let name: String
    let defaultValue: String?
}

struct SILGattConfiguratorXmlDatabase {
    
    static let trueString = "true"
    static let falseString = "false"
    
    
    struct GattConfigurationProperty {
        
        static let propertiesName = "properties"
        
        static let readName = "read"
        static let writeName = "write"
        static let writeNoResponseName = "write_no_response"
        static let notifyName = "notify"
        static let indicateName = "indicate"
        static let reliableWriteName = "reliable_write"
        
        static let encryptedAttribute = DatabaseXmlAttribute(
            name: "encrypted",
            defaultValue: SILGattConfiguratorXmlDatabase.falseString
        )
        
        static let authenticatedAttribute = DatabaseXmlAttribute(
            name: "authenticated",
            defaultValue: SILGattConfiguratorXmlDatabase.falseString
        )
        
        static let bondedAttribute = DatabaseXmlAttribute(
            name: "bonded",
            defaultValue: SILGattConfiguratorXmlDatabase.falseString
        )
    }
    
    struct GattConfigurationValue {
        
        static let name = "value"
        static let hexTypeString = "hex"
        static let textTypeString = "utf-8"
        static let maxValueLength = 255
        
        static let lengthAttribute = DatabaseXmlAttribute(
            name: "length",
            defaultValue: "0"
        )
        
        static let variableLengthAttribute = DatabaseXmlAttribute(
            name: "variable_length",
            defaultValue: SILGattConfiguratorXmlDatabase.falseString
        )
        
        static let typeAttribute = DatabaseXmlAttribute(
            name: "type",
            defaultValue: textTypeString
        )
    }
    
    struct GattConfigurationGATTEntity {
        
        static let nameAttribute = DatabaseXmlAttribute(
            name: "name",
            defaultValue: nil
        )
        
        static let uuidAttribute = DatabaseXmlAttribute(
            name: "uuid",
            defaultValue: nil
        )
    }
    
    struct GattConfigurationDescriptor {
        
        static let name = "descriptor"
        
        static let allowedPropertiesNames = [
            SILGattConfiguratorXmlDatabase.GattConfigurationProperty.readName,
            SILGattConfiguratorXmlDatabase.GattConfigurationProperty.writeName
        ]
    }
    
    struct GattConfigurationCharacteristic {
        
        static let name = "characteristic"
        
        static let allowedPropertiesNames = [
            SILGattConfiguratorXmlDatabase.GattConfigurationProperty.readName,
            SILGattConfiguratorXmlDatabase.GattConfigurationProperty.writeName,
            SILGattConfiguratorXmlDatabase.GattConfigurationProperty.writeNoResponseName,
            SILGattConfiguratorXmlDatabase.GattConfigurationProperty.notifyName,
            SILGattConfiguratorXmlDatabase.GattConfigurationProperty.indicateName,
            SILGattConfiguratorXmlDatabase.GattConfigurationProperty.reliableWriteName
        ]
    }
    
    struct GattConfigurationService {
        
        static let name = "service"
        static let primaryType = "primary"
        static let secondaryType = "secondary"
        
        static let typeAttribute = DatabaseXmlAttribute(
            name: "type",
            defaultValue: primaryType
        )
    }
    
    struct GattConfiguration {
        static let name = "gatt"
        
        static let outAttribute = DatabaseXmlAttribute(
            name: "out",
            defaultValue: "gatt_db.c"
        )
        
        static let headerAttribute = DatabaseXmlAttribute(
            name: "header",
            defaultValue: "gatt_db.h"
        )
        
        static let nameAttribute = DatabaseXmlAttribute(
            name: "name",
            defaultValue: "Custom BLE GATT"
        )
        
        static let prefixAttribute = DatabaseXmlAttribute(
            name: "prefix",
            defaultValue: "gattdb_"
        )
        
        static let genericAttributeServiceAttribute = DatabaseXmlAttribute(
            name: "generic_attribute_service",
            defaultValue: SILGattConfiguratorXmlDatabase.trueString
        )
    }
}
