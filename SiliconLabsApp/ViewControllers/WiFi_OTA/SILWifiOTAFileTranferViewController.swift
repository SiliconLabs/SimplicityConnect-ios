//
//  SILWifiOTAFileTranferViewController.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 26/02/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

class SILWifiOTAFileTranferViewController: UIViewController, NetTestDelegate, WYPopoverControllerDelegate {

    @IBOutlet weak var circleProgressView: CircleProgressView!
    @IBOutlet weak var lbl_IP_address: UILabel!
    @IBOutlet weak var lbl_serverPort: UILabel!
    @IBOutlet weak var btn_cancel: UIButton!
    @IBOutlet weak var lbl_fileName: UILabel!
    
    @IBOutlet weak var lbl_filesize: UILabel!
    @IBOutlet weak var lbl_fileLenth: UILabel!
    @IBOutlet weak var lbl_status: UILabel!
    
    var ip_address: String? = ""
    var server_port: String? = ""
    var file_name: String? = ""
    var file_length: Float = 0
    var file_path: URL?
    var network_Obj: NetTest?
    var file_finalCount: Int = 0
    var upload_Percentage: Float = 0
    var Timeout_Timer: Timer?
    var timer: Timer?
    var index = 0.0
    var devicePopoverController: WYPopoverController?

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    init() {
        super.init(nibName: "SILWifiOTAFileTranferViewController", bundle: nil)
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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTextLabels()
        network_Obj?.delegate = self
        startSrerver()
        uploadData()
        
    }
    
    @objc func uploadFileStatus(_ start: Bool) {
        network_Obj?.sendData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.lbl_status.text = "Firmware update in progress."
        }
    }
    
    
    @objc func uploadFile(_ fileCount: Int) {
        self.start_timer()
        file_finalCount = fileCount
        let totalFileLenth = Float(self.file_length/1024).rounded(.up)
         upload_Percentage = (Float(fileCount) / Float(totalFileLenth))

        DispatchQueue.main.async {
            self.lbl_fileLenth.text = "\(fileCount)/\(Int(totalFileLenth))"
        }
    }
    
    func start_timer(){
        
        DispatchQueue.main.async {
            print("Time start")
            self.Timeout_Timer?.invalidate()
            self.Timeout_Timer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(self.firmwareupdate_timeout), userInfo: "Test", repeats: false)
            self.Timeout_Timer?.tolerance = 0.1
        }
    }
    
    @objc func firmwareupdate_timeout(){
        network_Obj?.closeSocket()
        print("Time out cancel process ")
        let alert = UIAlertController(title: "Alert", message: "TCP connect timeout.Please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { alert in
            self.network_Obj?.closeSocket()
            self.devicePopoverController?.dismissPopover(animated: true)
        }))
                        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    private func uploadData() {
  
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            self.circleProgressView.progress = CGFloat(self.upload_Percentage)
        }
    }
    
    @objc func onNetTestResult(_ result: Bool) {
        print("RESULT: \(result)")
       
    }
    @objc func onConnectionClose(_ status: Bool) {
        if status == true {
            let totalFileLenth = Float(self.file_length/1024).rounded(.up)
            if file_finalCount == Int(totalFileLenth) {
                DispatchQueue.main.async {
                   
                    self.Timeout_Timer?.invalidate()
                    self.btn_cancel.setTitle("Done", for: .normal)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.lbl_status.textColor = UIColor.green
                        self.lbl_status.text = "Firmware updated successfully!"
                        
                    }
                    self.btn_cancel.backgroundColor = UIColor.systemBlue
                }
            }else{
                
                DispatchQueue.main.async {
                    self.btn_cancel.setTitle("Cancel", for: .normal)
                }
            }
        }else{
            
        }
    }
    
    @objc func firmwaeUpdateStart(_ status: Bool) {
        if status == true {
            DispatchQueue.main.async {
                self.lbl_status.text = "Reinitiating Firmware update......"
                self.btn_cancel.setTitle("Cancel", for: .normal)
            }
        }
    }
    func startSrerver(){
        
        network_Obj?.creatrCerver()

    }
 
    
    func setupTextLabels() {
        
        btn_cancel.layer.cornerRadius = 8
        let totalFileLenth = Float(self.file_length/1024).rounded(.up)
        self.lbl_fileName.text =   ": \(file_name ?? "0.0.0.0")"
        self.lbl_serverPort.text = ": \(server_port ?? "0000")"
        self.lbl_IP_address.text = ": \(ip_address ?? "filename.rps")"
        self.lbl_fileLenth.text = "0/\(Int(totalFileLenth))"
        self.btn_cancel.setTitle("Cancel", for: .normal)
        self.lbl_filesize.text = ": \(file_length) bytes"
        
    }
    
    @IBAction func clickBtn_cancel(_ sender: UIButton) {
        if let buttonTitle = sender.title(for: .normal) {
           print(buttonTitle)
            if buttonTitle == "Done" {
                network_Obj?.closeSocket()
                self.devicePopoverController?.dismissPopover(animated: true)
                //self.delegate?.didDismissSILWifiOTAFileTranferViewController()
            }else{
                let alert = UIAlertController(title: "Alert", message: "Are you sure you want to cancel firmware update process.", preferredStyle: .alert)
                let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
                    self.network_Obj?.closeSocket()
                    self.devicePopoverController?.dismissPopover(animated: true)
                    
                }
                alert.addAction(yesAction)
                alert.addAction(UIAlertAction(title: "No", style: .default, handler: { alert in
                }))
                
                self.present(alert, animated: true, completion: nil)

            }
         }
        
    }
//func 
}
