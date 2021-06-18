//
//  SILGattConfiguratorCharacteristicButtonCellView.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 22/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorCharacteristicButtonCellView: SILCell, SILCellView {

    private var viewModel: SILGattConfiguratorCharacteristicButtonCellViewModel?
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILGattConfiguratorCharacteristicButtonCellViewModel)
    }
    
    @IBAction func onAddCharacteristicTouch(_ sender: Any) {
        viewModel?.addCharacteristic()
    }
}
