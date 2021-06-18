//
//  SILGattConfiguratorSetRepository.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 02/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import RealmSwift

protocol SILGattConfigurationRepositoryType : class {
    var realm: Realm { get set }
    
    init()
    func getConfigurations() -> [SILGattConfigurationEntity]
    func getServices() -> [SILGattConfigurationServiceEntity]
    func observeConfigurations(block: @escaping ([SILGattConfigurationEntity]) -> Void) -> () -> Void
    func add(configuration: SILGattConfigurationEntity)
    func add(service: SILGattConfigurationServiceEntity)
    func add(characteristic: SILGattConfigurationCharacteristicEntity)
    func update(configuration: SILGattConfigurationEntity)
    func update(service: SILGattConfigurationServiceEntity)
    func update(characteristic: SILGattConfigurationCharacteristicEntity)
    func remove(configuration: SILGattConfigurationEntity)
    func remove(service: SILGattConfigurationServiceEntity)
    func remove(characteristic: SILGattConfigurationCharacteristicEntity)
}

class SILGattConfigurationRepository : SILGattConfigurationRepositoryType {
    var realm: Realm
    static let shared = SILGattConfigurationRepository()
    
    required init() {
        realm = try! Realm()
    }
    
    func getConfigurations() -> [SILGattConfigurationEntity] {
        let result = realm.objects(SILGattConfigurationEntity.self).sorted(byKeyPath: "createdAt").map {
            SILGattConfigurationEntity(value: $0)
        }
        return Array(result)
    }
    
    func getServices() -> [SILGattConfigurationServiceEntity] {
        let result = realm.objects(SILGattConfigurationServiceEntity.self).sorted(byKeyPath: "createdAt").map {
            SILGattConfigurationServiceEntity(value: $0)
        }
        return Array(result)
    }
    
    func getCharacteristics() -> [SILGattConfigurationCharacteristicEntity] {
        let result = realm.objects(SILGattConfigurationCharacteristicEntity.self).sorted(byKeyPath: "createdAt").map {
            SILGattConfigurationCharacteristicEntity(value: $0)
        }
        return Array(result)
    }
    
    func getDescriptors() -> [SILGattConfigurationDescriptorEntity] {
        let result = realm.objects(SILGattConfigurationDescriptorEntity.self).sorted(byKeyPath: "createdAt").map {
            SILGattConfigurationDescriptorEntity(value: $0)
        }
        return Array(result)
    }
    
    func observeConfigurations(block: @escaping ([SILGattConfigurationEntity]) -> Void) -> () -> Void {
        let results = realm.objects(SILGattConfigurationEntity.self).sorted(byKeyPath: "createdAt")
        return results.observeResults(block: { elements in
            block(elements.map {
                SILGattConfigurationEntity(value: $0)
            })
        })
    }
    
    func add(configuration: SILGattConfigurationEntity) {
        try! realm.write {
            let object = SILGattConfigurationEntity(value: configuration)
            realm.add(object)
        }
    }
    
    func add(service: SILGattConfigurationServiceEntity) {
        try! realm.write {
            let serviceObject = SILGattConfigurationServiceEntity(value: service)
            realm.add(serviceObject)
        }
    }
    
    func add(characteristic: SILGattConfigurationCharacteristicEntity) {
        try! realm.write {
            let characteristicObject = SILGattConfigurationCharacteristicEntity(value: characteristic)
            realm.add(characteristicObject)
        }
    }
    
    func update(configuration: SILGattConfigurationEntity) {
        try! realm.write {
            let object = SILGattConfigurationEntity(value: configuration)
            realm.add(object, update: .modified)
        }
    }
    
    func update(service: SILGattConfigurationServiceEntity) {
        try! realm.write {
            let object = SILGattConfigurationServiceEntity(value: service)
            realm.add(object, update: .modified)
        }
    }
    
    func update(characteristic: SILGattConfigurationCharacteristicEntity) {
        try! realm.write {
            let object = SILGattConfigurationCharacteristicEntity(value: characteristic)
            realm.add(object, update: .modified)
        }
    }
    
    func remove(configuration: SILGattConfigurationEntity) {
        try! realm.write {
            let object = realm.object(ofType: SILGattConfigurationEntity.self, forPrimaryKey: configuration.uuid)
            
            if let object = object {
                realm.delete(object, cascading: true)
            }
        }
    }
    
    func remove(service: SILGattConfigurationServiceEntity) {
        try! realm.write {
            let object = realm.object(ofType: SILGattConfigurationServiceEntity.self, forPrimaryKey: service.uuid)
            
            if let object = object {
                realm.delete(object, cascading: true)
            }
        }
    }
    
    func remove(characteristic: SILGattConfigurationCharacteristicEntity) {
        try! realm.write {
            let object = realm.object(ofType: SILGattConfigurationCharacteristicEntity.self, forPrimaryKey: characteristic.uuid)
            
            if let object = object {
                realm.delete(object, cascading: true)
            }
        }
    }
    
    func remove(descriptor: SILGattConfigurationDescriptorEntity) {
        try! realm.write {
            let object = realm.object(ofType: SILGattConfigurationDescriptorEntity.self, forPrimaryKey: descriptor.uuid)
            
            if let object = object {
                realm.delete(object, cascading: true)
            }
        }
    }
}
