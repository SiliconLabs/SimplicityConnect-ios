//
//  SILTransferTableViewCell.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 12/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILTransferTableViewCell: UITableViewCell {
    @IBOutlet weak var intervalLbl: UILabel!
    @IBOutlet weak var transferLbl: UILabel!
    @IBOutlet weak var bandwidthLbl: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateAPCell(cellData: [String: String]) {
        intervalLbl.text = cellData["Inteval"]
        transferLbl.text = cellData["Transfer"]
        bandwidthLbl.text = cellData["Bandwidth"]
    }

}
