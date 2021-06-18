//
//  SILGattConfiguratorServiceCellViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 15/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct ServiceModification {
    let onCopy: () -> ()
    let onDelete: () -> ()
    let onCharacteristicAdd: () -> ()
    let onDescriptorAdd: (Int) -> ()
}

struct EntityModification<Entity> {
    let onCopy: (Entity) -> ()
    let onEdit: (Entity) -> ()
    let onDelete: (Entity) -> ()
}

struct EntityModificationWithIndex<Entity> {
    let onCopy: (Entity, Int) -> ()
    let onEdit: (Entity, Int) -> ()
    let onDelete: (Entity, Int) -> ()
}

class SILGattConfiguratorServiceCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILGattConfiguratorServiceCellView"

    let name: String
    let serviceType: String
    let serviceUUID: String
    
    var isExpanded: Bool
    let service: SILGattConfigurationServiceEntity
    
    let onCopy: () -> ()
    let onDelete: () -> ()
    let onCharacteristicAdd: () -> ()
    let onDescriptorAdd: (Int) -> ()
    
    private let characteristicModification: EntityModification<SILGattConfigurationCharacteristicEntity>
    private let descriptorModification: EntityModificationWithIndex<SILGattConfigurationDescriptorEntity>

    var characteristicsAndDescriptorsCells: [SILCellViewModel] = []
    
    init(service: SILGattConfigurationServiceEntity,
         serviceModification: ServiceModification,
         characteristicModification: EntityModification<SILGattConfigurationCharacteristicEntity>,
         descriptorModification: EntityModificationWithIndex<SILGattConfigurationDescriptorEntity>) {
        self.service = service
        self.name = service.name ?? "Unknown Service"
        self.serviceType = service.isPrimary ? "Primary Service" : "Secondary Service"
        self.serviceUUID = "0x\(service.cbuuidString.uppercased())"
        self.onCopy = serviceModification.onCopy
        self.onDelete = serviceModification.onDelete
        self.onCharacteristicAdd = serviceModification.onCharacteristicAdd
        self.onDescriptorAdd = serviceModification.onDescriptorAdd
        self.characteristicModification = characteristicModification
        self.descriptorModification = descriptorModification
        self.isExpanded = false
        createCharacteristicCells()
    }

    func copyGattService() {
        onCopy()
    }
    
    func deleteGattService() {
        onDelete()
    }
    
    func changeExpand() {
        self.isExpanded.toggle()
        createCharacteristicCells()
    }
    
    private func createCharacteristicCells() {
        var cellModels: [SILCellViewModel] = []
        if isExpanded && service.characteristics.count > 0 {
            for (characteristicIndex, characteristic) in service.characteristics.enumerated() {
                let characteristicCellModel = SILGattConfiguratorCharacteristicCellViewModel(characteristic: characteristic, characteristicModification: characteristicModification)
                cellModels.append(characteristicCellModel)
                
                let descriptorCellModels = createDescriptorCellModels(characteristic: characteristic, characteristicIndex: characteristicIndex)
                cellModels.append(contentsOf: descriptorCellModels)
                
                let addDescriptorButtonCellModel = createAddDescriptorButtonCellModel(characteristicIndex: characteristicIndex)
                cellModels.append(addDescriptorButtonCellModel)
            }
            let shadowCellModel = SILGattConfiguratorCharacteristicShadowCellViewModel()
            cellModels.append(shadowCellModel)
        }
        let addCharacteristicCellModel = SILGattConfiguratorCharacteristicButtonCellViewModel(onAdd: onCharacteristicAdd)
        cellModels.append(addCharacteristicCellModel)
        characteristicsAndDescriptorsCells = cellModels
    }
    
    private func createDescriptorCellModels(characteristic: SILGattConfigurationCharacteristicEntity, characteristicIndex: Int) -> [SILCellViewModel] {
        var descriptorModels = [SILCellViewModel]()
        
        for (descriptorIndex, descriptor) in characteristic.descriptors.enumerated() {
            if descriptorIndex == 0 {
                descriptorModels.append(SILGattConfiguratorDescriptorTitleCellViewModel())
            }
            let descriptorModification = EntityModification<SILGattConfigurationDescriptorEntity>(onCopy: { (descriptor) in
                self.descriptorModification.onCopy(descriptor, characteristicIndex)
            }, onEdit: { (descriptor) in
                self.descriptorModification.onEdit(descriptor, characteristicIndex)
            }, onDelete: { (descriptor) in
                self.descriptorModification.onDelete(descriptor, characteristicIndex)
            })
            
            let descriptorCellModel = SILGattConfiguratorDescriptorCellViewModel(descriptor: descriptor, descriptorModification: descriptorModification)
            descriptorModels.append(descriptorCellModel)
            if descriptorIndex == characteristic.descriptors.count - 1 {
                descriptorCellModel.isLast = true
                descriptorModels.append(SILGattConfiguratorDescriptorShadowCellViewModel())
            }
        }
        return descriptorModels
    }
    
    private func createAddDescriptorButtonCellModel(characteristicIndex: Int) -> SILCellViewModel {
        let descriptorButtonCellModel = SILGattConfiguratorDescriptorButtonCellViewModel {
            self.onDescriptorAdd(characteristicIndex)
        }
        if characteristicIndex == service.characteristics.count - 1 {
            descriptorButtonCellModel.isLast = true
        }
        return descriptorButtonCellModel
    }
}
