//
//  SILScanResponseValueCellView.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 04/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILScanResponseValueCellView: UITableViewCell, SILCellView {
    @IBOutlet weak var valueContainerView: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    
    var viewModel: SILScanResponseValueCellViewModel? {
        didSet {
            updateView()
        }
    }
    
    private func updateView() {
        valueLabel.text = viewModel?.value
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }
    
    func setupAppearance() {
        valueContainerView.layer.cornerRadius = 4
        valueContainerView.layer.shouldRasterize = true
        valueContainerView.layer.rasterizationScale = UIScreen.main.scale
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    // MARK: SILCellView
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILScanResponseValueCellViewModel)
    }
}
