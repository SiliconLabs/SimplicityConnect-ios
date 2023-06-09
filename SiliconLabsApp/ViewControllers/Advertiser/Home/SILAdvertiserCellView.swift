//
//  SILAdvertiserCell.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertiserCellView: SILCell, SILAdvertiserHomeCellView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var enableSwitch: SILSwitch!
    @IBOutlet weak var affordanceImage: UIImageView!

    private var viewModel: SILAdvertiserCellViewModel? {
        didSet {
            didSetViewModel()
        }
    }
    
    private var state: SILAdvertiserCellViewModel.State? {
        didSet {
            didSetState(oldValue: oldValue)
        }
    }
    
    private var stateToken: SILObservableToken?
    
    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = (viewModel as! SILAdvertiserCellViewModel)
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
    
    private func didSetState(oldValue: SILAdvertiserCellViewModel.State?) {
        titleLabel.text = state?.name
        enableSwitch.isOn = state?.isOn ?? false
        changeAffordanceImageWhenCellIsTapped()
    }
    
    private func changeAffordanceImageWhenCellIsTapped() {
        if(state?.isExpanded == true) {
            affordanceImage.image = UIImage(systemName: "chevron.up")
        } else {
            affordanceImage.image = UIImage(systemName: "chevron.down")
        }
    }
    
    @IBAction func toggleEnableSwitch(_ sender: SILSwitch) {
        viewModel?.toggleEnableSwitch(isOn: sender.isOn)
    }
    
    @IBAction func editAdvertiser(_ sender: Any) {
        viewModel?.editAdvertiser()
    }
    
    @IBAction func removeAdvertiser(_ sender: Any) {
        viewModel?.removeAdvertiser()
    }
    
    @IBAction func copyAdvertiserSet(_ sender: Any) {
        viewModel?.copyAdvertiserSet()
    }
    
}
