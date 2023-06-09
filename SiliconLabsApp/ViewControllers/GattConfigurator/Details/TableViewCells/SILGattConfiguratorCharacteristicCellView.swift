//
//  SILGattConfiguratorCharacteristicCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 25/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorCharacteristicCellView: SILCell, SILCellView {
    
    @IBOutlet weak var propertyStackView: SILPropertyStackView!
    
    private var viewModel: SILGattConfiguratorCharacteristicCellViewModel? {
        didSet {
            didSetViewModel()
        }
    }
    
    @IBOutlet weak var characteristicNameLabel: UILabel!
    @IBOutlet weak var characteristicUUIDLabel: UILabel!
    @IBOutlet weak var shadowView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.addShadow(withOffset: SILCellShadowOffset,
                  radius: SILCellShadowRadius)
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILGattConfiguratorCharacteristicCellViewModel)
    }
    
    private func didSetViewModel() {
        self.characteristicNameLabel.text = viewModel?.name == "" ? "Unknown characteristc" : viewModel?.name
        addAttributedTextToLabel(label: characteristicUUIDLabel, boldText: "UUID: ", regularText: viewModel?.characteristicUUID)
        propertyStackView.updateProperties(viewModel?.characteristic.properties ?? [])
    }
    
    @IBAction func onCopyTouch(_ sender: UIButton) {
        viewModel?.copyGattCharacteristic()
    }
    
    @IBAction func onEditTouch(_ sender: UIButton) {
        viewModel?.editGattCharacteristic()
    }
    
    @IBAction func onDeleteTouch(_ sender: UIButton) {
        viewModel?.deleteGattCharacteristic()
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
