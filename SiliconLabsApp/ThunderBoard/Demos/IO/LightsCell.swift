//
//  LightsCell.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 12/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

class LightsCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet var lights: [UISwitch]!
    
    @IBAction func switched(_ sender: UISwitch) {
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
}
