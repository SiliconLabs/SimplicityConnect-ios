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
        addAttributedTextToLabel(label: descriptorUUIDLabel, boldText: "UUID: ", regularText: viewModel?.descriptorUUID)
        addAttributedTextToLabel(label: descriptorValueLabel, boldText: "Value: ", regularText: viewModel?.valueString)
        propertyStackView.updateProperties(viewModel?.descriptor.properties ?? [])
        if let canBeModified = viewModel?.descriptor.canBeModified {
            DispatchQueue.main.async {
                self.buttonStackView.isHidden = !canBeModified
                let labelColor = UIColor.sil_primaryText()!
                self.descriptorNameLabel.textColor = labelColor
                self.descriptorUUIDLabel.textColor = labelColor
                self.descriptorValueLabel.textColor = labelColor
                self.propertyStackView.propertyColor =  UIColor.sil_regularBlue()!
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
    
    private func addAttributedTextToLabel(label: UILabel, boldText: String, regularText: String?) {
        let boldAttribute = [
            NSAttributedString.Key.font: UIFont.robotoMedium(size: 12)!
           ]
           let regularAttribute = [
            NSAttributedString.Key.font: UIFont.robotoRegular(size: 12)!
           ]
        
        let boldText = NSAttributedString(string: boldText, attributes: boldAttribute)
        let regularText = NSAttributedString(string: regularText ?? " ", attributes: regularAttribute)
        let newString = NSMutableAttributedString()
        newString.append(boldText)
        newString.append(regularText)
        
        label.attributedText = newString
    }
}
