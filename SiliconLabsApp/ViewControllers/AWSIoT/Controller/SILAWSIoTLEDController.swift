//
//  SILAWSIoTLEDController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 20/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit
import AWSIoT
protocol SILAWSIoTLEDControllerProtocol {
  // blueprint of a method
    func notifyAWSIoTPublishViewClose(isClose: Bool)
}
class SILAWSIoTLEDController: UIViewController {
    @IBOutlet weak var blubImg: UIImageView!
    @IBOutlet weak var redColorBtn: UIButton!
    @IBOutlet weak var greenColorBtn: UIButton!
    @IBOutlet weak var blueColorBtn: UIButton!

    var SILAWSIoTLEDControllerDelegate: SILAWSIoTLEDControllerProtocol?

    
    var redColor: Bool = false
    var greenColor: Bool = false
    var blueColor: Bool = false
    var redColorVlue: String = "on"
    var greenColorVlue: String = "on"
    var blueColorVlue: String = "on"
    
    var ledIntialData: [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        redColorVlue = "on"
        greenColorVlue = "on"
        blueColorVlue = "on"
    }
    
    
    @IBAction func colorCheckBtn(_ sender: UIButton) {
        if sender.tag == 1 {
            
            if redColor {
                redColor = false
                redColorVlue = "off"
                greenColorVlue = "off"
                blueColorVlue = "off"
                greenColor = false
                blueColor = false
                setLedStatus(type: LedType.ledOff.rawValue)
            }else{
                redColor = true
                redColorVlue = "on"
                greenColorVlue = "off"
                blueColorVlue = "off"
                greenColor = false
                blueColor = false
                setLedStatus(type: LedType.redOn.rawValue)
            }

        }else if sender.tag == 2{
            if greenColor {
                greenColor = false
                greenColorVlue = "off"
                redColorVlue = "off"
                blueColorVlue = "off"
                redColor = false
                blueColor = false
                setLedStatus(type: LedType.ledOff.rawValue)
            }else{
                greenColor = true
                greenColorVlue = "on"
                redColorVlue = "off"
                blueColorVlue = "off"
                redColor = false
                blueColor = false
                setLedStatus(type: LedType.greenOn.rawValue)
            }

        }else if sender.tag == 3{
            if blueColor {
                blueColor = false
                blueColorVlue = "off"
                redColorVlue = "off"
                greenColorVlue = "off"
                redColor = false
                greenColor = false
                setLedStatus(type: LedType.ledOff.rawValue)
            }else{
                blueColor = true
                blueColorVlue = "on"
                redColorVlue = "off"
                greenColorVlue = "off"
                redColor = false
                greenColor = false
                setLedStatus(type: LedType.blueOn.rawValue)
            }
        }
        ledControll()
    }
    @IBAction func cancelBtn(_ sender: UIButton) {
        //sensorePopupView.isHidden = true
        SILAWSIoTLEDControllerDelegate?.notifyAWSIoTPublishViewClose(isClose: true)
        self.dismiss(animated: false, completion: nil)
    }
    
    func setLedStatus(type: String){
        var ledImage = UIImage()
        var ledColor = UIColor()
        
        switch type {
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
    private func ledControll(){
        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
        //iotDataManager.publishString("\(sender.value)", onTopic:"aws_status", qoS:.messageDeliveryAttemptedAtMostOnce)
        
        //iotDataManager.publishString("{\("on"): 1, \("msg"): Please turn on the light}", onTopic: "aws_status", qoS: .messageDeliveryAttemptedAtMostOnce)
        
        //iotDataManager.publishString("red", onTopic: "aws_status", qoS: .messageDeliveryAttemptedAtMostOnce)
        
        
//        {
//          "red": "off",
//          "green": "off",
//          "blue": "off"
//        }
        
        
        //SARAVAN
        //aws_status
        
        //Silabs
        //aws_status_sagar
        
        let jsonObject = ["red": "\(redColorVlue)", "green": "\(greenColorVlue)", "blue": "\(blueColorVlue)"]
        
//        let valid = JSONSerialization.isValidJSONObject(jsonObject)
//        print(valid)
//        iotDataManager.publishString("\(jsonObject)", onTopic: "\(pubTopic.text!)", qoS: .messageDeliveryAttemptedAtMostOnce)

//        {
//          "red": "off",
//          "green": "off",
//          "blue": "off"
//        }
        do {
                let data1 =  try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
                let convertedString = String(data: data1, encoding: String.Encoding.utf8) // the data will be converted to the string
                print(convertedString ?? "defaultvalue")
            
//            let valid = JSONSerialization.isValidJSONObject(jsonObject)
//            print(valid)
            
            if let pubTopicStr = AWStopicUserDefault.string(forKey: publish_topic_name) {
               print(pubTopicStr)
                iotDataManager.publishString("\(convertedString ?? "defaultvalue")", onTopic: "\(pubTopicStr)", qoS: .messageDeliveryAttemptedAtMostOnce)
            }
            } catch let myJSONError {
                print(myJSONError)
            }

    }
}
