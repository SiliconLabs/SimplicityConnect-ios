//
//  SILRadioButton.swift
//  SiliconLabsApp
//
//  Created by Grzegorz Janosz on 03/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

@objc
class SILRadioButton: UIView {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var radioButton: UIButton!
    
    let RadioButtonImages = (selected: "radio_button_selected",
                             active: "radio_button_active",
                             inactive: "radio_button_inactive")
    
    @objc func select() {
        descriptionLabel.isEnabled = true
        radioButton.setImage(UIImage(named: RadioButtonImages.selected), for: .normal)
        radioButton.tintColor = UIColor.sil_regularBlue()
        radioButton.titleLabel?.textColor = UIColor.sil_primaryText()
    }
    
    @objc func deselect() {
        descriptionLabel.isEnabled = true
        radioButton.setImage(UIImage(named: RadioButtonImages.active), for: .normal)
    }
    
    @objc func disable() {
        descriptionLabel.isEnabled = false
        radioButton.setImage(UIImage(named: RadioButtonImages.inactive), for: .normal)
    }
}
