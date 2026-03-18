//
//  SILUdpServerHelper.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 06/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol SILUDPServerHelperDelegate {
    func didDismissSILUDPServerHelper(ip: String, port: String)
}

class SILUdpServerHelper: UIViewController ,WYPopoverControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var lbl_IP_Address: UILabel!
    @IBOutlet weak var txtFld_ServerPort: UITextField!
    @IBOutlet weak var btn_cancel: UIButton!
    @IBOutlet weak var btn_StartUpdate: UIButton!
    
    var devicePopoverController: WYPopoverController?
    var popoverViewController: SILPopoverViewController?
    var delegate: SILUDPServerHelperDelegate?
    let getIPAddressObj = SILGetIPAddress.sharedInstance()
    var ipAddress: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ipAddress = getIPAddressObj.getIPAddresses(toDo: true)
        self.setupTextLabels()
        self.setupTextView()
    }
    
    @IBAction func StartServer(_ sender: Any) {
        txtFld_ServerPort.resignFirstResponder()
        if lbl_IP_Address.text == "0.0.0.0"{
            SVProgressHUD.showError(withStatus: "Could not find a valid en0/ipv4 address to initiate UDP server. Please connect your phone with your local network.")
        }else if txtFld_ServerPort.text!.count < 4 {
            SVProgressHUD.showError(withStatus: "Please enter a valid server port to initiate UDP server.")
        }else{
            self.delegate?.didDismissSILUDPServerHelper(ip: lbl_IP_Address.text!, port: txtFld_ServerPort.text!)
        }
    }
    
    @IBAction func cancelBtn(_ sender: UIButton) {
        self.devicePopoverController?.dismissPopover(animated: true)
    }
    
    // MARK: - Setup Methods
    func setupTextLabels() {
        btn_cancel.layer.cornerRadius = 8
        btn_StartUpdate.layer.cornerRadius = 8
        let ip = ipAddress
        if ip == "0.0.0.0"{
             lbl_IP_Address.text = ip
        }else{
            lbl_IP_Address.text = ip
        }
    }
    
    func setupTextView() {
        self.txtFld_ServerPort.delegate = self
    }
    
    @objc func dismissKeyboard() {
        txtFld_ServerPort.resignFirstResponder()
    }
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 540, height: 556)
            } else {
                return CGSize(width: 346, height: 350)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    //MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Check if the new text will exceed the 12-character limit
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        return newLength <= 4
    }
}
