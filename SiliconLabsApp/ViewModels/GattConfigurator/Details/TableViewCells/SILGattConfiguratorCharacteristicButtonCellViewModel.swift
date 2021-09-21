//
//  SILGattConfiguratorCharacteristicButtonCellViewModel.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 22/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorCharacteristicButtonCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILGattConfiguratorCharacteristicButtonCellView"
    
    private let onAdd: () -> Void
    
    init(onAdd: @escaping () -> Void) {
        self.onAdd = onAdd
    }
    
    func addCharacteristic() {
        onAdd()
    }
}
