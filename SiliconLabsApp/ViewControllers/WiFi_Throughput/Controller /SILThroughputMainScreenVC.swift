//
//  SILThroughputMainScreenVc.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 09/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILThroughputMainScreenVC: UIViewController, WYPopoverControllerDelegate, SILTCPServerHelperDelegate, SILTCPClinetHelperDelegate, SILUDPClinetHelperDelegate, SILUDPServerHelperDelegate, SIL_TLS_Tx_HelperDelegate {
  
   
    private var devicePopoverController: WYPopoverController?
    let storyBoard : UIStoryboard = UIStoryboard(name: "WifiThroughputStoryboard", bundle:nil)
    
    var TLS_TX_RX: String = ""
    var totalBytes = 0
    var totalTime = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setLeftAlignedTitle("WiFi Throughput")
        setupBackground()
    }
    private func setupBackground() {
        self.view.backgroundColor = UIColor.sil_background()
        //self.appsView.backgroundColor = UIColor.sil_background()
    }
    //MARK: TCP IBAction
    @IBAction func Button_Client(_ sender: Any) {
        let TCPClinetHelper = SILTCPClinetHelper()
        self.devicePopoverController = WYPopoverController(contentViewController: TCPClinetHelper)
        self.devicePopoverController?.delegate = self
        TCPClinetHelper.devicePopoverController = self.devicePopoverController
        TCPClinetHelper.delegate = self
        self.devicePopoverController?.presentPopoverAsDialog(animated: true)        
    }
    
    @IBAction func Button_Server(_ sender: Any) {
        let TCPServerHelper = SILTCPServerHelper()
        self.devicePopoverController = WYPopoverController(contentViewController: TCPServerHelper)
        self.devicePopoverController?.delegate = self
        TCPServerHelper.devicePopoverController = self.devicePopoverController
        TCPServerHelper.delegate = self
        self.devicePopoverController?.presentPopoverAsDialog(animated: true)
    }
    
    //MARK: UDP IBAction
    @IBAction func Button_UdpClient(_ sender: Any) {
        let UDPClinetHelper = SILUdpClientHelper()
        self.devicePopoverController = WYPopoverController(contentViewController: UDPClinetHelper)
        self.devicePopoverController?.delegate = self
        UDPClinetHelper.devicePopoverController = self.devicePopoverController
        UDPClinetHelper.delegate = self
        self.devicePopoverController?.presentPopoverAsDialog(animated: true)
    }

    @IBAction func Button_UdpServer(_ sender: Any) {
//        let  udpServer = UdpServer.sharedInstance()
//        udpServer.initUdpServer("", port: 5005)
        let UDPServerHelper = SILUdpServerHelper()
        self.devicePopoverController = WYPopoverController(contentViewController: UDPServerHelper)
        self.devicePopoverController?.delegate = self
        UDPServerHelper.devicePopoverController = self.devicePopoverController
        UDPServerHelper.delegate = self
        self.devicePopoverController?.presentPopoverAsDialog(animated: true)
    }
    
    //MARK: TSL IBAction
    @IBAction func Button_TLSUpload(_ sender: Any) {

        TLS_TX_RX = "UPLOAD"
        let TCPServerHelper = SIL_TLS_Tx_Helper()
        self.devicePopoverController = WYPopoverController(contentViewController: TCPServerHelper)
        self.devicePopoverController?.delegate = self
        TCPServerHelper.devicePopoverController = self.devicePopoverController
        TCPServerHelper.heading = "TLS RX"
        TCPServerHelper.delegate = self
        self.devicePopoverController?.presentPopoverAsDialog(animated: true)
        
    }
    
    @IBAction func Button_TLSDownload(_ sender: Any) {
        
        TLS_TX_RX = "DOWNLOAD"
        let TCPServerHelper = SIL_TLS_Tx_Helper()
        self.devicePopoverController = WYPopoverController(contentViewController: TCPServerHelper)
        self.devicePopoverController?.delegate = self
        TCPServerHelper.devicePopoverController = self.devicePopoverController
        TCPServerHelper.heading = "TLS TX"
        TCPServerHelper.delegate = self
        self.devicePopoverController?.presentPopoverAsDialog(animated: true)
    }
    
    // MARK: - SILTCPClinetHelperDelegate
    func didDismissSILTCPClinetHelper(ip: String, port: String){
        devicePopoverController?.dismissPopover(animated: true)
        let WifiThroughputVC = storyBoard.instantiateViewController(withIdentifier: "WifiThroughputVC") as! WifiThroughputVC
        WifiThroughputVC.ip_address = ip
        WifiThroughputVC.server_port = port
        self.navigationController?.pushViewController(WifiThroughputVC, animated: true)
    }
    
    // MARK: - SILTCPServerHelperDelegate
    func didDismissSILTCPServerHelper(ip: String, port: String) {
        devicePopoverController?.dismissPopover(animated: true)
        let TCPServerViewController = storyBoard.instantiateViewController(withIdentifier: "SILTCPServerViewController") as! SILTCPServerViewController
        TCPServerViewController.ip_address = ip
        TCPServerViewController.server_port = port
        
        if let port = Int32(port){
            let network_Obj = TCPServer(port: port, hostIP: ip)
            
            //TCPServerViewController.network_Obj = network_Obj
            TCPServerViewController.tcpServer = network_Obj
            
        }
        
        self.navigationController?.pushViewController(TCPServerViewController, animated: true)
        
    }
    
    // MARK: - didDismissSIL_TLS_Tx_ServerHelper
    
    
    func didDismissSIL_TLS_Tx_ServerHelper(ip: String, port: String) {
        
        devicePopoverController?.dismissPopover(animated: true)
        let TCPServerViewController = storyBoard.instantiateViewController(withIdentifier: "SIL_TLS_Tx_ViewController") as! SIL_TLS_Tx_ViewController
        
        TCPServerViewController.ip_address = ip
        TCPServerViewController.server_port = port
        TCPServerViewController.TLS_TX_RX = TLS_TX_RX
        
        
        if let port = Int32(port){
            let network_Obj = TLS_Tx(port: port, hostIP: ip)
            
            //TCPServerViewController.network_Obj = network_Obj
            TCPServerViewController.tcpServer = network_Obj
            
        }
        
        self.navigationController?.pushViewController(TCPServerViewController, animated: true)
        
    }
    
    //MARK: - SILUDPClinetHelperDelegate
    func didDismissSILUDPClinetHelper(ip: String, port: String) {
        devicePopoverController?.dismissPopover(animated: true)
        let UdpClientThroughputVC = storyBoard.instantiateViewController(withIdentifier: "SILUdpClientThroughputVC") as! SILUdpClientThroughputVC
        UdpClientThroughputVC.ip_address = ip
        UdpClientThroughputVC.server_port = port
        self.navigationController?.pushViewController(UdpClientThroughputVC, animated: true)
    }
    //MARK: - SILUDPServerHelperDelegate
    func didDismissSILUDPServerHelper(ip: String, port: String) {
        //SILUDPServerViewController
        devicePopoverController?.dismissPopover(animated: true)
        let UDPServerThroughputVC = storyBoard.instantiateViewController(withIdentifier: "SILUDPServerViewController") as! SILUDPServerViewController
        UDPServerThroughputVC.ip_address = ip
        UDPServerThroughputVC.server_port = port
        self.navigationController?.pushViewController(UDPServerThroughputVC, animated: true)
    }

}
