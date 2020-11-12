//
//  SILCharacteristicWriteEnumListTableViewCell.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILCharacteristicWriteEnumListTableViewCell: UITableViewCell {
    @IBOutlet weak var fieldNameLabel: UILabel!
    @IBOutlet weak var valueAreaStackView: UIStackView!
    @IBOutlet weak var currentValueTextField: UILabel!
    private var cellViewModel: SILCharacteristicWriteEnumListCellViewModel?
    private var popoverController: WYPopoverController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fieldNameLabel.text = ""
        currentValueTextField.text = ""
    }

    func setupCell(using cellViewModel: SILCharacteristicWriteEnumListCellViewModel) {
        self.cellViewModel = cellViewModel
        self.fieldNameLabel.text = self.cellViewModel?.titleName
        self.currentValueTextField.text = self.cellViewModel?.currentSelectedValueText()
    }
}
