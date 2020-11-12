//
//  SILAdvertisingServiceRepository.swift
//  BlueGecko
//
//  Created by Michał Lenart on 12/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertisingServiceRepository {
    private var bluetoothXmlParser: SILBluetoothXMLParser = SILBluetoothXMLParser.shared()!
    
    private lazy var services: [SILAdvertisingServiceEntity] = {
        let dict = bluetoothXmlParser.servicesDictionary()!
        return dict.idKeys()!.map({
            let service = dict.object(forIdKey: ($0 as! NSObject)) as! SILBluetoothServiceModel
            
            return SILAdvertisingServiceEntity(uuid: service.uuidString, name: service.name)
        })
    }()
    
    func getServices() -> [SILAdvertisingServiceEntity] {
        return services
    }
    
    func getService(byUuid uuid: String) -> SILAdvertisingServiceEntity? {
        return services.first(where: { service in service.uuid == uuid })
    }
}
