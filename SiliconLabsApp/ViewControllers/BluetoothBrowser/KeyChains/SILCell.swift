//
//  SILCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 06/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILCell: UITableViewCell {
    
    @objc var isRounded: Bool = false {
        didSet {
            if self.isRounded == true {
                self.clipsToBounds = true
                self.layer.cornerRadius = CornerRadiusStandardValue
            } else {
                self.layer.cornerRadius = 0
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 13, *) {
            isRounded = false
        } else {
            isRounded = true
        }
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.layer.cornerRadius = CornerRadiusStandardValue
    }
}

@objc protocol SILConfigurableCell {
    @objc func configure()
}
