//
//  SILAdvertisingDataValueCellView.swift
//  BlueGecko
//
//  Created by Michał Lenart on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertisingDataValueCellView: UITableViewCell, SILCellView {
    @IBOutlet weak var valueContainerView: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    var viewModel: SILAdvertisingDataValueCellViewModel? {
        didSet {
            updateView()
        }
    }
    
    private func updateView() {
        valueLabel.text = viewModel?.value
        deleteButton.isHidden = !(viewModel?.hasDeleteButton ?? false)
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
    
    @IBAction func didTouchDeleteButton(_ sender: Any) {
        viewModel?.delete()
    }
    
    // MARK: SILCellView
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILAdvertisingDataValueCellViewModel)
    }
}
