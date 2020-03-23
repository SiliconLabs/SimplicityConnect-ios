//
//  SILBrowserServiceViewCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILBrowserServiceViewCell: SILCell {
    
    @IBOutlet weak var serviceNameLabel: UILabel!
    @IBOutlet weak var serviceUUIDLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        serviceNameLabel.text = ""
        serviceUUIDLabel.text = ""
    }
    
}
