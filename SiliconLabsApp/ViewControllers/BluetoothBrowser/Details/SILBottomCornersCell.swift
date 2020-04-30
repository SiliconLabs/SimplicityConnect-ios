//
//  SILBottomCornersCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 27/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILBottomCornersCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.clipsToBounds = true
        self.layer.cornerRadius = CornerRadiusStandardValue
        self.layer.maskedCorners = [.layerMinXMaxYCorner,.layerMaxXMaxYCorner]
    }
    
}
