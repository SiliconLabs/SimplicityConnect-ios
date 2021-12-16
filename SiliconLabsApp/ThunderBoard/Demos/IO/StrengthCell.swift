//
//  StrengthCell.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 12/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

class StrengthCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var barView: BarView!
    
     var level: Int {
        get {
            return barView.level
        }
        set (newValue) {
            barView.level = newValue
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        level = 0
    }

}
