//
//  SILWifiCommissioningAPCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 04/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

class SILWifiCommissioningAPCellView: SILCell, SILCellView {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var securityType: UILabel!
    @IBOutlet weak var dotView: SILDot!
    
    private var viewModel: SILWifiCommissioningAPCellViewModel? {
        didSet {
            didSetViewModel()
        }
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILWifiCommissioningAPCellViewModel)
    }
    
    private func didSetViewModel() {
        if let viewModel = viewModel {
            name.text = viewModel.name
            securityType.text = viewModel.securityType
            dotView.color = viewModel.dotColor
        }
    }
}
