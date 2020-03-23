//
//  SILMapCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@objc
protocol SILMapCellDelegate {
    @objc func editName(cell: UITableViewCell)
}

@objc
protocol SILMapCellProtocol: class {
    @objc weak var delegate: SILMapCellDelegate! { get set }
}

@IBDesignable
class SILMapCell: SILCell, SILMapCellProtocol {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    weak var delegate: SILMapCellDelegate!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = ""
        uuidLabel.text = ""
    }

}
