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

            stateToken = viewModel.state.observe { state in
                weakSelf?.state = state
            }
        } else {
            state = nil
        }
    }
    
    private func didSetState(oldValue: SILGattConfiguratorCellViewModel.State?) {
        titleLabel.text = state?.name
        serviceNumberLabel.text = "\(viewModel?.configuration.services.count ?? 0) Services"
        enableSwitch.isOn = state?.isOn ?? false
    }
    
    @IBAction func toggleEnableSwitch(_ sender: SILSwitch) {
        viewModel?.toggleEnableSwitch(isOn: sender.isOn)
    }
    
    @IBAction func editConfiguration(_ sender: Any) {
        viewModel?.editConfiguration()
    }
    
    @IBAction func removeAdvertiser(_ sender: Any) {
        viewModel?.removeConfiguration()
    }
    
    @IBAction func copyAdvertiserSet(_ sender: Any) {
        viewModel?.copyConfiguration()
    }
}
