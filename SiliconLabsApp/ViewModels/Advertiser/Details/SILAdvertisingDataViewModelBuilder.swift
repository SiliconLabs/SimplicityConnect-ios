//
//  SILAdvertisingDataViewModelBuilder.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertisingDataViewModelBuilder {
    private let serviceRepository: SILGattAssignedNumbersRepository
    
    private var data: [SILCellViewModel] = []
    
    init(serviceRepository: SILGattAssignedNumbersRepository) {
        self.serviceRepository = serviceRepository
    }
        
    func add(completeList16: [String]?, addService: @escaping () -> Void, removeService: @escaping (Int) -> Void, removeList: @escaping () -> Void) {
        guard let list = completeList16 else {
            return
        }
                
        data.append(SILAdvertisingDataTitleCellViewModel(title: "0x03 Complete List of 16-bit Service Class UUIDs", onDelete: {
            removeList()
        }))
        
        for (index, uuid) in list.enumerated() {
            let name = mapServiceName(uuid: uuid)
            data.append(SILAdvertisingDataValueCellViewModel(value: name, onDelete: {
                removeService(index)
            }))
        }
        
        data.append(SILAdvertisingDataButtonCellViewModel(title: "Add 16-bit service", onClick: {
            addService()
        }))
    }
    
    private func mapServiceName(uuid: String) -> String {
        let service = serviceRepository.getServices().first { service in
            service.uuid == uuid
        }
        
        let name = service?.name ?? "Unknown Service"
        
        return "0x\(uuid) - \(name)"
    }
    
    func add(completeList128: [String]?, addService: @escaping () -> Void, removeService: @escaping (Int) -> Void, removeList: @escaping () -> Void) {
        guard let list = completeList128 else {
            return
        }
        
        data.append(SILAdvertisingDataTitleCellViewModel(title: "0x07 Complete List of 128-bit Service Class UUIDs", onDelete: {
            removeList()
        }))
        
        for (index, uuid) in list.enumerated() {
            data.append(SILAdvertisingDataValueCellViewModel(value: uuid, onDelete: {
                removeService(index)
            }))
        }
        
        data.append(SILAdvertisingDataButtonCellViewModel(title: "Add 128-bit service", onClick: {
            addService()
        }))
    }
    
    func build() -> [SILCellViewModel] {
        return data
    }
}
