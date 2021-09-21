//
//  SILGattConfiguratorCellView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 04/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

class SILGattConfiguratorCellView: SILCell, SILCellView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var serviceNumberLabel: UILabel!
    @IBOutlet weak var enableSwitch: SILSwitch!
    
    private var viewModel: SILGattConfiguratorCellViewModel? {
        didSet {
            didSetViewModel()
        }
    }
    
    private var state: SILGattConfiguratorCellViewModel.State? {
        didSet {
            didSetState(oldValue: oldValue)
        }
    }
    
    private var stateToken: SILObservableToken?
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILGattConfiguratorCellViewModel)
    }
    
    private func didSetViewModel() {
        stateToken = nil
        
        if let viewModel = viewModel {
            weak var weakSelf = self

            enableSwitch.isUserInteractionEnabled = !viewModel.isExportModeOn
            
            stateToken = viewModel.state.observe { state in
                weakSelf?.state = state
            }
        } else {
            state = nil
        }
    }
    
    private func didSetState(oldValue: SILGattConfiguratorCellViewModel.State?) {
        titleLabel.text = state?.name
        if viewModel?.configuration.services.count == 1 {
            serviceNumberLabel.text = "\(viewModel?.configuration.services.count ?? 1) Service"
        } else {
            serviceNumberLabel.text = "\(viewModel?.configuration.services.count ?? 0) Services"
        }
        enableSwitch.isOn = state?.isOn ?? false
    }
    
    @IBAction func toggleEnableSwitch(_ sender: SILSwitch) {
        if let viewModel = viewModel, !viewModel.isExportModeOn {
            viewModel.toggleEnableSwitch(isOn: sender.isOn)
        }
    }
    
    @IBAction func editConfiguration(_ sender: Any) {
        if let viewModel = viewModel, !viewModel.isExportModeOn {
            viewModel.editConfiguration()
        }
    }
    
    @IBAction func removeAdvertiser(_ sender: Any) {
        if let viewModel = viewModel, !viewModel.isExportModeOn {
            viewModel.removeConfiguration()
        }
    }
    
    @IBAction func copyAdvertiserSet(_ sender: Any) {
        if let viewModel = viewModel, !viewModel.isExportModeOn {
            viewModel.copyConfiguration()
        }
    }
}
