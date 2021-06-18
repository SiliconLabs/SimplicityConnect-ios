//
//  SILGattConfiguratorDescriptorButtonCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 25/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorDescriptorButtonCellView: SILCell, SILCellView {
    
    private var viewModel: SILGattConfiguratorDescriptorButtonCellViewModel?
    
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var separatorView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.addShadow(withOffset: SILCellShadowOffset, radius: SILCellShadowRadius)
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        let viewModel = (viewModel as! SILGattConfiguratorDescriptorButtonCellViewModel)
        self.viewModel = viewModel
        self.separatorView.isHidden = viewModel.isLast
    }
    
    @IBAction func onAddDescriptorTouch(_ sender: Any) {
        viewModel?.addDescriptor()
    }
}
