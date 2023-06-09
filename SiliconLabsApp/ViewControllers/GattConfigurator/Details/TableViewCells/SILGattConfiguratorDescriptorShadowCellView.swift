//
//  SILGattConfiguratorDesciptorShadowCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 25/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorDesciptorShadowCellView: SILCell, SILCellView {
    
    private var viewModel: SILGattConfiguratorDescriptorShadowCellViewModel?
    
    @IBOutlet weak var characteristicShadowView: UIView!
    @IBOutlet weak var descriptorShadowView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILGattConfiguratorDescriptorShadowCellViewModel)
    }
}
