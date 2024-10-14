//
//  SILWiFiLEDViewController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 27/06/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

class SILWiFiLEDViewController: UIViewController {
    @IBOutlet weak var blubImg: UIImageView!
    @IBOutlet weak var redColorBtn: UIButton!
    @IBOutlet weak var greenColorBtn: UIButton!
    @IBOutlet weak var blueColorBtn: UIButton!
    @IBOutlet weak var onBtn: UIButton!
    @IBOutlet weak var offBtn: UIButton!



    var silWiFiLedSensorsViewModelObject:SILWiFiLedSensorsViewModel = SILWiFiLedSensorsViewModel()
    var redColor: Bool = false
    var greenColor: Bool = false
    var blueColor: Bool = false
    var redColorVlue: String = "on"
    var greenColorVlue: String = "on"
    var blueColorVlue: String = "on"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //blubImg.image = LedImage.ledOnImage
        self.onBtn.backgroundColor = UIColor(named: "sil_boulderColor")
        self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
        
        //Comented: After BLE commissioning led status not to be check.
       // ledStatus()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        redColorVlue = "on"
        greenColorVlue = "on"
        blueColorVlue = "on"
        SVProgressHUD.show(withStatus: "Connecting")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            getLedStatus()
        }
    }
    func ledStatus(){
        //{"status_led": "on/off"}
        self.silWiFiLedSensorsViewModelObject.statusLed(requestMethod: HttpMethods.GET.rawValue) { [self] sensorsData, APIClientError in
            if APIClientError == nil{
                if let statusValue: String = sensorsData?["status_led"] as? String{
                    print(statusValue)
                    if statusValue == "on" {
                        postLedStatus()
                    }
                }
            }
        }
    }
    func postLedStatus(){
        self.silWiFiLedSensorsViewModelObject.statusLed(requestMethod: HttpMethods.POST.rawValue) { sensorsData, APIClientError in
            if APIClientError == nil{
                print(sensorsData)
            }
        }
    }

    func getLedStatus() {
        silWiFiLedSensorsViewModelObject.getLedData { sensorsData, APIClientError in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
            }
            if APIClientError == nil{
                
                if let ledDic: Dictionary = sensorsData {
                    self.stateOfLed(ledDic: ledDic)
                }
            }
        }
    }
    func stateOfLed(ledDic: Dictionary<String, Any> ){
        self.redColorVlue = "\(ledDic["red"] ?? "")"
        self.greenColorVlue = "\(ledDic["green"] ?? "")"
        self.blueColorVlue = "\(ledDic["blue"] ?? "")"
        if "\(ledDic["red"] ?? "")" == LedStatus.ledOnState.rawValue && "\(ledDic["green"] ?? "")" == LedStatus.ledOnState.rawValue && "\(ledDic["blue"] ?? "")" == LedStatus.ledOnState.rawValue{
            self.setLedStatus(type: LedType.ledOn.rawValue)
        }else if "\(ledDic["red"] ?? "")" == LedStatus.ledOffState.rawValue && "\(ledDic["green"] ?? "")" == LedStatus.ledOffState.rawValue && "\(ledDic["blue"] ?? "")" == LedStatus.ledOffState.rawValue {
            self.setLedStatus(type: LedType.ledOff.rawValue)
        }else if "\(ledDic["red"] ?? "")" == LedStatus.ledOnState.rawValue && "\(ledDic["green"] ?? "")" == LedStatus.ledOffState.rawValue && "\(ledDic["blue"] ?? "")" == LedStatus.ledOffState.rawValue {
            self.setLedStatus(type: LedType.redOn.rawValue)
        }else if "\(ledDic["red"] ?? "")" == LedStatus.ledOffState.rawValue && "\(ledDic["green"] ?? "")" == LedStatus.ledOnState.rawValue && "\(ledDic["blue"] ?? "")" == LedStatus.ledOffState.rawValue {
            self.setLedStatus(type: LedType.greenOn.rawValue)
        }else if "\(ledDic["red"] ?? "")" == LedStatus.ledOffState.rawValue && "\(ledDic["green"] ?? "")" == LedStatus.ledOffState.rawValue && "\(ledDic["blue"] ?? "")" == LedStatus.ledOnState.rawValue {
            self.setLedStatus(type: LedType.blueOn.rawValue)
        }else if "\(ledDic["red"] ?? "")" == LedStatus.ledOnState.rawValue && "\(ledDic["green"] ?? "")" == LedStatus.ledOnState.rawValue && "\(ledDic["blue"] ?? "")" == LedStatus.ledOffState.rawValue {
            self.setLedStatus(type: LedType.redGreenOn.rawValue)
        }else if "\(ledDic["red"] ?? "")" == LedStatus.ledOnState.rawValue && "\(ledDic["green"] ?? "")" == LedStatus.ledOffState.rawValue && "\(ledDic["blue"] ?? "")" == LedStatus.ledOnState.rawValue {
            self.setLedStatus(type: LedType.redBlueOn.rawValue)
        }else if "\(ledDic["red"] ?? "")" == LedStatus.ledOffState.rawValue && "\(ledDic["green"] ?? "")" == LedStatus.ledOnState.rawValue && "\(ledDic["blue"] ?? "")" == LedStatus.ledOnState.rawValue {
            self.setLedStatus(type: LedType.greenBuleOn.rawValue)
        }
    }
    
    func setLedStatus(type: String){
        var ledImage = UIImage()
        var ledColor = UIColor()
        
        switch type {
        case LedType.ledOn.rawValue:
            ledImage = LedImage.ledOnImage ?? UIImage()
            DispatchQueue.main.async {
                //self.redColorCheckImg.image = LedImage.checkBoxActiveImage
                self.redColorBtn.backgroundColor = UIColor(named: "sil_siliconLabsRedColor")
                self.redColor = true
                //self.greenColorCheckImg.image = LedImage.checkBoxActiveImage
                self.greenColorBtn.backgroundColor = UIColor(named: "sil_regularGreenColor")
                self.greenColor = true
                //self.blueColorCheckImg.image = LedImage.checkBoxActiveImage
                self.blueColorBtn.backgroundColor = UIColor(named: "sil_regularBlueColor")
                self.blueColor = true
                self.onBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
                self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
            }
        case LedType.ledOff.rawValue:
            ledImage = LedImage.ledOffImage ?? UIImage()
            DispatchQueue.main.async {
                //self.redColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.redColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.redColor = false
                //self.greenColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.greenColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.greenColor = false
                //self.blueColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.blueColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.blueColor = false
                
                self.onBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.offBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
            }
        case LedType.redOn.rawValue:
            //ledImage = LedImage.redLedOnImage ?? UIImage()
            ledImage = LedImage.blubOffTint ?? UIImage()
            ledColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 1)
            DispatchQueue.main.async {
                //self.redColorCheckImg.image = LedImage.checkBoxActiveImage
                self.redColorBtn.backgroundColor = UIColor(named: "sil_siliconLabsRedColor")
                self.redColor = true
                //self.greenColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.greenColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.greenColor = false
                //self.blueColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.blueColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.blueColor = false
                self.onBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
                self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
            }
        case LedType.greenOn.rawValue:
            //ledImage = LedImage.greenLedOnImage ?? UIImage()
            ledImage = LedImage.blubOffTint ?? UIImage()
            ledColor = UIColor(red: 0.0, green: 255.0, blue: 0.0, alpha: 1)
            DispatchQueue.main.async {
                //self.greenColorCheckImg.image = LedImage.checkBoxActiveImage
                self.greenColorBtn.backgroundColor = UIColor(named: "sil_regularGreenColor")
                self.greenColor = true
                //self.redColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.redColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.redColor = false
                //self.blueColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.blueColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.blueColor = false
                self.onBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
                self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
            }
        case LedType.blueOn.rawValue:
            //ledImage = LedImage.blueLedOnImage ?? UIImage()
            ledImage = LedImage.blubOffTint ?? UIImage()
            ledColor = UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 1)
            DispatchQueue.main.async {
                //self.blueColorCheckImg.image = LedImage.checkBoxActiveImage
                self.blueColorBtn.backgroundColor = UIColor(named: "sil_regularBlueColor")
                self.blueColor = true
                //self.redColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.redColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.redColor = false
                //self.greenColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.greenColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.greenColor = false
                self.onBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
                self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
            }
        case LedType.redGreenOn.rawValue:
            //ledImage = LedImage.yellowLedImage ?? UIImage()
            ledImage = LedImage.blubOffTint ?? UIImage()
            ledColor = UIColor(red: 255.0, green: 255.0, blue: 0.0, alpha: 1)
            DispatchQueue.main.async {
                //self.redColorCheckImg.image = LedImage.checkBoxActiveImage
                self.redColorBtn.backgroundColor = UIColor(named: "sil_siliconLabsRedColor")
                self.redColor = true
                //self.greenColorCheckImg.image = LedImage.checkBoxActiveImage
                self.greenColorBtn.backgroundColor = UIColor(named: "sil_regularGreenColor")
                self.greenColor = true
                //self.blueColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.blueColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.blueColor = false
                self.onBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
                self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
            }
        case LedType.redBlueOn.rawValue:
            //ledImage = LedImage.magentaLedImage ?? UIImage()
            ledImage = LedImage.blubOffTint ?? UIImage()
            ledColor = UIColor(red: 255.0, green: 0.0, blue: 255.0, alpha: 1)
            DispatchQueue.main.async {
                //self.redColorCheckImg.image = LedImage.checkBoxActiveImage
                self.redColorBtn.backgroundColor = UIColor(named: "sil_siliconLabsRedColor")
                self.redColor = true
                //self.blueColorCheckImg.image = LedImage.checkBoxActiveImage
                self.blueColorBtn.backgroundColor = UIColor(named: "sil_regularBlueColor")
                self.blueColor = true
                //self.greenColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.greenColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.greenColor = false
                self.onBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
                self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
            }
        case LedType.greenBuleOn.rawValue:
            //ledImage = LedImage.cyanLedImage ?? UIImage()
            ledImage = LedImage.blubOffTint ?? UIImage()
            ledColor = UIColor(red: 0.0, green: 255.0, blue: 255.0, alpha: 1)
            DispatchQueue.main.async {
                //self.greenColorCheckImg.image = LedImage.checkBoxActiveImage
                self.greenColorBtn.backgroundColor = UIColor(named: "sil_regularGreenColor")
                self.greenColor = true
                //self.blueColorCheckImg.image = LedImage.checkBoxActiveImage
                self.blueColorBtn.backgroundColor = UIColor(named: "sil_regularBlueColor")
                self.blueColor = true
                //self.redColorCheckImg.image = LedImage.checkBoxInactiveImage
                self.redColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                self.redColor = false
                self.onBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
                self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
            }
        default:
            print("Have you done something new?")
        }
        DispatchQueue.main.async {
            self.blubImg.image = ledImage
            if type != LedType.ledOn.rawValue && type != LedType.ledOff.rawValue {
                self.blubImg.tintColor = ledColor
            }
        }
    }
    @IBAction func Led_On(_ sender: Any) {
        redColorVlue = "on"
        greenColorVlue = "on"
        blueColorVlue = "on"
        self.onBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
        self.offBtn.backgroundColor = UIColor(named: "sil_boulderColor")
        ledControll()
    }
    
    func ledControll()  {
        let paramStr = """
                    {"red": "\(redColorVlue)", "green": "\(greenColorVlue)", "blue": "\(blueColorVlue)"}
                    """
        silWiFiLedSensorsViewModelObject.ledOnOf(ledType: LedType.ledOn.rawValue, parameter: paramStr, urlEndpoint: "led") { sensorsData, APIClientError in
            if APIClientError == nil{
                if let ledDic: Dictionary = sensorsData {
                    print(ledDic)
//                    self.redColorVlue = "\(ledDic["red"] ?? "")"
//                    self.greenColorVlue = "\(ledDic["green"] ?? "")"
//                    self.blueColorVlue = "\(ledDic["blue"] ?? "")"
//                    self.setLedStatus(type: LedType.ledOn.rawValue)
                    self.stateOfLed(ledDic: ledDic)
                }else{
                    
                }
            }
        }
    }
    
    @IBAction func Led_off(_ sender: Any) {
        redColorVlue = "off"
        greenColorVlue = "off"
        blueColorVlue = "off"
        self.onBtn.backgroundColor = UIColor(named: "sil_boulderColor")
        self.offBtn.backgroundColor = UIColor(named: "sil_primaryTextColor")
        ledControll()
//        silWiFiLedSensorsViewModelObject.ledOnOf(ledType: LedType.ledOff.rawValue, parameter: """
//                    {"red": "off", "green": "off", "blue": "off"}
//                    """, urlEndpoint: "led") { sensorsData, APIClientError in
//            if APIClientError == nil{
//                if let ledDic: Dictionary = sensorsData {
//                    print(ledDic)
////                    self.redColorVlue = "\(ledDic["red"] ?? "")"
////                    self.greenColorVlue = "\(ledDic["green"] ?? "")"
////                    self.blueColorVlue = "\(ledDic["blue"] ?? "")"
////                    self.setLedStatus(type: LedType.ledOff.rawValue)
//                    self.stateOfLed(ledDic: ledDic)
//                }
//            }
//        }
    }
    
    @IBAction func Led_Red(_ sender: Any) {
             silWiFiLedSensorsViewModelObject.ledOnOf(ledType: LedType.redOn.rawValue, parameter: """
                         {"red": "on", "green": "off", "blue": "off"}
                         """, urlEndpoint: "led") { sensorsData, APIClientError in
                 if APIClientError == nil{
                     if let ledDic: Dictionary = sensorsData {
                         print(ledDic)
                         self.redColorVlue = "\(ledDic["red"] ?? "")"
                         self.greenColorVlue = "\(ledDic["green"] ?? "")"
                         self.blueColorVlue = "\(ledDic["blue"] ?? "")"
                         self.setLedStatus(type: LedType.redOn.rawValue)
                     }
                 }
             }
    }
   

    @IBAction func Led_blue(_ sender: Any) {
        silWiFiLedSensorsViewModelObject.ledOnOf(ledType: LedType.blueOn.rawValue, parameter: """
                    {"red": "off", "green": "off", "blue": "on"}
                    """, urlEndpoint: "led") { sensorsData, APIClientError in
            if APIClientError == nil{
                if let ledDic: Dictionary = sensorsData {
                    print(ledDic)
                    self.redColorVlue = "\(ledDic["red"] ?? "")"
                    self.greenColorVlue = "\(ledDic["green"] ?? "")"
                    self.blueColorVlue = "\(ledDic["blue"] ?? "")"
                    self.setLedStatus(type: LedType.blueOn.rawValue)
                }
            }
        }
    }
    

    @IBAction func Led_Green(_ sender: Any) {
        silWiFiLedSensorsViewModelObject.ledOnOf(ledType: LedType.blueOn.rawValue, parameter: """
                    {"red": "off", "green": "on", "blue": "off"}
                    """, urlEndpoint: "led") { sensorsData, APIClientError in
            if APIClientError == nil{
                if let ledDic: Dictionary = sensorsData {
                    print(ledDic)
                    self.redColorVlue = "\(ledDic["red"] ?? "")"
                    self.greenColorVlue = "\(ledDic["green"] ?? "")"
                    self.blueColorVlue = "\(ledDic["blue"] ?? "")"
                    self.setLedStatus(type: LedType.greenOn.rawValue)
                }
            }
        }
    }
    
    @IBAction func colorCheckBtn(_ sender: UIButton) {
        if sender.tag == 1 {
            if redColor {
                //redColorCheckImg.image = LedImage.checkBoxInactiveImage
                //redColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                redColor = false
                redColorVlue = "off"
                if !greenColor {
                    greenColorVlue = "off"
                }
                if !blueColor {
                    blueColorVlue = "off"
                }
                
            }else{
                //redColorCheckImg.image = LedImage.checkBoxActiveImage
                //redColorBtn.backgroundColor = UIColor(named: "sil_siliconLabsRedColor")
                redColor = true
                redColorVlue = "on"
                if !greenColor {
                    greenColorVlue = "off"
                }
                if !blueColor {
                    blueColorVlue = "off"
                }
            }
        }else if sender.tag == 2{
            if greenColor {
                //greenColorCheckImg.image = LedImage.checkBoxInactiveImage
                //greenColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                greenColor = false
                greenColorVlue = "off"
                if !redColor {
                    redColorVlue = "off"
                }
                if !blueColor {
                    blueColorVlue = "off"
                }
                
            }else{
                //greenColorCheckImg.image = LedImage.checkBoxActiveImage
                //greenColorBtn.backgroundColor = UIColor(named: "sil_regularGreenColor")
                greenColor = true
                greenColorVlue = "on"
                if !redColor {
                    redColorVlue = "off"
                }
                if !blueColor {
                    blueColorVlue = "off"
                }
            }
        }else if sender.tag == 3{
            if blueColor {
                //blueColorCheckImg.image = LedImage.checkBoxInactiveImage
                //blueColorBtn.backgroundColor = UIColor(named: "sil_boulderColor")
                blueColor = false
                blueColorVlue = "off"
                if !redColor {
                    redColorVlue = "off"
                }
                if !greenColor {
                    greenColorVlue = "off"
                }
                
            }else{
                //blueColorCheckImg.image = LedImage.checkBoxActiveImage
                //blueColorBtn.backgroundColor = UIColor(named: "sil_regularBlueColor")
                blueColor = true
                blueColorVlue = "on"
                if !redColor {
                    redColorVlue = "off"
                }
                if !greenColor {
                    greenColorVlue = "off"
                }
            }
        }
        ledControll()
    }
    @IBAction func cancelBtn(_ sender: UIButton) {
        //sensorePopupView.isHidden = true
        self.dismiss(animated: false, completion: nil)
    }
    @IBAction func refreshBtn(_ sender: UIButton) {
        getLedStatus()
    }
}
