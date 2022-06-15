//
//  SILIOPDeviceNamePopup.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 10/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import UIKit

@objc
protocol SILIOPPopupDelegate: class {
    func didTappedCancelButton()
}

@objc
@objcMembers
class SILIOPInfoPopup: UIViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    var delegate: SILIOPPopupDelegate?
    
    private let demoDescription = #"This feature will execute a set of Bluetooth operations against a Silicon Labs device to test for interoperability (IOP). The device name can be read from the display on your Silicon Labs kit where the IOP sample application is running. For more information about IOP and which sample application to use please read:"#
    
    private let documentationUrlString = "https://www.silabs.com/documents/public/application-notes/an1346-running-ble-iop-test.pdf"
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 400, height: 270)
            } else {
                return CGSize(width: 300, height: 300)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    //MARK: View Controller LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.descriptionLabel.text = demoDescription
    }
    
    //MARK:ACTION METHOD
    
    @IBAction func didTappedCancelBtn(_ sender: Any) {
        self.delegate?.didTappedCancelButton()
    }
    
    @IBAction func didTapInfoButton(_ sender: UIButton) {
        if let url = URL(string: documentationUrlString) {
            UIApplication.shared.open(url)
        }
    }
}
