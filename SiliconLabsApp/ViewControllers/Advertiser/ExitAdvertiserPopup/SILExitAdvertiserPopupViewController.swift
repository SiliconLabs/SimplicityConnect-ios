//
//  SILExitAdvertiserPopupViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 09/12/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILExitAdvertiserPopupViewController: UIViewController {

    @IBOutlet weak var confirmSwitch: SILSwitch!
    @IBOutlet weak var yesButton: UIButton!
    var viewModel: SILExitAdvertiserPopupViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        confirmSwitch.isOn = false
        yesButton.layer.cornerRadius = 4.0
    }
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 500, height: 270);
            } else {
                return CGSize(width: 350, height: 220);
            }
        }
        
        set { super.preferredContentSize = newValue }
    }
    
    @IBAction func onSwitchChanged(_ sender: SILSwitch) {
        viewModel.onSwitchChange(disableWarning: sender.isOn)
    }
    
    @IBAction func onYes(_ sender: UIButton) {
        viewModel.onYes()
    }
    
    @IBAction func onNo(_ sender: UIButton) {
        viewModel.onNo()
    }
}
