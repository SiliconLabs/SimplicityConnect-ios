//
//  SILRemoveServiceListWarningDialogViewController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILRemoveServiceListWarningDialogViewController: UIViewController {
    
    @IBOutlet weak var yesButton: UIButton!
    var viewModel: SILRemoveServiceListWarningDialogViewModel!
    
    override var preferredContentSize: CGSize {
        get {
            return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        yesButton.layer.cornerRadius = 4.0
    }
    
    @IBAction func onSwitchChange(_ sender: SILSwitch) {
        viewModel.onSwitchChange(disableWarning: sender.isOn)
    }
    
    @IBAction func onYes(_ sender: UIButton) {
        viewModel.onYesCallback()
    }
    
    @IBAction func onNo(_ sender: UIButton) {
        viewModel.onNoCallback()
    }
}
