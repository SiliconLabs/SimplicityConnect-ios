//
//  RGBCell.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 17/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

class RGBCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lightSwitch: UISwitch!
    
    @IBAction func switched(_ sender: UISwitch) {
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lightSwitch.isOn = false
    }

}
