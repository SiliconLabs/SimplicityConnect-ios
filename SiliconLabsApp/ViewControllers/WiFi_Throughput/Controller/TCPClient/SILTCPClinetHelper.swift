//
//  SILTCPClinetHelper.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 09/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD
protocol SILTCPClinetHelperDelegate {
    func didDismissSILTCPClinetHelper(ip: String, port: String)
}
class SILTCPClinetHelper: UIViewController, WYPopoverControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var lbl_IP_Address: UITextField!
    
    @IBOutlet weak var txtFld_ServerPort: UITextField!

    @IBOutlet weak var btn_cancel: UIButton!
    
    @IBOutlet weak var btn_StartUpdate: UIButton!
    
    
    var devicePopoverController: WYPopoverController?
    var popoverViewController: SILPopoverViewController?
    let getIPAddressObj = SILGetIPAddress.sharedInstance()
    var delegate: SILTCPClinetHelperDelegate?

    var ipAddress: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        btn_cancel.layer.cornerRadius = 8
        btn_StartUpdate.layer.cornerRadius = 8
        
        lbl_IP_Address.delegate = self
        txtFld_ServerPort.delegate = self
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
    
    
    @IBAction func StartServer(_ sender: Any) {
        
        if lbl_IP_Address.text == "0.0.0.0"{
            SVProgressHUD.showError(withStatus: "Please enter a valid server IP")
        }else if txtFld_ServerPort.text!.count < 4 {
            SVProgressHUD.showError(withStatus: "Please enter a valid server port to initiate TCP server.")
        }else{
            self.delegate?.didDismissSILTCPClinetHelper(ip: lbl_IP_Address.text!, port: txtFld_ServerPort.text!)
        }

    }
    
    @IBAction func cancelBtn(_ sender: UIButton) {
        self.devicePopoverController?.dismissPopover(animated: true)
    }

    //MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Check if the new text will exceed the 15-character limit
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        if textField == lbl_IP_Address {
            return newLength <= 15
        }else{
            return newLength <= 4
        }
    }
}
