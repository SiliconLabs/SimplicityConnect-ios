//
//  SILRemoveServiceListWarningDialogViewController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILRemoveServiceListWarningDialogViewController: UIViewController {
    
    var viewModel: SILRemoveServiceListWarningDialogViewModel!
    
    override var preferredContentSize: CGSize {
        get {
            return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    @IBAction func onSwitchChange(_ sender: SILSwitch) {
        viewModel.onSwitchChange(disableWarning: sender.isOn)
    }
    
    @IBAction func onOk(_ sender: UIButton) {
        viewModel.onOk()
    }
    
    @IBAction func onCancel(_ sender: UIButton) {
        viewModel.onCancel()
    }
}
