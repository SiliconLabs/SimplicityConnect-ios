//
//  SILIOPTestScenarioCellView.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 02/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import UIKit

class SILIOPTestScenarioCellView: UITableViewCell, SILCellView {
    @IBOutlet weak var testTitleLabel: UILabel!
    @IBOutlet weak var testDescriptionLabel: UILabel!
    @IBOutlet weak var testStatusView: SILIOPTestStatusView!
    
    private var viewModel: SILIOPTestScenarioCellViewModel? {
        didSet {
            if let viewModel = viewModel, viewModel.shouldUpdateView {
                testStatusView.update(newStatus: viewModel.status)
            }
        }
    }
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILIOPTestScenarioCellViewModel)
        testTitleLabel.text = self.viewModel?.name
        testDescriptionLabel.text = self.viewModel?.description
    }
}
