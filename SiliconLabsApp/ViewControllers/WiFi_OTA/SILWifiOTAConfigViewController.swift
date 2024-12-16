//
//  SILWifiOTAConfigViewController..swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 22/02/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD


protocol SILWifiOTAConfigViewControllerDelegate {
 
    func didDismissSILWifiOTAConfigViewController()
}
//SILWifiOTAFileTranferViewControllerDelegate
class SILWifiOTAConfigViewController: UIViewController, WYPopoverControllerDelegate {

    @IBOutlet weak var lbl_IP_Address: UILabel!
    
    @IBOutlet weak var txtFld_ServerPort: UITextField!
    
    @IBOutlet weak var btn_FilePicker: UIButton!
    
    @IBOutlet weak var btn_cancel: UIButton!
    
    @IBOutlet weak var btn_StartUpdate: UIButton!
    
    private var devicePopoverController: WYPopoverController?
    var progressViewModel: SILOTAProgressViewModel?
    var popoverViewController: SILPopoverViewController?
    var silCentralManager: SILCentralManager?
    weak var peripheral: CBPeripheral?
    var progressViewController: SILOTAProgressViewController?
    let getIPAddressObj = SILGetIPAddress.sharedInstance()
    var delegate: SILWifiOTAConfigViewControllerDelegate?

    var file_Url: URL?
    var file_name: String? = ""
    var fileData: Data?
    var fileLenth: Int = 0
    var ipAddress: String = ""
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(nibName: "SILWifiOTAConfigViewController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
            view.addGestureRecognizer(tap)

        ipAddress = getIPAddressObj.getIPAddresses(toDo: true)

        self.setupTextLabels()
        self.setupTextView()
        // Add observer for wifi network check
        NotificationCenter.default.addObserver(self, selector: #selector(SILWifiOTAConfigViewController.networkStatusChanged(_:)), name: Notification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        Reachability().monitorReachabilityChanges()
    }
    
    @objc func dismissKeyboard() {
        txtFld_ServerPort.resignFirstResponder()
    }
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 540, height: 606)
            } else {
                return CGSize(width: 346, height: 547)
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
        
        btn_FilePicker.backgroundColor = .clear
        btn_FilePicker.layer.cornerRadius = 5
        btn_FilePicker.layer.borderWidth = 0.5
        btn_FilePicker.layer.borderColor = UIColor.lightGray.cgColor
        
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
    
    func adjustUITextViewHeight(textView : UITextView) {
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.sizeToFit()
        textView.isScrollEnabled = false
    }
    
    private func showWifiDisabledAlert() {
        let message = "Please check your Wi-Fi connection to use Wi-Fi OTA Demo"
        self.alertWithOKButton(title: "Wi-Fi Disabled", message: message, completion: { _ in
            self.delegate?.didDismissSILWifiOTAConfigViewController()
        })
    }
    
    @objc func networkStatusChanged(_ notification: Notification) {
        let status = Reachability().connectionStatus()
        switch status {
        case .unknown, .offline:
            showWifiDisabledAlert()
        case .online(.wwan):
            break
        case .online(.wiFi):
            break
        }
    }

    @IBAction func didPressCancelButton(_ sender: Any) {
        txtFld_ServerPort.resignFirstResponder()
        delegate?.didDismissSILWifiOTAConfigViewController()
    }
    
    @IBAction func didPressStartUpdate(_ sender: Any) {
        txtFld_ServerPort.resignFirstResponder()
        if lbl_IP_Address.text == "0.0.0.0"{
            SVProgressHUD.showError(withStatus: "Could not find a valid en0/ipv4 address to initiate TCP server. Please connect your phone with your local network.")
        }else if txtFld_ServerPort.text!.count < 4 {
            SVProgressHUD.showError(withStatus: "Please enter a valid server port to initiate TCP server.")
        }else if file_name == "" {
            SVProgressHUD.showError(withStatus: "Please select .rps file.")
        }else{
            let OTAConfigViewController = SILWifiOTAFileTranferViewController()
            OTAConfigViewController.file_name = file_name
            OTAConfigViewController.server_port = txtFld_ServerPort.text
            OTAConfigViewController.ip_address = lbl_IP_Address.text
            OTAConfigViewController.file_path = file_Url
            OTAConfigViewController.file_length = Float(fileLenth)
            if let port = Int32(txtFld_ServerPort.text!){
                let network_Obj = NetTest(port: port, fileData: fileData!, hostIP: ipAddress)
                OTAConfigViewController.network_Obj = network_Obj
            }
            self.devicePopoverController = WYPopoverController(contentViewController: OTAConfigViewController)
            self.devicePopoverController?.delegate = self
            OTAConfigViewController.devicePopoverController = self.devicePopoverController
            self.devicePopoverController?.presentPopoverAsDialog(animated: true)
        }

    }
    
    func presentOTAProgress(completion: (() -> Void)?) {
        self.progressViewModel = SILOTAProgressViewModel(peripheral: peripheral, with: silCentralManager)
        self.progressViewController = SILOTAProgressViewController(viewModel: self.progressViewModel)
        self.popoverViewController = SILPopoverViewController(nibName: nil, bundle: nil, contentViewController: self.progressViewController)
        guard let topVC = UIViewController.topViewController() else { return }
        if topVC.isKind(of: UIAlertController.self) {
            topVC.dismiss(animated: true) {
                guard let newTopVC = UIViewController.topViewController() else { return }
                newTopVC.present(self.popoverViewController!, animated: true, completion: completion)
            }
        } else {
            topVC.present(self.popoverViewController!, animated: true, completion: completion)
        }
    }
    
    func showOTAProgressForFirmwareFile(totalNumber: Int, completion: (() -> Void)?) {
        self.presentOTAProgress {
            self.progressViewModel?.totalNumberOfFiles = totalNumber
         //   self.progressViewModel?.file = file
            self.progressViewModel?.uploadingFile = true
            if let block = completion {
                block()
            }
        }
    }

    func dismissPopoverWithCompletion(completion: (() -> Void)?) {
        self.popoverViewController?.dismiss(animated: true, completion: completion)
    }

    func handleFileUploadProgress(progress: Double, uploadedBytes bytes: Int) {
        self.progressViewModel?.progressFraction = CGFloat(progress)
        self.progressViewModel?.progressBytes = bytes
    }
    
    func handleAppFileUploadCompletionForPeripheral(peripheral: CBPeripheral?, error: Error?) {
        self.progressViewModel?.uploadingFile = false
        if error == nil {
            self.progressViewModel?.finished = true
        }
    }
    
    @IBAction func select_Firmware_File(_ sender: Any) {
        self.showDocumentPickerView()
    }
    
    func showDocumentPickerView() {
        let documentPickerViewController = SILDocumentPickerViewController(documentTypes: ["public.rps"], in: .import)
        documentPickerViewController.setupDocumentPickerView()
        documentPickerViewController.delegate = self
        self.present(documentPickerViewController, animated: false, completion: nil)
    }
    
    //MARK: WYPopoverControllerDelegate
        func popoverControllerShouldDismissPopover(_ popoverController: WYPopoverController!) -> Bool {
            return false
        }
}
extension SILWifiOTAConfigViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        // Verify all the conditions
        if let sdcTextField = textField as? TextField_Util {
            return sdcTextField.verifyFields(shouldChangeCharactersIn: range, replacementString: string)
        }
        return false
    }
}


extension SILWifiOTAConfigViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        debugPrint("DID PICK")
        self.sendChosenUrl(urls: urls)
    }
    
    private func sendChosenUrl(urls: [URL]) {
        if let rpsFile = urls.first {
            
            if let filename =  urls.first?.lastPathComponent {
                file_Url = rpsFile
                do {
                    fileData = try Data(contentsOf: rpsFile)
                    fileLenth = fileData?.count ?? 0
                    print(fileLenth)
                } catch {
                    print ("loading image file error")
                }
                file_name = filename
                 self.btn_FilePicker.setTitle(filename, for: .normal)
            }
            
           
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        debugPrint("DID CANCEL")
        NotificationCenter.default.post(Notification(name: .SILIOPFileUrlChosen, object: nil, userInfo: nil))
        controller.dismiss(animated: true, completion: nil)
    }
}
