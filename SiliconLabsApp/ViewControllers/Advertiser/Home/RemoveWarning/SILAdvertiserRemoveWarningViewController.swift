//
//  SILAdvertiserRemoveWarningViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 13/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertiserRemoveWarningViewController: UIViewController {
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var confirmSwitch: SILSwitch!
    
    var viewModel: SILAdvertiserRemoveWarningViewModel!
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 500, height: 270)
            } else {
                return CGSize(width: 350, height: 220)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        okButton.layer.cornerRadius = CornerRadiusForButtons
    }

    @IBAction func okButtonWasTapped(_ sender: UIButton) {
        viewModel.onConfirm(with: confirmSwitch.isOn)
    }
    
    @IBAction func cancelButtonWasTapped(_ sender: UIButton) {
        viewModel.onCancel()
    }
}
