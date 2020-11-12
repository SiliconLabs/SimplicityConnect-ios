//
//  SILCharacteristicWriteFieldTableViewCell.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILCharacteristicWriteFieldTableViewCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var fieldNameLabel: UILabel!
    @IBOutlet weak var enterValueTextField: UITextField!
    private var cellViewModel: SILCharacteristicWriteFieldCellViewModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        enterValueTextField.delegate = self
        enterValueTextField.text = ""
        fieldNameLabel.text = ""
    }
    
    func setupCell(using cellViewModel: SILCharacteristicWriteFieldCellViewModel) {
        self.cellViewModel = cellViewModel
        self.fieldNameLabel.text =  self.cellViewModel?.titleName
        self.enterValueTextField.text = self.cellViewModel?.currentValue
    }
    
    @IBAction func enterValueWasChanged(_ sender: UITextField) {
        cellViewModel?.updateValue(newValue: sender.text ?? "")
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if cellViewModel?.format == "utf8s" {
            textField.keyboardType = .asciiCapable
        } else {
            textField.keyboardType = .numberPad
            textField.addDoneButton()
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
