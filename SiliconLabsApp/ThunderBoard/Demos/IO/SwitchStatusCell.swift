//
//  SwitchStatusCell.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 11/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

@IBDesignable
class SwitchStatusCell:  UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet var switches: [SwitchView]!
    @IBOutlet weak var switchConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        switches.forEach { (switchView) in
            switchView.switchStatus = .off
        }
    }

}
