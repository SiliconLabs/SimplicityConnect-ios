//
//  SILWarningViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 13/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILWarningViewController: UIViewController {
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmSwitch: SILSwitch!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var viewModel: SILWarningViewModel!
    
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
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        okButton.layer.cornerRadius = CornerRadiusForButtons
        okButton.setTitle(viewModel.confirmButtonTitle, for: .normal)
        cancelButton.setTitle(viewModel.cancelButtonTitle, for: .normal)
    }

    @IBAction func okButtonWasTapped(_ sender: UIButton) {
        viewModel.onConfirm(with: confirmSwitch.isOn)
    }
    
    @IBAction func cancelButtonWasTapped(_ sender: UIButton) {
        viewModel.onCancel(with: confirmSwitch.isOn)
    }
}
