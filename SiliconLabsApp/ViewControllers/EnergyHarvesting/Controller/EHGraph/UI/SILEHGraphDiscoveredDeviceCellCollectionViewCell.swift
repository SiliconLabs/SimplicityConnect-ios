//
//  SILRSSIGraphDiscoveredDeviceCellCollectionViewCell.swift
//  BlueGecko
//
//  Created by Mantosh Kumar on 02/10/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit

class SILEHGraphDiscoveredDeviceCellCollectionViewCell: UICollectionViewCell {
    
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
