//
//  SILFavoritePeripheral.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 28/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import RealmSwift


@objcMembers
public class SILFavoritePeripheral: Object {
    public var uuid: String = ""
    public var name: String = ""
    
    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    @objc static func isFavorite(_ peripheral: SILDiscoveredPeripheralDisplayDataViewModel) -> Bool {
        let uuid: String = peripheral.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey
        var fav = false
        let realm = try! Realm()
        if let _: SILFavoritePeripheral = realm.object(ofType: SILFavoritePeripheral.self, forPrimaryKey: uuid) {
            fav = true
        }
        return fav
    }
    
    @objc static func add(_ peripheral: SILDiscoveredPeripheralDisplayDataViewModel) {
        let uuid: String = peripheral.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey
        let name: String = peripheral.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral?.name ?? ""
        let realm = try! Realm()
        try! realm.write {
            let peripheral = SILFavoritePeripheral()
            peripheral.name = name
            peripheral.uuid = uuid
            realm.add(peripheral, update: .modified)
        }
        peripheral.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite = true
    }
    
    @objc static func remove(_ peripheral: SILDiscoveredPeripheralDisplayDataViewModel) {
        peripheral.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite = false
        let uuid: String = peripheral.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey
        let realm = try! Realm()
        guard let peripheral: SILFavoritePeripheral = realm.object(ofType: SILFavoritePeripheral.self, forPrimaryKey: uuid) else {
            return
        }
        try! realm.write {
            realm.delete(peripheral)
        }
    }
}
