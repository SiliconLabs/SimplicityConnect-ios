//
//  SILKeychainInfoViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21/05/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILKeychainInfoViewController: UIViewController {
    @IBOutlet weak var informationsLabel: UILabel!
    var delegate: SILKeychainInfoViewContollerDelegate!
    
    let InfoText = #"The UUID dictionary contains the 128-bit UUIDs for services and characteristics that have been renamed by the user. The main purpose is simple consultation but it is also possible to change or delete them from this view. When deleted, the 128-bit UUIDs will again be shown as "Unknown Service" or "Unknown Characteristic" in the connected device's info screen."#
    
    override func viewDidLoad() {
        super.viewDidLoad()
        informationsLabel.text = InfoText
    }

    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 400, height: 400)
            } else {
                return CGSize(width: 300, height: 350)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    @IBAction func didTapOKButton(_ sender: Any) {
        delegate!.shouldCloseInfoViewController(self)
    }
}
