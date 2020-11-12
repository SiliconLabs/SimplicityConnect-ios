//
//  SILSILAdvertisingDataTitleCellView.swift
//  BlueGecko
//
//  Created by Michał Lenart on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertisingDataTitleCellView: UITableViewCell, SILCellView {
    @IBOutlet weak var titleLabel: UILabel!
    
    var viewModel: SILAdvertisingDataTitleCellViewModel? {
        didSet {
            updateView()
        }
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILAdvertisingDataTitleCellViewModel)
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func updateView() {
        titleLabel.text = viewModel?.title
    }
    
    @IBAction func didTouchDeleteButton(_ sender: Any) {
        viewModel?.delete()
    }
}
