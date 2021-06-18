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
    func didTappedOKButton(deviceName text: String, bluetoothState: Bool)
    func didTappedCancelButton()
}

@objc
@objcMembers
class SILIOPDeviceNamePopup: UIViewController {
    @IBOutlet weak var deviceNameTextField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    var delegate: SILIOPPopupDelegate?
    private var iopCentralManager = SILIOPTesterCentralManager()
    private var bluetoothState: Bool = true
    private var disposeBag = SILObservableTokenBag()
    
    private let Description = #"This feature will execute a set of Bluetooth operations against a Silicon Labs device to test for interoperability (IOP). The device name can be read from the display on your Silicon Labs kit where the IOP sample application is running. For more information about IOP and which sample application to use please read:"#
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 400, height: 320)
            } else {
                return CGSize(width: 300, height: 350)
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
        self.deviceNameTextField.text = "IOP Test"
        self.descriptionLabel.text = Description
        
        weak var weakSelf = self
        let bluetoothStatusSubscription = iopCentralManager.newPublishConnectionStatus().observe({ status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .bluetoothEnabled(enabled: enabled):
                weakSelf.bluetoothState = enabled
                
            default:
                break
            }
        })
        disposeBag.add(token: bluetoothStatusSubscription)
    }
    
    //MARK: INTERNAL METHODS

    func showPopupAlert() {
        let alert = UIAlertController(title: "Please enter a valid device name", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    func dismissKeyBoard() {
        self.view.endEditing(true)
    }
    
    func navigateToTestIOPScreen() {
        self.dismissKeyBoard()
        
        guard let deviceName = self.deviceNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !deviceName.isEmpty else {
            self.showPopupAlert()
            self.view.endEditing(true)
            return
        }
        self.dismiss(animated: true, completion: nil)
        self.delegate?.didTappedOKButton(deviceName: deviceName, bluetoothState: bluetoothState)
    }
    
    //MARK:ACTION METHOD
    
    @IBAction func didTappedCancelBtn(_ sender: Any) {
        self.delegate?.didTappedCancelButton()
    }
    
    @IBAction func didTappedOKBtn(_ sender: Any) {
        self.navigateToTestIOPScreen()
    }
    
    @IBAction func didTapInfoButton(_ sender: UIButton) {
        if let url = URL(string: "https://www.silabs.com/documents/public/application-notes/an1346-running-ble-iop-test.pdf") {
            UIApplication.shared.open(url)
        }
    }
}

//MARK: UITEXTFIELD DELEGATE METHOD
extension SILIOPDeviceNamePopup: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.navigateToTestIOPScreen()
        return true
    }
}
