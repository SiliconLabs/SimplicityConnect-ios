//
//  SILAWSIoTSubscribeViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 19/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation
import AWSIoT
protocol SILAWSIoTSubscribeViewModelProtocol {
  // blueprint of a method
    func notifyAWSIoTSubscribeData(subscribeData: [Any])
}

class SILAWSIoTSubscribeViewModel {
    var SILAWSIoTSubscribeViewModelDelegate: SILAWSIoTSubscribeViewModelProtocol?
    var sensorsData: [Any] = []

    init(SILAWSIoTSubscribeViewModelDelegate: SILAWSIoTSubscribeViewModelProtocol? = nil, sensorsData: [Any]) {
        self.SILAWSIoTSubscribeViewModelDelegate = SILAWSIoTSubscribeViewModelDelegate
        self.sensorsData = sensorsData
    }
    func subscribeOverTopic(topicId: String){
        getAWSIoTSubscribeData(topicId: topicId) { (ReponsData: AWSIoTSubscribeModel?, APIClientError) in
            //print(ReponsData)
            if let responseData = ReponsData{
                self.refromArray(allData: responseData)
            }else{
                self.SILAWSIoTSubscribeViewModelDelegate?.notifyAWSIoTSubscribeData(subscribeData: [])
            }
           
        }
    }
    
    private func getAWSIoTSubscribeData<T:Codable>(topicId: String, completionBlockSensor: @escaping (_ ReponsData: T?, _ APIClientError:Error?) -> Void)  {
        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
//SOVAN
        //siwx91x_status
        //SARAVAN
        //si91x_status
        //Silabs
        //si91x_status_sagar
        iotDataManager.subscribe(toTopic: topicId, qoS: .messageDeliveryAttemptedAtMostOnce, messageCallback: {
            (payload) ->Void in
           // print(payload)
            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)!

            //print("received: \(stringValue)")
            
            do {
//                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
//                    print(json)
//                    let string = String(data: ReponsData ?? Data(), encoding: .utf8)!
//                    print(string)
                let decodaData = try JSONDecoder().decode(T.self, from: payload)
                //print(decodaData)
                completionBlockSensor(decodaData, nil)

            } catch {
                //print(APIClientError)
                completionBlockSensor(nil, nil)
            }
//            DispatchQueue.main.async {
//                //self.subValueTextView.text = "\(stringValue)"
//            }
        } )
    }
    
    private func refromArray(allData: AWSIoTSubscribeModel){
         sensorsData = []
         for val in SensorType.allSensors{
             var valOfSensor = ""
             var tempDic = Dictionary<String, Any>()
             switch val {
             case SensorType.temp.rawValue:
                 //tempDic = ["title": "\(val)", "value": allData.temperature]
                 
                 let tempValue = getTemperatureValue(sensoreAllData: allData)
                 tempDic = ["title": "\(val)", "value": tempValue]
                 
             case SensorType.humudity.rawValue:
                 //tempDic = ["title": "\(val)", "value": allData.humidity]
                 
                 let humidityVal = getHumudityValue(sensoreAllData: allData)
                 tempDic = ["title": "\(val)", "value": humidityVal]
                 
             case SensorType.ambient.rawValue:
                 
                 //tempDic = ["title": "\(val)", "value": ["ambient_light_lux": allData.ambientLight, "white_light_lux": allData.whiteLight]]
                 
                 let ambientLightVal = getLightValue(sensoreAllData: allData).ambientLight
                 let whiteLightVal = getLightValue(sensoreAllData: allData).whiteLight
                 tempDic = ["title": "\(val)", "value": ["ambient_light_lux": ambientLightVal, "white_light_lux": whiteLightVal]]

             case SensorType.whiteLight.rawValue:
 
//                 tempDic = ["title": "\(val)", "value": ["ambient_light_lux": allData.ambientLight, "white_light_lux": allData.whiteLight]]
                 
                 let ambientLightVal = getLightValue(sensoreAllData: allData).ambientLight
                 let whiteLightVal = getLightValue(sensoreAllData: allData).whiteLight
                 tempDic = ["title": "\(val)", "value": ["ambient_light_lux": ambientLightVal, "white_light_lux": whiteLightVal]]
                 
             case SensorType.motion.rawValue:
                 
                 let motionDic = getAccelerometerGyroValue(sensoreAllData: allData)
                 tempDic = ["title": "\(val)", "value": motionDic]
                 
//                 let gyroscopeDic = ["x": allData.gyro.x, "y": allData.gyro.y, "z": allData.gyro.z]
//                 let accelerometerDic = ["x": allData.accelerometer.x, "y": allData.accelerometer.y, "z": allData.accelerometer.z]
//                 let motionDic = ["gyroscope": gyroscopeDic, "accelerometer": accelerometerDic]
//                 tempDic = ["title": "\(val)", "value": motionDic]
             case SensorType.led.rawValue:
                 //let ledDic = ["red": allData.led.red, "green": allData.led.green, "blue": allData.led.blue]
                 let ledDic = ["red": "off", "green": "off", "blue": "off"]
                 tempDic = ["title": "\(val)", "value": ledDic]
                 print("")
                 
             default:
                 print("Have you done something new?")
             }
             sensorsData.append(tempDic)
         }
         
         if sensorsData.count > 0 {
             //print(sensorsData)
             SILAWSIoTSubscribeViewModelDelegate?.notifyAWSIoTSubscribeData(subscribeData: sensorsData)
         }else{
             SILAWSIoTSubscribeViewModelDelegate?.notifyAWSIoTSubscribeData(subscribeData: sensorsData)
         }
     }
    func createCollectionArray() -> [Any]{
        var sensorDataTemp: [Any] = []
        for val in SensorType.allSensors{
            var valOfSensor = ""
            var tempDic = Dictionary<String, Any>()
            switch val {
            case SensorType.temp.rawValue:
                tempDic = ["title": "\(val)", "value": "0.0"]
            case SensorType.humudity.rawValue:
                tempDic = ["title": "\(val)", "value": "0.0"]
            case SensorType.ambient.rawValue:
                tempDic = ["title": "\(val)", "value": ["ambient_light_lux": "0.0", "white_light_lux": "0.0"]]
            case SensorType.whiteLight.rawValue:
                tempDic = ["title": "\(val)", "value": ["ambient_light_lux": "0.0", "white_light_lux": "0.0"]]
            case SensorType.motion.rawValue:
                let gyroscopeDic = ["x": "", "y": "", "z": ""]
                let accelerometerDic = ["x": "", "y": "", "z": ""]
                let motionDic = ["gyroscope": gyroscopeDic, "accelerometer": accelerometerDic]
                tempDic = ["title": "\(val)", "value": motionDic]
            case SensorType.led.rawValue:
                //let ledDic = ["red": allData.led.red, "green": allData.led.green, "blue": allData.led.blue]
                let ledDic = ["red": "off", "green": "off", "blue": "off"]
                tempDic = ["title": "\(val)", "value": ledDic]
                print("")
                
            default:
                print("Have you done something new?")
            }
            sensorDataTemp.append(tempDic)
        }
        
        return sensorDataTemp
    }
    
    private func getTemperatureValue(sensoreAllData: AWSIoTSubscribeModel) -> String {
        var tempVal = ""
        switch sensoreAllData.temperature {
          case .intValue(let intV):
            tempVal = "\(intV)"
          case .doubleValue(let doubleV):
            tempVal = "\(doubleV)"
          case .stringValue(let stringV):
            tempVal = stringV
          }
        return tempVal
    }
    
    private func getHumudityValue(sensoreAllData: AWSIoTSubscribeModel) -> String {
        var humudityVal = ""
        switch sensoreAllData.humidity {
        case .intValue(let intV):
            humudityVal = "\(intV)"
        case .doubleValue(let doubleV):
            humudityVal = "\(doubleV)"
        case .stringValue(let stringV):
            humudityVal = stringV
        }
        return humudityVal
    }
    
    private func getLightValue(sensoreAllData: AWSIoTSubscribeModel) -> (ambientLight: String, whiteLight: String)
    {
        var ambientLightVal = ""
        var whiteLightVal = ""
        switch sensoreAllData.ambientLight {
          case .intValue(let intV):
            ambientLightVal = "\(intV)"
          case .doubleValue(let doubleV):
            ambientLightVal = "\(doubleV)"
          case .stringValue(let stringV):
            ambientLightVal = stringV
          }
       switch sensoreAllData.whiteLight {
         case .intValue(let intV):
           whiteLightVal = "\(intV)"
         case .doubleValue(let doubleV):
           whiteLightVal = "\(doubleV)"
         case .stringValue(let stringV):
           whiteLightVal = stringV
         }
        return (ambientLightVal, whiteLightVal)
    }
    
    private func getAccelerometerGyroValue(sensoreAllData: AWSIoTSubscribeModel) -> [String : Any]{
        var gyroXval = ""
        var gyroYval = ""
        var gyroZval = ""
        
        switch sensoreAllData.gyro.x {
          case .intValue(let intV):
            gyroXval = "\(intV)"
          case .doubleValue(let doubleV):
            gyroXval = "\(doubleV)"
          case .stringValue(let stringV):
            gyroXval = stringV
          }
       switch sensoreAllData.gyro.y {
         case .intValue(let intV):
           gyroYval = "\(intV)"
         case .doubleValue(let doubleV):
           gyroYval = "\(doubleV)"
         case .stringValue(let stringV):
           gyroYval = stringV
         }
        switch sensoreAllData.gyro.z {
          case .intValue(let intV):
            gyroZval = "\(intV)"
          case .doubleValue(let doubleV):
            gyroZval = "\(doubleV)"
          case .stringValue(let stringV):
            gyroZval = stringV
          }
        
        var accelerometerXval = ""
        var accelerometerYval = ""
        var accelerometerZval = ""
        
        switch sensoreAllData.accelerometer.x {
          case .intValue(let intV):
            accelerometerXval = "\(intV)"
          case .doubleValue(let doubleV):
            accelerometerXval = "\(doubleV)"
          case .stringValue(let stringV):
            accelerometerXval = stringV
          }
       switch sensoreAllData.accelerometer.y {
         case .intValue(let intV):
           accelerometerYval = "\(intV)"
         case .doubleValue(let doubleV):
           accelerometerYval = "\(doubleV)"
         case .stringValue(let stringV):
           accelerometerYval = stringV
         }
        switch sensoreAllData.accelerometer.z {
          case .intValue(let intV):
            accelerometerZval = "\(intV)"
          case .doubleValue(let doubleV):
            accelerometerZval = "\(doubleV)"
          case .stringValue(let stringV):
            accelerometerZval = stringV
          }
        let gyroscopeDic = ["x": gyroXval, "y": gyroYval, "z": gyroZval]
        let accelerometerDic = ["x": accelerometerXval, "y": accelerometerYval, "z": accelerometerZval]
        return ["gyroscope": gyroscopeDic, "accelerometer": accelerometerDic]
    }

}
