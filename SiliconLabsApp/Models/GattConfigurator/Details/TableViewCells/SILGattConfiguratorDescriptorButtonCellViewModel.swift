//
//  SILGattConfiguratorDescriptorButtonViewCellModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 12/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorDescriptorButtonCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILGattConfiguratorDescriptorButtonCellView"
    
    var isLast: Bool = false
    
    private let onAdd: () -> Void
    
    init(onAdd: @escaping () -> Void) {
        self.onAdd = onAdd
    }
    
    func addDescriptor() {
        onAdd()
    }
}
