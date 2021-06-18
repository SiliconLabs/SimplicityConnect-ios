//
//  SILGattConfiguratorServiceCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 15/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILGattConfiguratorServiceCellView: SILCell, SILCellView {
    
    @IBOutlet weak var serviceNameLabel: UILabel!
    @IBOutlet weak var serviceUUIDLabel: UILabel!
    @IBOutlet weak var serviceTypeLabel: UILabel!
    @IBOutlet weak var moreInfoButton: UIButton!
    
    private var viewModel: SILGattConfiguratorServiceCellViewModel? {
        didSet {
            didSetViewModel()
        }
    }
    
    private var tokenBag = SILObservableTokenBag()
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILGattConfiguratorServiceCellViewModel)
    }
    
    private func didSetViewModel() {
        if let viewModel = viewModel {
            self.serviceNameLabel.text = viewModel.name == "" ? "Unknown service" : viewModel.name
            self.serviceUUIDLabel.text = viewModel.serviceUUID
            self.serviceTypeLabel.text = viewModel.serviceType
            let title = viewModel.isExpanded ? "Less info" : "More info"
            self.moreInfoButton.setTitle(title, for: .normal)
        }
    }
    
    @IBAction func onCopyTouch(_ sender: UIButton) {
        viewModel?.copyGattService()
    }

    @IBAction func onDeleteTouch(_ sender: UIButton) {
        viewModel?.deleteGattService()
    }
}
