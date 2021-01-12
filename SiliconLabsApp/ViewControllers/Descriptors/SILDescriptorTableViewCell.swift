//
//  SILDescriptorsTableViewCell.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 25/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@objc
protocol SILDescriptorTableViewCellDelegate {
    func cellDidRequestReadForDescriptor(_ descriptor: CBDescriptor?)
}

@objc
@objcMembers
class SILDescriptorTableViewCell: UITableViewCell {

    @IBOutlet weak var descriptorLabel: UILabel!
    var delegate: SILDescriptorTableViewCellDelegate?
    private var descriptorModel: SILDescriptorTableModel!
    
    @objc func configureCellWithDescriptor(_ descriptorModel: SILDescriptorTableModel) {
        self.descriptorModel = descriptorModel
        descriptorLabel.attributedText = descriptorModel.getAttributedDescriptor()
    }

    @IBAction func handleReadDescriptorTap(_ sender: Any) {
        descriptorLabel.attributedText = NSAttributedString(string: "")
        descriptorModel.shouldReadValue = true
        delegate?.cellDidRequestReadForDescriptor(descriptorModel.descriptor)
    }
}
