//
//  SILWiFiMotionViewController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 28/06/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILWiFiMotionViewController: UIViewController, SILWiFiMotionSensorsViewModelProtocol {

    @IBOutlet weak var accelerationXLbl: StyledLabel!
    @IBOutlet weak var accelerationYLbl: StyledLabel!
    @IBOutlet weak var accelerationZLbl: StyledLabel!

    @IBOutlet weak var orientationXLbl: StyledLabel!
    @IBOutlet weak var orientationYLbl: StyledLabel!
    @IBOutlet weak var orientationZLbl: StyledLabel!

    var silWiFiMotionSensorsViewModel:SILWiFiMotionSensorsViewModel = SILWiFiMotionSensorsViewModel()
    var apiCallTimer: Timer?
    
     var accelerationXStr: String = ""
     var accelerationYStr: String = ""
     var accelerationZStr: String = ""

    var orientationXStr: String = ""
    var orientationYStr: String = ""
    var orientationZStr: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        silWiFiMotionSensorsViewModel.SILWiFiMotionSensorsViewModelDelegate = self
        
        let motionData = ["gyroscope": ["x": orientationXStr, "y": orientationYStr, "z": orientationZStr], "accelerometer": ["x": accelerationXStr, "y": accelerationYStr, "z": accelerationZStr]]
        uiUpdate(sensorsData: motionData)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        apiCallTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] (timer) in
            self?.silWiFiMotionSensorsViewModel.getMotionData()
        })
        //silWiFiMotionSensorsViewModel.getMotionData()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.apiCallTimer != nil{
            self.apiCallTimer?.invalidate()
            self.apiCallTimer = nil
        }
    }
    
    @IBAction func cancelBtn(_ sender: UIButton) {
        //sensorePopupView.isHidden = true
        if self.apiCallTimer != nil{
            self.apiCallTimer?.invalidate()
            self.apiCallTimer = nil
        }
        self.dismiss(animated: false, completion: nil)
    }
    @IBAction func refreshBtn(_ sender: UIButton) {
        silWiFiMotionSensorsViewModel.getMotionData()
    }
    func uiUpdate(sensorsData: Dictionary<String, Any>){
        //print(sensorsData)
        let degrees = " °"
        let gravity = " g"
        DispatchQueue.main.async {
            self.orientationXLbl.text = "\((sensorsData["gyroscope"] as? Dictionary<String, Any>)?["x"] ?? "")\(degrees)"
            self.orientationYLbl.text = "\((sensorsData["gyroscope"] as? Dictionary<String, Any>)?["y"] ?? "")\(degrees)"
            self.orientationZLbl.text = "\((sensorsData["gyroscope"] as? Dictionary<String, Any>)?["z"] ?? "")\(degrees)"
            self.accelerationXLbl.text = "\((sensorsData["accelerometer"] as? Dictionary<String, Any>)?["x"] ?? "")\(gravity)"
            self.accelerationYLbl.text = "\((sensorsData["accelerometer"] as? Dictionary<String, Any>)?["y"] ?? "")\(gravity)"
            self.accelerationZLbl.text = "\((sensorsData["accelerometer"] as? Dictionary<String, Any>)?["z"] ?? "")\(gravity)"
        }
        
    }
    func notifyMotionSensorsData(sensorsData: Dictionary<String, Any>?) {
        if let sensorsData = sensorsData {
            let aX = (sensorsData["accelerometer"] as? Dictionary<String, Any>)?["x"]
            let aY = (sensorsData["accelerometer"] as? Dictionary<String, Any>)?["y"]
            let aZ = (sensorsData["accelerometer"] as? Dictionary<String, Any>)?["z"]
            
            let gX = (sensorsData["accelerometer"] as? Dictionary<String, Any>)?["x"]
            let gY = (sensorsData["accelerometer"] as? Dictionary<String, Any>)?["y"]
            let gZ = (sensorsData["accelerometer"] as? Dictionary<String, Any>)?["z"]
            let xAcceleration = α("\(aX ?? "")") ?? 0.0
            let yAcceleration = α("\(aY ?? "")") ?? 0.0
            let zAcceleration = α("\(aZ ?? "")") ?? 0.0
            ThunderboardVector(x: xAcceleration, y: yAcceleration, z: zAcceleration)
            let xDegrees = Degree("\(gX ?? "")") ?? 0.0
            let yDegrees = Degree("\(gY ?? "")") ?? 0.0
            let zDegrees = Degree("\(gZ ?? "")") ?? 0.0
            ThunderboardInclination(x: xDegrees, y: yDegrees, z: zDegrees)
            self.uiUpdate(sensorsData: sensorsData)
        }
    }
}
