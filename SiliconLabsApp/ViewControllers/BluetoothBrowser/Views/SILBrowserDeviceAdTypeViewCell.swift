//
//  SILBrowserDeviceAdTypeViewCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILBrowserDeviceAdTypeViewCell: SILCell {
    
    @IBOutlet weak var adTypeNameLabel: UILabel!
    @IBOutlet weak var adTypeValueLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        adTypeNameLabel.text = ""
        adTypeValueLabel.text = ""
    }
    
}
