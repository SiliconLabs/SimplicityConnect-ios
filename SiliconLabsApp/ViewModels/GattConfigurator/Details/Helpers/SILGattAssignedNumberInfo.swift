//
//  SILGattAssignedNumberInfo.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 30/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct SILGattAssignedNumberInfo {
    let fullName: String
    let name: String
    let prefixUUID: String
    let uuid: String
    let entity: SILGattAssignedNumberEntity
    
    init(entity: SILGattAssignedNumberEntity) {
        self.fullName = "\(entity.name) (0x\(entity.uuid.uppercased()))"
        self.prefixUUID = "0x\(entity.uuid)"
        self.uuid = entity.uuid
        self.name = entity.name
        self.entity = entity
    }
}
