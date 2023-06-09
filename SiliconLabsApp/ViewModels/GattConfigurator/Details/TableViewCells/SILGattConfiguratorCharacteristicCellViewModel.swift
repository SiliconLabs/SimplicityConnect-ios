//
//  SILGattConfiguratorCharacteristicCellViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 25/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorCharacteristicCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILGattConfiguratorCharacteristicCellView"
    
    let characteristic: SILGattConfigurationCharacteristicEntity
    
    var name: String
    var characteristicUUID: String
    
    private let onCopy: (SILGattConfigurationCharacteristicEntity) -> ()
    private let onEdit: (SILGattConfigurationCharacteristicEntity) -> ()
    private let onDelete: (SILGattConfigurationCharacteristicEntity) -> ()
    
    var characteristicsAndDescriptorsCells: [SILCellViewModel] = []
    
    init(characteristic: SILGattConfigurationCharacteristicEntity,
         characteristicModification: EntityModification<SILGattConfigurationCharacteristicEntity>) {
        self.characteristic = characteristic
        self.name = characteristic.name ?? "Unknown Characteristic"
        self.characteristicUUID = "0x\(characteristic.cbuuidString.uppercased())"
        self.onCopy = characteristicModification.onCopy
        self.onEdit = characteristicModification.onEdit
        self.onDelete = characteristicModification.onDelete
    }
    
    func copyGattCharacteristic() {
        onCopy(characteristic)
    }
    
    func editGattCharacteristic() {
        onEdit(characteristic)
    }
    
    func deleteGattCharacteristic() {
        onDelete(characteristic)
    }
}
