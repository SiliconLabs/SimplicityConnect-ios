//
//  SILTCPServerHelper.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 09/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol SIL_TLS_Tx_HelperDelegate {
 
    func didDismissSIL_TLS_Tx_ServerHelper(ip: String, port: String)
}
class SIL_TLS_Tx_Helper: UIViewController ,WYPopoverControllerDelegate, UITextFieldDelegate{

    
    
    @IBOutlet weak var lbl_IP_Address: UILabel!
    
    @IBOutlet weak var txtFld_ServerPort: UITextField!
    
    @IBOutlet weak var btn_cancel: UIButton!
    
    @IBOutlet weak var btn_StartUpdate: UIButton!
    @IBOutlet weak var lbl_heading: UILabel!
    
    @IBOutlet weak var descriptionText: UITextView!
    
    var devicePopoverController: WYPopoverController?
    var popoverViewController: SILPopoverViewController?
    let getIPAddressObj = SILGetIPAddress.sharedInstance()
    var delegate: SIL_TLS_Tx_HelperDelegate?

    var ipAddress: String = ""
    var heading: String = ""
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(nibName: "SIL_TLS_Tx_Helper", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ipAddress = getIPAddressObj.getIPAddresses(toDo: true)
        self.setupTextLabels()
        self.setupTextView()
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
    
    // MARK: - Setup Methods
    
    func setupTextLabels() {
        
        btn_cancel.layer.cornerRadius = 8
        btn_StartUpdate.layer.cornerRadius = 8
     
        let ip = ipAddress
        
        
        //lbl_heading.text = heading
        
        
        if ip == "0.0.0.0"{
             lbl_IP_Address.text = ip
        }else{
            lbl_IP_Address.text = ip
        }
    }
    
    func setupTextView() {
        self.txtFld_ServerPort.delegate = self
        if heading == "TLS TX"{
            descriptionText.text = "Ensure to flash TLS_TX on the FW and enter the below details  to perform TLS throughput."
        }else if heading == "TLS RX" {
            descriptionText.text = "Ensure to flash TLS_RX on the FW and enter the below details  to perform TLS throughput."
        }
    }

    @IBAction func StartServer(_ sender: Any) {
        txtFld_ServerPort.resignFirstResponder()
        if lbl_IP_Address.text == "0.0.0.0"{
            SVProgressHUD.showError(withStatus: "Could not find a valid en0/ipv4 address to initiate TCP server. Please connect your phone with your local network.")
        }else if txtFld_ServerPort.text!.count < 4 {
            SVProgressHUD.showError(withStatus: "Please enter a valid server port to initiate TCP server.")
        }else{
            
            self.delegate?.didDismissSIL_TLS_Tx_ServerHelper(ip: lbl_IP_Address.text!, port: txtFld_ServerPort.text!)
        }
    }
    
    @IBAction func cancelBtn(_ sender: UIButton) {
        self.devicePopoverController?.dismissPopover(animated: true)
    }
    
    //MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Check if the new text will exceed the 12-character limit
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        return newLength <= 4
    }
}
