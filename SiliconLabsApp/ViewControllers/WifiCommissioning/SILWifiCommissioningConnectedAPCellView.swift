//
//  SILWifiCommissioningConnectedAPCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 25/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

class SILWifiCommissioningConnectedAPCellView: SILWifiCommissioningAPCellView {
    
    @IBOutlet weak var macAddressLabel: UILabel!
    @IBOutlet weak var ipAddressLabel: UILabel!
    
    private var viewModel: SILWifiCommissioningConnectedAPCellViewModel? {
        didSet {
            didSetViewModel()
        }
    }
    
    override func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILWifiCommissioningConnectedAPCellViewModel)
    }
    
    private func didSetViewModel() {
        if let viewModel = viewModel {
            name.text = viewModel.name
            securityType.text = viewModel.securityType
            dotView.color = viewModel.dotColor
            macAddressLabel.text = viewModel.macAddress
            ipAddressLabel.text = viewModel.ipAddress
        }
    }
}
