//
//  SILESLDemoTagDetailCell.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 27.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import UIKit

class SILESLDemoTagDetailCell: UITableViewCell, SILCellView {
    @IBOutlet weak var tagDetailNameLabel: UILabel!
    @IBOutlet weak var tagDetailValueNameLabel: UILabel!
    
    var viewModel: SILESLDemoTagDetailViewModel? {
        didSet {
            configure()
        }
    }

    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = viewModel as? SILESLDemoTagDetailViewModel
    }
    
    private func configure() {
        if let viewModel = viewModel {
            tagDetailNameLabel.text = viewModel.tagDetailName
            tagDetailValueNameLabel.text = viewModel.tagDetailValue
        }
    }
}
