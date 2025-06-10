//
//  SILWiFiProvisionViewController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 26/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD


protocol SILWiFiProvisionViewControllerProtocol {
  // blueprint of a method
    func provisioningStatus(isComplete: Bool)
}

class SILWiFiProvisionViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var ssidLbl: UILabel!
    @IBOutlet weak var securityTypeLbl: UILabel!
    @IBOutlet weak var bssidLbl: UILabel!
    @IBOutlet weak var rssiLbl: UILabel!
    @IBOutlet weak var passText: UITextField!
    
    //let eyeButton = UIButton()
    var selectedCellData: ScanResult?
    var isPassHide = false
    private var wifiProvisionViewModelObj: SILWiFiProvisionViewModel = SILWiFiProvisionViewModel()
    var SILWiFiProvisionViewControllerDelegate: SILWiFiProvisionViewControllerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpUI()
    }

    func setUpUI(){
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
            view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        ssidLbl.text = selectedCellData?.ssid
        securityTypeLbl.text = selectedCellData?.securityType
        bssidLbl.text = selectedCellData?.bssid
        rssiLbl.text = selectedCellData?.rssi
        isPassHide = false
        
        let eyeButton = UIButton(type: .custom)
        eyeButton.frame = CGRect.init(x: 0, y: 0, width: 44, height: 34)
        eyeButton.setImage(UIImage(named: "eye_hide.png"), for: .normal)
        //eyeButton.setBackgroundImage(UIImage(named: "eye_hide.png"), for: .normal)
        eyeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
        //eyeButton.frame = CGRect(x: CGFloat(passText.frame.size.width - 25), y: CGFloat(5), width: CGFloat(25), height: CGFloat(25))
        eyeButton.frame = CGRect.init(x: 0, y: 0, width: 44, height: 34)
        eyeButton.tintColor = UIColor.black
        eyeButton.addTarget(self, action: #selector(self.passHide), for: .touchUpInside)
        passText.rightView = eyeButton
        passText.rightViewMode = .always
        passText.delegate = self
        passText.tag = 0 //Increment accordingly
        passText.enablesReturnKeyAutomatically = false
    }

    
    @IBAction func cancelBtn(_ sender: UIButton) {
        passText.resignFirstResponder()
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func provisionBtn(_ sender: UIButton) {
        passText.resignFirstResponder()
        if wifiProvisionViewModelObj.passwordIsEmpty(textFieldTemp: passText){
            print("true")
            alertView(alertTitle: "Alert!", alertMsg: "Please enter the Wi-Fi password correctly.", alertType: "")
        }else{
            print("false")
            SVProgressHUD.show(withStatus: "Connecting")
            provision()
        }
    }
    
    @IBAction func passHide(_ sender: Any) {
        let senderButton: UIButton = sender as! UIButton
        if (isPassHide){
            passText.isSecureTextEntry = true
            senderButton.setImage(UIImage(named: "eye_hide.png"), for: .normal)
            //senderButton.setBackgroundImage(UIImage(named: "eye_hide.png"), for: .normal)
            isPassHide = false
        } else {
            passText.isSecureTextEntry = false
            senderButton.setImage(UIImage(named: "eye_view.png"), for: .normal)
            //senderButton.setBackgroundImage(UIImage(named: "eye_view.png"), for: .normal)
            isPassHide = true
        }
    }
    func provision(){
        let paramStr = """
                       {"ssid": "\(selectedCellData?.ssid ?? "")", "passphrase": "\(passText?.text ?? "")", "security_type": "\(selectedCellData?.securityType ?? "")"}
                       """
        wifiProvisionViewModelObj.connectAPI(paramData: paramStr) { [self] (_ responseValue: SILWiFiProvisioning?, APIClientError) in
            if APIClientError == nil{
            
                if responseValue?.status == "ok" {
                    
                    do {
                        sleep(7)
                    }
                    afterSuccess()
                }else{
                    alertView(alertTitle: "Error!", alertMsg: APIClientError?.localizedDescription.description ?? "", alertType: "")
                }
            }else{
                alertView(alertTitle: "Error!", alertMsg: APIClientError?.localizedDescription.description ?? "", alertType: "")
            }
        }
    }
    func afterSuccess(){
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            self.dismiss(animated: false, completion: nil)
            self.SILWiFiProvisionViewControllerDelegate?.provisioningStatus(isComplete: true)
        }
    }
    func alertView(alertTitle: String, alertMsg: String, alertType: String){
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: {_ in
            }))
            self.present(alert, animated: true, completion: nil)
        }

    }
}


extension SILWiFiProvisionViewController {
    
    @objc func dismissKeyboard() {
        passText.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       // Try to find next responder
       if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
          nextField.becomeFirstResponder()
       } else {
          // Not found, so remove keyboard.
          textField.resignFirstResponder()
       }
       // Do not add a line break
       return false
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height - 200
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}
