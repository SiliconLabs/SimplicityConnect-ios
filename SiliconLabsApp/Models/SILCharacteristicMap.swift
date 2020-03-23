//
//  SILCharacteristicMap.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import RealmSwift


@objcMembers
public class SILCharacteristicMap: Object, SILMap {
    dynamic public var uuid: String = ""
    dynamic public var name: String = ""
    
    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    @objc static func get(with uuid: String) -> SILCharacteristicMap? {
        let realm = try! Realm()
        return realm.object(ofType: SILCharacteristicMap.self, forPrimaryKey: uuid)
    }
    
    static func get() -> Results<SILCharacteristicMap>? {
        let realm = try! Realm()
        return realm.objects(SILCharacteristicMap.self).sorted(byKeyPath: "name", ascending: false)
    }
    
    @objc static func add(_ map: SILCharacteristicMap) -> Bool {
        let realm = try! Realm()
        do {
            try realm.write {
                realm.add(map, update: .modified)
            }
        } catch {
            return false
        }
        return true
    }
    
    @objc static func create(with name: String, uuid: String) -> SILCharacteristicMap {
        let map: SILCharacteristicMap = SILCharacteristicMap()
        map.name = name
        map.uuid = uuid
        return map
    }
    
    @objc static public func remove(map uuid: String) -> Bool {
        let realm = try! Realm()
        guard let map: SILCharacteristicMap = realm.object(ofType: SILCharacteristicMap.self, forPrimaryKey: uuid) else {
            return false
        }
        do {
            try realm.write {
                realm.delete(map)
            }
        } catch {
            return false
        }
        return true
    }
}
