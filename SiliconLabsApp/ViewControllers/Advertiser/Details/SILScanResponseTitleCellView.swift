//
//  SILScanResponseTitleCellView.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 04/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILScanResponseTitleCellView: UITableViewCell, SILCellView {
    @IBOutlet weak var titleLabel: UILabel!
    
    var viewModel: SILScanResponseTitleCellViewModel? {
        didSet {
            updateView()
        }
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILScanResponseTitleCellViewModel)
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func updateView() {
        titleLabel.text = viewModel?.title
    }
    
    @IBAction func didTouchDeleteButton(_ sender: UIButton) {
        viewModel?.delete()
    }
}
