//
//  SILUDPServerViewController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 06/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILUDPServerViewController: UIViewController, IUdpServer, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var lbl_DataLogs: UILabel!
    @IBOutlet weak var transerTableView: UITableView!
    @IBOutlet weak var udpWifiSpeedGaugeView: SILWifiUdpServerGaugeView!
    
    
    let  udpServer = UdpServer.sharedInstance()
    var messageData = NSMutableData()
    var timerStart = 0
    var timer = Timer()
    var SecCount = 0
    var dataTransferSpeedArray: [[String: String]] = []
    
    var ip_address: String? = ""
    var server_port: String? = ""
    var TimeoutTimer: Timer?
    
    var speedZeroCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setLeftAlignedTitle("UDP Download")

        udpServer.setDelegate_I(self)
        
        
        transerTableView.backgroundColor = UIColor.clear
        transerTableView.delegate = self
        transerTableView.dataSource =  self
        transerTableView.showsVerticalScrollIndicator = false
        transerTableView.showsHorizontalScrollIndicator = false
        timerStart = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        dataTransferSpeedArray = []
        if let portNumber: Int = Int(server_port ?? "") {
            if timerStart == 0 {
                lbl_DataLogs.text = "Waiting for client to connect..."
                udpServer.initUdpServer("", port: portNumber)
            }
        }
    }
    
//    func startTimer(){
//        
//        DispatchQueue.main.async {
//            print("Time start")
//            self.TimeoutTimer?.invalidate()
//            self.TimeoutTimer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(self.firmwareupdate_timeout), userInfo: "Test", repeats: false)
//            self.TimeoutTimer?.tolerance = 0.1
//        }
//    }
//    @objc func firmwareupdate_timeout(){
//        network_Obj?.closeSocket()
//        print("Time out cancel process ")
//        let alert = UIAlertController(title: "Alert", message: "TCP connect timeout.Please try again.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { alert in
//            self.network_Obj?.closeSocket()
//            self.devicePopoverController?.dismissPopover(animated: true)
//        }))
//                        
//        self.present(alert, animated: true, completion: nil)
//    }
}

extension SILUDPServerViewController {
    
    func updateTable(bandWidht: Float){
        let testre =   SILWifiThroughputResult(wifiSender: .wifiEFRToPhone, wifiTestType: .wifiNone, wifiValueInBits: Int(bandWidht))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            udpWifiSpeedGaugeView.updateView(throughputResult: testre)
            transerTableView.reloadData()
            scrollToBottom()
        }
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.dataTransferSpeedArray.count-1, section: 0)
            self.transerTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
          return 1
      }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataTransferSpeedArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = transerTableView.dequeueReusableCell(withIdentifier: "SILTransferTableViewCell", for: indexPath) as! SILTransferTableViewCell
        cell.updateAPCell(cellData: dataTransferSpeedArray[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

    //MARK: - IUdpServer
    func onReceiveDataSuccess(_ sendedTxt: String, totalTime totaltime: Int) {
        
    }
    
    func onReceiveDataError(_ err: any Error) {
        
    }

    func onDidReadDataSuccess(_ data: Data) {
        
        if timerStart == 0{
            self.timerStart = 1
            var previousBytesSent: Int = 0
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                let bytesSent = self.messageData.count
                //let speed =  abs(bytesSent-previousBytesSent)
                let speed =  Float(abs(bytesSent-previousBytesSent))
                if speed == 0 {
                    self.speedZeroCount += 1
                }
                self.SecCount = self.SecCount+1
                //let Bandwidth : Float = Float((speed*8)/1000000)
                let Bandwidth : Float = Float((speed*8.388608)/1000000)
                
                //let dataTransferSpeedDic = ["Inteval": "\(self.SecCount - 1) - \(self.SecCount) Sec", "Transfer": "\(speed.byteSize) Kbps", "Bandwidth": "\(Bandwidth) Mbits/sec"]
                let dataTransferSpeedDic = ["Inteval": "\(self.SecCount - 1) - \(self.SecCount) Sec", "Transfer": "\(speed.byteSize)", "Bandwidth": "\(Bandwidth.round(to: 2)) Mbits/sec"]

                self.dataTransferSpeedArray.append(dataTransferSpeedDic)
               
    
                self.lbl_DataLogs.text =  "Test in progress. Total data received :\(self.messageData.count.byteSize)"
                self.updateTable(bandWidht: Bandwidth)

                    if self.speedZeroCount > 10{
                        self.speedZeroCount = 0
                        self.udpServer.connectionClose()
                    }

                
                previousBytesSent = bytesSent
                if self.SecCount > 28 {
                    //self.lbl_DataLogs.text =  "Result :: Total Data Transfered : \(self.messageData.count.byteSize) Throughput Achieved : \(Bandwidth/Float(self.SecCount)) Mbps in  :  \(self.SecCount) sec"
                    //self.lbl_DataLogs.text =  "Total data received :\(self.messageData.count.byteSize)"
                    let BandwidthVal : Float = Float((self.messageData.count*Int(8.388608))/1000000)
                    let bandwidthPerSec = BandwidthVal/Float(self.SecCount)

                    self.lbl_DataLogs.text = "Result :: Total Data received : \(self.messageData.count.byteSize) Throughput Achieved : \(bandwidthPerSec.round(to: 2)) Mbps in  :  \(self.SecCount) sec"

                    self.udpServer.connectionClose()
                }
            })
            
        }
        messageData.append(data)
        
    }
    
    func udpSocketDidClose(_ error: any Error) {
        messageData = NSMutableData()
        self.updateTable(bandWidht: 0)
        SecCount = 0
        //timerStart = 0
        self.speedZeroCount = 0
        self.timer.invalidate()
    }
}
