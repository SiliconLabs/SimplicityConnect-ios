//
//  RoundCell.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 06/03/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

class RoundCell: UITableViewCell {

    @objc var isRounded: Bool = false {
        didSet {
            if self.isRounded == true {
                self.clipsToBounds = true
                self.layer.cornerRadius = 10
                self.layer.borderColor = UIColor.white.cgColor
                self.layer.borderWidth = 1.0
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
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.layer.cornerRadius = 10
    }

}
