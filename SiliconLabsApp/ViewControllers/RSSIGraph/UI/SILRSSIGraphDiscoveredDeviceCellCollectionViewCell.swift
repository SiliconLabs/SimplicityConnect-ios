//
//  SILRSSIGraphDiscoveredDeviceCellCollectionViewCell.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 28/03/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import UIKit

class SILRSSIGraphDiscoveredDeviceCellCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    
    var color: UIColor = .clear {
        didSet {
            self.dotView.backgroundColor = color
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dotView.layer.cornerRadius = dotView.bounds.height / 2.0
    }
}
