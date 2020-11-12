//
//  SILAdvertisingSetRepository.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import RealmSwift

class SILAdvertisingSetRepository {
    let realm: Realm
    
    init() {
        realm = try! Realm()
    }
    
    func getAdvertisers() -> [SILAdvertisingSetEntity] {
        let result = realm.objects(SILAdvertisingSetEntity.self).sorted(byKeyPath: "createdAt").map {
            SILAdvertisingSetEntity(value: $0)
        }
        return Array(result)
    }
    
    func observeAdvertisers(block: @escaping ([SILAdvertisingSetEntity]) -> Void) -> () -> Void {
        let results = realm.objects(SILAdvertisingSetEntity.self).sorted(byKeyPath: "createdAt")
        return results.observeResults(block: { elements in
            block(elements.map {
                SILAdvertisingSetEntity(value: $0)
            })
        })
    }
    
    func add(advertiser: SILAdvertisingSetEntity) {
        try! realm.write {
            let object = SILAdvertisingSetEntity(value: advertiser)
            realm.add(object)
        }
    }
    
    func update(advertiser: SILAdvertisingSetEntity) {
        try! realm.write {
            let object = SILAdvertisingSetEntity(value: advertiser)
            realm.add(object, update: .modified)
        }
    }
    
    func remove(advertiser: SILAdvertisingSetEntity) {
        try! realm.write {
            let object = realm.object(ofType: SILAdvertisingSetEntity.self, forPrimaryKey: advertiser.uuid)
            
            if let object = object {
                realm.delete(object)
            }
        }
    }
}

extension Results {
    func observeResults(block: @escaping ([Element]) -> Void) -> () -> Void {
        let token = self.observe { change in
            block(Array(self))
        }
        
        return {
            token.invalidate()
        };
    }
}
