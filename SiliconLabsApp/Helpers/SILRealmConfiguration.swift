//
//  SILRealmConfiguration.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28/05/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import RealmSwift

class SILRealmConfiguration : NSObject {
    // Initial version of database
    static let SchemeVersionEFR_2_0_0: UInt64 = 0
    
    // Updated:
    // - removed mappings for OTA characteristics, they already have names the same as in document AN1086, page 10
    // - removed mappings for missing services from Generic Access Profile (https://www.bluetooth.com/specifications/assigned-numbers/generic-access-profile/)
    // - removed "search by raw advertising data" from Saved Searches's objects
    static let SchemeVersionEFR_2_0_3: UInt64 = 1
    
    // Added scheme for storing advertisers
    static let SchemeVersionEFR_2_1_0: UInt64 = 2
    
    // Updated:
    // - removed mappings for Blinky and Throughput services and characteristic
    // - added scheme for storing Gatt Configurations
    static let SchemeVersionEFR_2_3_0: UInt64 = 3
    
    // Updated:
    // - added fields for Gatt Configurations import and export
    static let SchemeVersionEFR_2_3_2: UInt64 = 4
    
    // Updated:
    // - changed type of property SILAdvertisingSetEntity.executionTime from ‘double’ to ‘int’
    static let SchemeVersionEFR_2_6_2: UInt64 = 5
    
    @objc
    static func updateRealmConfigurationIfNeeded() {
        let configuration = Realm.Configuration(
            schemaVersion: SILRealmConfiguration.SchemeVersionEFR_2_6_2,
            migrationBlock: { migration, oldSchemeVersion in
                if oldSchemeVersion < SILRealmConfiguration.SchemeVersionEFR_2_0_3 {
                    SILRealmConfiguration.performUpdateDatabaseForEFR_2_0_3(migration: migration)
                }
                if oldSchemeVersion < SILRealmConfiguration.SchemeVersionEFR_2_1_0 { }
                if oldSchemeVersion < SILRealmConfiguration.SchemeVersionEFR_2_3_0 {
                    SILRealmConfiguration.performUpdateDatabaseForEFR_2_3_0(migration: migration)
                }
                if oldSchemeVersion < SILRealmConfiguration.SchemeVersionEFR_2_3_2 {
                    SILRealmConfiguration.performUpdateDatabaseForEFR_2_3_2(migration: migration)
                }
                if oldSchemeVersion < SILRealmConfiguration.SchemeVersionEFR_2_6_2 {
                    SILRealmConfiguration.performUpdateDatabaseForEFR_2_6_2(migration: migration)
                }
            }
        )
        Realm.Configuration.defaultConfiguration = configuration
    }
    
    private static func performUpdateDatabaseForEFR_2_0_3(migration: Migration) {
        let servicesUUIDMappingsToRemove = [
            "1827",
            "1826",
            "183A",
            "1820",
            "1828",
            "1829"
        ]
        let characteristicsUUIDMappingsToRemove = [
            "F7BF3564-FB6D-4E53-88A4-5E37E0326063",
            "984227F3-34FC-4045-A5D0-2C581F81A153",
            "4F4A2368-8CCA-451E-BFFF-CF0E2EE23E9F",
            "4CC07BCF-0868-4B32-9DAD-BA4CC41E5316",
            "25F05C0A-E917-46E9-B2A5-AA2BE1245AFE",
            "0D77CC11-4AC1-49F2-BFA9-CD96AC7A92F8"
        ]
        
        migrateServiceMappings(migration: migration, servicesUUIDMappingsToRemove: servicesUUIDMappingsToRemove)
        migrateCharacteristicMappings(migration: migration, characteristicsUUIDMappingsToRemove: characteristicsUUIDMappingsToRemove)
    }
    
    
    
    private static func performUpdateDatabaseForEFR_2_3_0(migration: Migration) {
        let servicesUUIDMappingsToRemove = [
            "DE8A5AAC-A99B-C315-0C80-60D4CBB51224",
            "BBB99E70-FFF7-46CF-ABC7-2D32C71820F2",
            "BA1E0E9F-4D81-BAE3-F748-3AD55DA38B46",
        ]
        let characteristicsUUIDMappingsToRemove = [
            "5B026510-4088-C297-46D8-BE6C736A087A",
            "61A885A4-41C3-60D0-9A53-6D652A70D29C",
            "6109B631-A643-4A51-83D2-2059700AD49F",
            "47B73DD6-DEE3-4DA1-9BE0-F5C539A9A4BE",
            "BE6B6BE1-CD8A-4106-9181-5FFE2BC67718",
            "ADF32227-B00F-400C-9EEB-B903A6CC291B",
            "00A82B93-0FEB-2739-72BE-ABDA1F5993D0",
            "0A32F5A6-0A6C-4954-F413-A698FAF2C664",
            "FF629B92-332B-E7F7-975F-0E535872DDAE",
            "67E2C4F2-2F50-914C-A611-ADB3727B056D",
            "30CC364A-0739-268C-4926-36F112631E0C",
            "3816DF2F-D974-D915-D26E-78300F25E86E"
        ]
        
        migrateServiceMappings(migration: migration, servicesUUIDMappingsToRemove: servicesUUIDMappingsToRemove)
        migrateCharacteristicMappings(migration: migration, characteristicsUUIDMappingsToRemove: characteristicsUUIDMappingsToRemove)
    }
    
    private static func performUpdateDatabaseForEFR_2_3_2(migration: Migration) {
        let types = ["SILGattConfigurationEntity", "SILGattConfigurationServiceEntity", "SILGattConfigurationCharacteristicEntity", "SILGattConfigurationDescriptorEntity"]
        types.forEach { setDefaultValue(migration: migration, type: $0, fieldName: "_additionalXmlAttributes", value: nil) }
        types.forEach { setDefaultValue(migration: migration, type: $0, fieldName: "_additionalXmlChildren", value: nil) }
        setDefaultValue(migration: migration, type: "SILGattConfigurationEntity", fieldName: "projectEntity", value: nil)
        addFieldsTofGattConfigurationEntities(migration: migration)
        setFixedVariableLength(migration: migration, type: "SILGattConfigurationCharacteristicEntity")
        setFixedVariableLength(migration: migration, type: "SILGattConfigurationDescriptorEntity")
    }
    
    private static func performUpdateDatabaseForEFR_2_6_2(migration: Migration) {
        migration.enumerateObjects(ofType: SILAdvertisingSetEntity.className()) { oldObject, newObject in
            let oldTime = oldObject!["executionTime"] as? NSNumber
            newObject!["executionTime"] = oldTime?.intValue ?? 0
        }
    }
    
    private static func setDefaultValue(migration: Migration, type: String, fieldName: String, value: Any?) {
        migration.enumerateObjects(ofType: type) { old, new in
            new?[fieldName] = value
        }
    }
    
    private static func addFieldsTofGattConfigurationEntities(migration: Migration) {
        migration.enumerateObjects(ofType: "SILGattConfigurationEntity") { oldObject, newObject in
            newObject?["_additionalXmlAttributes"] = "out:gatt_db.c:::header:gatt_db.h:::prefix:gattdb_:::generic_attribute_service:true"
        }
    }
    
    private static func setFixedVariableLength(migration: Migration, type: String) {
        migration.enumerateObjects(ofType: type, { oldObject, newObject in
            newObject?["fixedVariableLength"] = false
        })
    }
    
    private static func migrateServiceMappings(migration: Migration, servicesUUIDMappingsToRemove: [String]) {
        migration.enumerateObjects(ofType: "SILServiceMap") { oldObject, _ in
            if  let oldObject = oldObject,
                let uuid = oldObject["uuid"] as? String,
                servicesUUIDMappingsToRemove.contains(uuid) {
                    migration.delete(oldObject)
            }
        }
    }
    
    private static func migrateCharacteristicMappings(migration: Migration, characteristicsUUIDMappingsToRemove: [String]) {
         migration.enumerateObjects(ofType: "SILCharacteristicMap") { oldObject, _ in
             if  let oldObject = oldObject,
                 let uuid = oldObject["uuid"] as? String,
                 characteristicsUUIDMappingsToRemove.contains(uuid) {
                     migration.delete(oldObject)
             }
         }
    }
}
