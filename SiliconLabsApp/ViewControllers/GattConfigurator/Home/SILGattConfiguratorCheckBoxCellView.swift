//
//  SILGattConfiguratorCheckBoxCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 04/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorCheckBoxCellView: SILCell, SILCellView {
    
    @IBOutlet weak var checkBox: SILCheckBox!
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILGattConfiguratorCheckBoxCellViewModel)
    }
    
    private var viewModel: SILGattConfiguratorCheckBoxCellViewModel? {
        didSet {
            if let viewModel = viewModel {
                self.checkBox.isHidden = viewModel.isCheckBoxHidden
                self.checkBox.isChecked = viewModel.isChecked
                self.checkBox.borderStyle = .roundedSquare(radius: 3)
                self.layoutIfNeeded()
            }
        }
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    @IBAction func onCheckBoxChange(_ sender: SILCheckBox) {
        viewModel?.onCheckBoxChange(isChecked: sender.isChecked)
    }
}
