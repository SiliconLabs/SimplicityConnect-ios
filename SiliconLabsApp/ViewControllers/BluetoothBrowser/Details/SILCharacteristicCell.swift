//
//  SILCharacteristicCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILCharacteristicCell: UITableViewCell {

    @IBOutlet weak var characteristicName: UILabel!
    @IBOutlet weak var characteristicUuid: UILabel!
    @IBOutlet var buttons: [UIButton]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
