//
//  WifiThroughputVC.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 06/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class WifiThroughputVC: UIViewController, ITcpClient, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var lbl_DataLogs: UILabel!
    
    @IBOutlet weak var transerTableView: UITableView!

    @IBOutlet weak var showAlert: UIView!
    
    var messageData = NSMutableData()
    
    var  tcp = TcpClient.sharedInstance()!
    
    var timerStart = 0
    
    var timer = Timer()
    
    var SecCount = 0
    
    var ip_address: String? = ""
    var server_port: String? = ""
    
    var dataTransferSpeedArray: [[String: String]] = []
    @IBOutlet weak var wifiSpeedGaugeView: SILWifiThroughputGaugeView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLeftAlignedTitle("TCP Upload")
        showAlert.isHidden = true
        tcp.setDelegate_I(self)
        transerTableView.backgroundColor = UIColor.clear
        transerTableView.delegate = self
        transerTableView.dataSource =  self
        transerTableView.showsVerticalScrollIndicator = false
        transerTableView.showsHorizontalScrollIndicator = false
        dataTransferSpeedArray = []
    }
    
    override func viewDidAppear(_ animated: Bool) {
        lbl_DataLogs.text = "Connecting to server ...."
        self.ConnectServer()
    }
    func ConnectServer(){
        if let port = Int(server_port ?? "5000"){
            tcp.openTcpConnection(ip_address, port: port)
        }
    }
    
    @IBAction func yesBtn(_ sender: UIButton) {
        showAlert.isHidden = true
        self.ConnectServer()
    }
    @IBAction func cancelBtn(_ sender: UIButton) {
        showAlert.isHidden = true
        self.navigationController?.popViewController(animated: true)
    }
    func SendData(){
       
           if timerStart == 0{
               
               self.timerStart = 1
               
               var previousBytesSent: Int = 0
               self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                   let bytesSent = self.messageData.count
                   
                   //let speed =  abs(bytesSent-previousBytesSent)
                   let speed =  Float(abs(bytesSent-previousBytesSent))
                   
                   self.SecCount = self.SecCount+1
                   
                   //let Bandwidth : Float = Float((speed*8)/1000000)
                   let Bandwidth : Float = Float((speed*8.388608)/1000000)
                 
                   self.lbl_DataLogs.text =  "Test in progress. Total data sent :\(self.messageData.count.byteSize)"
                   
                   //let dataTransferSpeedDic = ["Inteval": "\(self.SecCount - 1) - \(self.SecCount) Sec", "Transfer": "\(speed.byteSize) Kbps", "Bandwidth": "\(Bandwidth) Mbits/sec"]
                   
                   let dataTransferSpeedDic = ["Inteval": "\(self.SecCount - 1) - \(self.SecCount) Sec", "Transfer": "\(speed.byteSize)", "Bandwidth": "\(Bandwidth.round(to: 2)) Mbits/sec"]
                   
                   self.dataTransferSpeedArray.append(dataTransferSpeedDic)
                   self.updateTable(bandWidht: Bandwidth)

                   previousBytesSent = bytesSent
               })
               
           }
           
           let dataToSend = randomBytes(length: 10240)
           
           messageData.append(dataToSend!)
          
           tcp.write(dataToSend)
        
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
    
    func onSendDataSuccess(_ sendedTxt: String!) {
       
        if messageData.length == 0{
            lbl_DataLogs.text = "Connection established ...."
        }
        self.SendData()        
    }
    
    func onReciveData(_ recivedTxt: String!) {
        
    }
    
    func onConnectionError(_ err: (any Error)!) {
        
        if messageData.length == 0{
           
            timer.invalidate()
            showAlert.isHidden = false
           
//            let alertController = UIAlertController(title: "Alert!", message: "Failed to establish TCP connection. Do you want to retry ?", preferredStyle: .alert)
//
//            let RetryAction = UIAlertAction(title: "Yes", style: .default, handler: {_ in
//                
//                self.ConnectServer()
//                
//            })
//            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {_ in
//                
//                self.navigationController?.popViewController(animated: true)
//                
//            })
//            alertController.addAction(RetryAction)
//            alertController.addAction(cancelAction)
//
//            self.present(alertController, animated: true, completion: nil)
            
        }else{
            
            self.lbl_DataLogs.text =  "\(messageData.count.byteSize)"
            
            //let Bandwidth : Float = Float((messageData.count*8)/1000000)
            let Bandwidth : Float = Float(Float((messageData.count*Int(8.388608))/1000000).round(to: 2))
            let bandwidthPerSec = Bandwidth/Float(SecCount)

            //lbl_DataLogs.text = "Total Data Transfered : \(messageData.count.byteSize) Throughput Achieved : \(Bandwidth/Float(SecCount)) Mbps in  :  \(self.SecCount) sec"
            lbl_DataLogs.text = "Total Data Transferred : \(messageData.count.byteSize) Throughput Achieved : \(bandwidthPerSec.round(to: 2)) Mbps in  :  \(self.SecCount) sec"
            SecCount = 0
            timerStart = 0
            
            timer.invalidate()
            
            messageData = NSMutableData()
            self.updateTable(bandWidht: 0)
        }
    }
    
    func onConnectionSucess() {
        
        
        if tcp.asyncSocket.isConnected{
             
            SendData()
             
         }else{
             
             let alertController = UIAlertController(title: "Alert!", message: "Failed to establish TCP connection. Do you want to retry ?", preferredStyle: .alert)

             let RetryAction = UIAlertAction(title: "Yes", style: .default, handler: {_ in 
                 
                 self.ConnectServer()
                 
             })
             let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {_ in
             
                 self.navigationController?.popViewController(animated: true)
             })
            
             alertController.addAction(RetryAction)
             alertController.addAction(cancelAction)

             self.present(alertController, animated: true, completion: nil)
            
         }
        
    }

    func updateCounting(){
    
    }
    
 
    
}

extension WifiThroughputVC {
    
    func updateTable(bandWidht: Float){
        let testre =   SILWifiThroughputResult(wifiSender: .wifiPhoneToEFR, wifiTestType: .wifiNone, wifiValueInBits: Int(bandWidht))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            wifiSpeedGaugeView.updateView(throughputResult: testre)
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

extension Int {
    var byteSize: String {
        return ByteCountFormatter().string(fromByteCount: Int64(self))
    }
}

extension Float {
    var byteSize: String {
        return ByteCountFormatter().string(fromByteCount: Int64(self))
    }
}
extension Float {
    func round(to places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (Float(self) * divisor).rounded() / divisor
    }
}
