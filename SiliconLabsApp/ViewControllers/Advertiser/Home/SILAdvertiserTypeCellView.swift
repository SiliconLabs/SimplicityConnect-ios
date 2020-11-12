//
//  SILAdvertiserTypeCellView.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 12/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertiserAdTypeCellView: SILCell, SILAdvertiserHomeCellView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    private var cellViewModel: SILAdvertiserAdTypeCellViewModel? {
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
        cellViewModel = (viewModel as! SILAdvertiserAdTypeCellViewModel)
    }
    
    private func updateView() {
        titleLabel.text = cellViewModel?.title
        valueLabel.text = cellViewModel?.value
    }
}
