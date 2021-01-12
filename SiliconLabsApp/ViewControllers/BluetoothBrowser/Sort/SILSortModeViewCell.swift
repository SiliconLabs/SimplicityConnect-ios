//
//  SILSortModeViewCell.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 10/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILSortModeViewCell: UITableViewCell {

    @IBOutlet weak var sortModeLabel: UILabel!
    @IBOutlet weak var checkImage: UIImageView!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            sortModeLabel.textColor = UIColor.sil_regularBlue()
            checkImage.isHidden = false
        } else {
            sortModeLabel.textColor = UIColor.sil_primaryText()
            checkImage.isHidden = true
        }
    }

}
