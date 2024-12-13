//
//  SILTCPServerViewController.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 09/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILTCPServerViewController: UIViewController,ITcpServer, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var lbl_Data_Logs: UILabel!

    @IBOutlet weak var lbl_status: UILabel!
    @IBOutlet weak var transerTableView: UITableView!
    @IBOutlet weak var wifiSpeedGaugeView: SILWifiThroughputGaugeView!
    
    
    //var network_Obj: TCPServer?
    var ip_address: String? = ""
    var server_port: String? = ""
    var  tcpServer = TCPServer.sharedInstance()
    
    var messageData = NSMutableData()
    
    var timerStart = 0
    
    var timer = Timer()
    
    var SecCount = 0
    
    var dataTransferSpeedArray: [[String: String]] = []
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLeftAlignedTitle("TCP Download")

        tcpServer.setDelegateI(self)
        //network_Obj?.delegate = self
        //setLeftAlignedTitle("Throughput Server")
        transerTableView.backgroundColor = UIColor.clear
        transerTableView.delegate = self
        transerTableView.dataSource =  self
        transerTableView.showsVerticalScrollIndicator = false
        transerTableView.showsHorizontalScrollIndicator = false
        dataTransferSpeedArray = []
        
        //lbl_IP_address.text = ip_address
        //lbl_serverPort.text = server_port
        lbl_Data_Logs.text = "Waiting for client to connect..."
        startSrerver()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
       closeServer()
    }
    
    func closeServer(){
        
        tcpServer.closeSocket()

    }
    
    func startSrerver(){
        
        tcpServer.creatrCerver()

    }


    func onDidAcceptNewSocket(_ newSocket: GCDAsyncSocket!) {
       
        lbl_Data_Logs.text = "Did connect with client"
        
    }
    
    func onDidConnect(toHost host: String!, port: UInt16) {
        
        lbl_Data_Logs.text = "Did connect with client with IP :\(String(describing: host)) to Port :\(port)"
    }
    
    func onDidRead(_ data: Data!, withTag tag: Int) {
        
        if timerStart == 0{
         
            
            self.timerStart = 1
            var previousBytesSent: Int = 0
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                let bytesSent = self.messageData.count
//                let speed =  abs(bytesSent-previousBytesSent)
                let speed =  Float(abs(bytesSent-previousBytesSent))
                self.SecCount = self.SecCount+1
                //let Bandwidth : Float = Float((speed*8)/1000000)
                let Bandwidth : Float = Float((speed*8.388608)/1000000)
                //let dataTransferSpeedDic = ["Inteval": "\(self.SecCount - 1) - \(self.SecCount) Sec", "Transfer": "\(speed.byteSize) Kbps", "Bandwidth": "\(Bandwidth) Mbits/sec"]
                let dataTransferSpeedDic = ["Inteval": "\(self.SecCount - 1) - \(self.SecCount) Sec", "Transfer": "\(speed.byteSize)", "Bandwidth": "\(Bandwidth.round(to: 2)) Mbits/sec"]

                self.dataTransferSpeedArray.append(dataTransferSpeedDic)
               
    
                self.lbl_Data_Logs.text =  "Test in progress. Total data received :\(self.messageData.count.byteSize)"
                
                self.updateTable(bandWidht: Bandwidth)
                
                previousBytesSent = bytesSent
            })
            
        }
        messageData.append(data!)
        
    }
    
    func onSocketDidDisconnectWithError(_ err: (any Error)!) {
       
        if messageData.length == 0{
           
            timer.invalidate()
            let alertController = UIAlertController(title: "Alert!", message: "TCP connection Error! Please Try again.", preferredStyle: .alert)

            let cancelAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)
            
        }else{
            
            //let Bandwidth : Float = Float((messageData.count*8)/1000000)
            //let Bandwidth : Float = Float((messageData.count*Int(8.388608))/1000000)
            let Bandwidth : Float = Float(Float((messageData.count*Int(8.388608))/1000000).round(to: 2))
            let bandwidthPerSec = Bandwidth/Float(SecCount)

            lbl_Data_Logs.text = "Result :: Total Data received : \(messageData.count.byteSize) Throughput Achieved : \(bandwidthPerSec.round(to: 2)) Mbps in  :  \(self.SecCount) sec"
            SecCount = 0
            timerStart = 0
            timer.invalidate()
            messageData = NSMutableData()
            self.updateTable(bandWidht: 0)
            closeServer()
        }
    }
    
    func onDidWriteData(withTag tag: Int) {
       
    }

}

extension SILTCPServerViewController {
    
    func updateTable(bandWidht: Float){
     let testre =   SILWifiThroughputResult(wifiSender: .wifiEFRToPhone, wifiTestType: .wifiNone, wifiValueInBits: Int(bandWidht))
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
