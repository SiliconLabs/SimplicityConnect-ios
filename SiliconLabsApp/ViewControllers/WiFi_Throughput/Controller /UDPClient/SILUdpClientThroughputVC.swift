//
//  SILUdpClientThroughputVC.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 04/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILUdpClientThroughputVC: UIViewController, UITableViewDelegate, UITableViewDataSource, IUdpClient{
    
    @IBOutlet weak var lbl_DataLogs: UILabel!
    @IBOutlet weak var transerTableView: UITableView!
    @IBOutlet weak var udpWifiSpeedGaugeView: SILWifiUdpClientGaugeView!
    var dataTransferSpeedArray: [[String: String]] = []
    
    var timerStart = 0
    var timer = Timer()
    var messageData = NSMutableData()
    var SecCount = 0
    
    var ip_address: String? = ""
    var server_port: String? = ""
    
    let  udpClient = UdpClient.sharedInstance()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setLeftAlignedTitle("UDP Upload")

        udpClient.setDelegate_I(self)
        
        
        transerTableView.backgroundColor = UIColor.clear
        transerTableView.delegate = self
        transerTableView.dataSource =  self
        transerTableView.showsVerticalScrollIndicator = false
        transerTableView.showsHorizontalScrollIndicator = false
        dataTransferSpeedArray = []
        timerStart = 0
    }
    override func viewDidAppear(_ animated: Bool) {
        if timerStart == 0 {
            lbl_DataLogs.text = "Connecting to server ...."
            self.ConnectServer()
        }
    }
    func ConnectServer(){
        if let dataToSend = randomBytes(length: 1470) {
            let x = Int(server_port ?? "0") ?? 0
            udpClient.openUdpConnection(ip_address ?? "192.168.1.205", port: x, send: dataToSend)
        }
    }
    
    func SendData(){
        if timerStart == 0{
            self.timerStart = 1
            var previousBytesSent: Int = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                
                self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                    let bytesSent = self.messageData.count
                    
                    //let speed =  abs(bytesSent-previousBytesSent)
                    let speed =  Float(abs(bytesSent-previousBytesSent))
                    
                    self.SecCount = self.SecCount+1
                    
                    //let Bandwidth : Float = Float((speed*8)/1000000)
                    let Bandwidth : Float = Float(Float((self.messageData.count*Int(8.388608))/1000000).round(to: 2))
                    self.lbl_DataLogs.text =  "Test in progress. Total data Transferred :\(self.messageData.count.byteSize)"
                    
                    //let dataTransferSpeedDic = ["Inteval": "\(self.SecCount - 1) - \(self.SecCount) Sec", "Transfer": "\(speed.byteSize) Kbps", "Bandwidth": "\(Bandwidth) Mbits/sec"]
                    let dataTransferSpeedDic = ["Inteval": "\(self.SecCount - 1) - \(self.SecCount) Sec", "Transfer": "\(speed.byteSize)", "Bandwidth": "\(Bandwidth.round(to: 2)) Mbits/sec"]

                    self.dataTransferSpeedArray.append(dataTransferSpeedDic)
                    self.updateTable(bandWidht: Bandwidth)
                    
                    previousBytesSent = bytesSent
                })
            }
        }
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let dataToSend = self.randomBytes(length: 1470)
            if let dataToSend = dataToSend {
                self.messageData.append(dataToSend)
                //tcp.write(dataToSend)
                self.udpClient.write(dataToSend, totalTimeCount: self.SecCount)
            }
       //}
    }
    
    func randomBytes(length: Int) -> Data? {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            return nil
        }
        return data
    }
}

extension SILUdpClientThroughputVC {
    
    func updateTable(bandWidht: Float){
        let testre =   SILWifiThroughputResult(wifiSender: .wifiPhoneToEFR, wifiTestType: .wifiNone, wifiValueInBits: Int(bandWidht))
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

}

extension SILUdpClientThroughputVC {
    func onSendDataSuccess(_ sendedTxt: String, totalTime totaltime: Int) {
//        if let dataToSend = randomBytes(length: 1470) {
//            //totalBytes = totalBytes + dataToSend.count
//            //totalTime = totaltime
//            udpClient.write(dataToSend)
//        }
        DispatchQueue.main.async {
            if self.messageData.length == 0{
                self.lbl_DataLogs.text = "Connection established ...."
            }
        }
        self.SendData()
    }
    
    func onSendDataError(_ err: any Error) {
        
    }
    
    func onReciveData(_ recivedTxt: String) {
        
    }
    
    func onConnectionError(_ err: any Error) {
        
    }
    
    func onConnectionSucess(_ str: String) {
        
    }
    
    func udpSocketDidClose(_ error: any Error) {
        self.timer.invalidate()
        //timerStart = 0
        let testre =   SILWifiThroughputResult(wifiSender: .wifiPhoneToEFR, wifiTestType: .wifiNone, wifiValueInBits: Int(00))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            //self.lbl_DataLogs.text =  "Total data Transfered :\(self.messageData.count.byteSize)"
            let BandwidthVal : Float = Float((self.messageData.count*Int(8.388608))/1000000)
            let bandwidthPerSec = BandwidthVal/Float(self.SecCount)
            lbl_DataLogs.text = "Total Data Transferred : \(messageData.count.byteSize) Throughput Achieved : \(bandwidthPerSec.round(to: 2)) Mbps in  :  \(self.SecCount) sec"
            udpWifiSpeedGaugeView.updateView(throughputResult: testre)
        }
    }
}
