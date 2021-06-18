//
//  SILGattConfiguratorServiceInfoCellViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 27/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorServiceInfoCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILGattConfiguratorAdTypeCellView"
    
    let title: String
    let value: String
    
    init(service: SILGattConfigurationServiceEntity) {
        self.title = service.cbuuidString.count == 4 ? "0x\(service.cbuuidString) - \(service.name ?? "")" : "\(service.cbuuidString)"
        self.value = "\(service.characteristics.count) Characteristics"
    }
}
