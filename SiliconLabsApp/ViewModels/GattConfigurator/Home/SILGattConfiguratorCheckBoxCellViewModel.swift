//
//  SILGattConfiguratorCheckBoxCellViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 04/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILGattConfiguratorCheckBoxCellViewModelType : class {
    init(configuration: SILGattConfigurationEntity,  isCheckBoxHidden: Bool, addToExportedConfigurations: @escaping (SILGattConfigurationEntity, Bool) -> ())
    func onCheckBoxChange(isChecked: Bool)
}

class SILGattConfiguratorCheckBoxCellViewModel: SILCellViewModel, SILGattConfiguratorCheckBoxCellViewModelType {
    
    var reusableIdentifier: String = "SILGattConfiguratorCheckBoxCellView"
    
    private let configuration: SILGattConfigurationEntity
    private let addToExportedConfigurations: (SILGattConfigurationEntity, Bool) -> ()
    let isCheckBoxHidden: Bool
    var isChecked: Bool = false
    
    required init(configuration: SILGattConfigurationEntity,
                  isCheckBoxHidden: Bool,
                  addToExportedConfigurations: @escaping (SILGattConfigurationEntity, Bool) -> ()) {
        self.configuration = configuration
        self.addToExportedConfigurations = addToExportedConfigurations
        self.isCheckBoxHidden = isCheckBoxHidden
    }
    
    func onCheckBoxChange(isChecked: Bool) {
        self.isChecked = isChecked
        addToExportedConfigurations(configuration, isChecked)
    }
}
