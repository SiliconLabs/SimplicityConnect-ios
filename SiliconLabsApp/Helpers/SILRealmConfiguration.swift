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
    
    @objc
    static func updateRealmConfigurationIfNeeded() {
        let configuration = Realm.Configuration(
            schemaVersion: SILRealmConfiguration.SchemeVersionEFR_2_0_3,
            migrationBlock: { migration, oldSchemeVersion in
                if oldSchemeVersion < SILRealmConfiguration.SchemeVersionEFR_2_0_3 {
                    SILRealmConfiguration.performUpdateDatabaseForEFR_2_0_3(migration: migration)
                }
            }
        )
        Realm.Configuration.defaultConfiguration = configuration
    }
    
    private static func performUpdateDatabaseForEFR_2_0_3(migration: Migration) {
        func migrateServiceMappings() {
            let servicesUUIDMappingsToRemove = [
                "1827",
                "1826",
                "183A",
                "1820",
                "1828",
                "1829"
            ]
            
            migration.enumerateObjects(ofType: "SILServiceMap") { oldObject, _ in
                if  let oldObject = oldObject,
                    let uuid = oldObject["uuid"] as? String,
                    servicesUUIDMappingsToRemove.contains(uuid) {
                        migration.delete(oldObject)
                }
            }
        }
        
        func migrateCharacteristicMappings() {
            let characteristicsUUIDMappingsToRemove = [
                "F7BF3564-FB6D-4E53-88A4-5E37E0326063",
                "984227F3-34FC-4045-A5D0-2C581F81A153",
                "4F4A2368-8CCA-451E-BFFF-CF0E2EE23E9F",
                "4CC07BCF-0868-4B32-9DAD-BA4CC41E5316",
                "25F05C0A-E917-46E9-B2A5-AA2BE1245AFE",
                "0D77CC11-4AC1-49F2-BFA9-CD96AC7A92F8"
            ]
            
             migration.enumerateObjects(ofType: "SILCharacteristicMap") { oldObject, _ in
                 if  let oldObject = oldObject,
                     let uuid = oldObject["uuid"] as? String,
                     characteristicsUUIDMappingsToRemove.contains(uuid) {
                         migration.delete(oldObject)
                 }
             }
        }
        
        migrateServiceMappings()
        migrateCharacteristicMappings()
    }
}
