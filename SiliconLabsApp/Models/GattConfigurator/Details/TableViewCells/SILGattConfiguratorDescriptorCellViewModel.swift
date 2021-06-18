//
//  SILGattConfiguratorDescriptorCellViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 12/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorDescriptorCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILGattConfiguratorDescriptorCellView"
    
    let descriptor: SILGattConfigurationDescriptorEntity
    
    var name: String
    var descriptorUUID: String
    var valueString: String
    var isLast: Bool = false
    
    private let onCopy: (SILGattConfigurationDescriptorEntity) -> ()
    private let onEdit: (SILGattConfigurationDescriptorEntity) -> ()
    private let onDelete: (SILGattConfigurationDescriptorEntity) -> ()
    
    var characteristicsAndDescriptorsCells: [SILCellViewModel] = []
    
    init(descriptor: SILGattConfigurationDescriptorEntity,
         descriptorModification: EntityModification<SILGattConfigurationDescriptorEntity>) {
        self.descriptor = descriptor
        self.name = descriptor.name ?? "Unknown descriptor"
        self.valueString = ""
        self.descriptorUUID = "UUID: 0x\(descriptor.cbuuidString.uppercased())"
        self.onCopy = descriptorModification.onCopy
        self.onEdit = descriptorModification.onEdit
        self.onDelete = descriptorModification.onDelete
        setValue()
    }
    
    private func setValue() {
        switch descriptor.initialValueType {
        case .none:
            self.valueString = "Value:"
        case .hex:
            self.valueString = "Value: 0x\(descriptor.initialValue!)"
        case .text:
            self.valueString = "Value: \(descriptor.initialValue!)"
        }
    }
    
    func copyGattDescriptor() {
        onCopy(descriptor)
    }
    
    func editGattDescriptor() {
        onEdit(descriptor)
    }
    
    func deleteGattDescriptor() {
        onDelete(descriptor)
    }
}
