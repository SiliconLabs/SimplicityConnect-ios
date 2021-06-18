//
//  SILGattConfiguratorDescriptorCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 25/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorDescriptorCellView: SILCell, SILCellView {
    
    @IBOutlet weak var propertyStackView: SILPropertyStackView!
    
    private var viewModel: SILGattConfiguratorDescriptorCellViewModel? {
        didSet {
            didSetViewModel()
        }
    }
    
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var descriptorNameLabel: UILabel!
    @IBOutlet weak var descriptorUUIDLabel: UILabel!
    @IBOutlet weak var descriptorValueLabel: UILabel!
    @IBOutlet weak var characteristicShadowView: UIView!
    @IBOutlet weak var descriptorShadowView: UIView!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        characteristicShadowView.addShadow(withOffset: SILCellShadowOffset,
                  radius: SILCellShadowRadius)
        descriptorShadowView.addShadow(withOffset: SILCellShadowOffset, radius: SILCellShadowRadius)
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILGattConfiguratorDescriptorCellViewModel)
    }
    
    private func didSetViewModel() {
        self.descriptorUUIDLabel.text = viewModel?.descriptorUUID
        self.separatorView.isHidden = viewModel?.isLast ?? false
        self.descriptorValueLabel.text = viewModel?.valueString
        propertyStackView.updateProperties(viewModel?.descriptor.properties ?? [])
        if let canBeModified = viewModel?.descriptor.canBeModified {
            DispatchQueue.main.async {
                self.buttonStackView.isHidden = !canBeModified
                let labelColor = canBeModified ? UIColor.sil_primaryText()! : UIColor.sil_boulder()!
                self.descriptorNameLabel.textColor = labelColor
                self.descriptorUUIDLabel.textColor = labelColor
                self.descriptorValueLabel.textColor = labelColor
                self.propertyStackView.propertyColor = labelColor
                self.descriptorNameLabel.text = self.viewModel?.name == "" ? "Unknown descriptor" : canBeModified ?  self.viewModel?.name : "\(self.viewModel?.name ?? "") (predefined)"
            }
        }
    }
    
    @IBAction func onCopyTouch(_ sender: UIButton) {
        viewModel?.copyGattDescriptor()
    }
    
    @IBAction func onEditTouch(_ sender: UIButton) {
        viewModel?.editGattDescriptor()
    }
    
    @IBAction func onDeleteTouch(_ sender: UIButton) {
        viewModel?.deleteGattDescriptor()
    }
}
