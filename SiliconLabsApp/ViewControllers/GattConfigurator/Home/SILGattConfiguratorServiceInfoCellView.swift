//
//  SILGattConfiguratorServiceInfoCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 27/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorServiceInfoCellView: SILCell, SILCellView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    private var cellViewModel: SILGattConfiguratorServiceInfoCellViewModel? {
        didSet {
            updateView()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setViewModel(_ viewModel: SILCellViewModel) {
        cellViewModel = (viewModel as! SILGattConfiguratorServiceInfoCellViewModel)
    }
    
    private func updateView() {
        titleLabel.text = cellViewModel?.title
        valueLabel.text = cellViewModel?.value
    }
}
