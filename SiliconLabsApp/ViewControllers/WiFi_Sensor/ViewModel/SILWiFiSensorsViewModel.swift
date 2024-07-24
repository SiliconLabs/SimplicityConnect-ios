//
//  SILWiFiSensorsViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 26/06/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
import Network


protocol SILWiFiSensorsViewModelProtocol {
  // blueprint of a method
    func notifySensorsData(sensorsData: [Any])
}

class SILWiFiSensorsViewModel {
    //static let silwifiSensorsViewModelObject = SILWiFiSensorsViewModel()
    var SILWiFiSensorsViewModelDelegate: SILWiFiSensorsViewModelProtocol?
    var temperature = ""
    var humidity = ""
    var ambientLightLux = ""
    var whiteLightLux = ""
    var gyroscope = Dictionary<String, Any>()
    var accelerometer = Dictionary<String, Any>()
    var led = Dictionary<String, Any>()
    
    
    typealias completionBlockSensors = (_ sensorsData: [Any]?, _ APIClientError:Error?) -> Void
    typealias completionBlock = (_ sensorsData: Dictionary<String, Any>?, _ APIClientError:Error?) -> Void
    
    
    var sensorsData: [Any] = []
    let APIRequestdispatchGroup = DispatchGroup()
    let sensorConcurrentQueue = DispatchQueue(label: "com.gcd.sensordispatchGroup", attributes: .concurrent)
    var countInt = 0
    
        
    func getSensors() {
        sensorsData = []
        for val in SensorType.allSensors{
            var valOfSensor = ""
            var tempDic = Dictionary<String, Any>()
            switch val {
            case SensorType.temp.rawValue:
                tempDic = ["title": "\(val)", "value": temperature]
            case SensorType.humudity.rawValue:
                tempDic = ["title": "\(val)", "value": humidity]
            case SensorType.ambient.rawValue:
                //valOfSensor = "AL:\(ambientLightLux) WL:\(whiteLightLux)"
                //valOfSensor = "\(ambientLightLux) lx"
                tempDic = ["title": "\(val)", "value": ["ambient_light_lux": ambientLightLux, "white_light_lux": whiteLightLux]]
            case SensorType.motion.rawValue:
                let motionDic = ["gyroscope": gyroscope, "accelerometer": accelerometer]
                tempDic = ["title": "\(val)", "value": motionDic]
            case SensorType.led.rawValue:
                tempDic = ["title": "\(val)", "value": led]
                
            default:
                print("Have you done something new?")
            }
            //let tempDic = ["title": "\(val)", "value": valOfSensor]
            sensorsData.append(tempDic)
        }
        if sensorsData.count > 0 {
            print(sensorsData)
            SILWiFiSensorsViewModelDelegate?.notifySensorsData(sensorsData: sensorsData)
        }else{
            SILWiFiSensorsViewModelDelegate?.notifySensorsData(sensorsData: sensorsData)
        }
    }

    
    func getAllSensor()  {
        APIRequest.sharedInstance.getApiCall(url: "all_sensors") { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                    print(json)
//                    if let temperatureDic: Dictionary = json as? Dictionary<String, Any>{
//                        self.temperature = "\(temperatureDic["temperature_celcius"] ?? "")"
//                    }
                } catch {
                    print(APIClientError)
                }
            }else{
                print(APIClientError)
            }
        }
    }
    
    func getAllSensorData(){
        if self.countInt == 0 {
        sensorConcurrentQueue.async(group: APIRequestdispatchGroup) {
            self.APIRequestdispatchGroup.enter()
            APIRequest.sharedInstance.getApiCall(url: "temperature") { ReponsData, APIClientError in
                if APIClientError == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                        print(json)
                        if let temperatureDic: Dictionary = json as? Dictionary<String, Any>{
                            self.temperature = "\(temperatureDic["temperature_celcius"] ?? "")"
                        }
                        self.countInt += 1
                        self.APIRequestdispatchGroup.leave()
                    } catch {
                        self.APIRequestdispatchGroup.leave()
                        print(APIClientError)
                    }
                }else{
                    self.APIRequestdispatchGroup.leave()
                }
            }
            
        }
        sensorConcurrentQueue.async(group: APIRequestdispatchGroup) {
            self.APIRequestdispatchGroup.enter()
            APIRequest.sharedInstance.getApiCall(url: "humidity") { ReponsData, APIClientError in
                if APIClientError == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                        print(json)
                        if let humidityDic: Dictionary = json as? Dictionary<String, Any>{
                            self.humidity = "\(humidityDic["humidity_percentage"] ?? "")"
                        }
                        self.countInt += 1
                        self.APIRequestdispatchGroup.leave()
                    } catch {
                        self.APIRequestdispatchGroup.leave()
                        print(APIClientError)
                    }
                }else{
                    self.APIRequestdispatchGroup.leave()
                }
            }
        }
        
        sensorConcurrentQueue.async(group: APIRequestdispatchGroup) {
            self.APIRequestdispatchGroup.enter()
            APIRequest.sharedInstance.getApiCall(url: "light") { ReponsData, APIClientError in
                if APIClientError == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                        print(json)
                        if let lightDic: Dictionary = json as? Dictionary<String, Any>{
                            self.ambientLightLux = "\(lightDic["ambient_light_lux"] ?? "")"
                            self.whiteLightLux = "\(lightDic["white_light_lux"] ?? "")"
                        }
                        self.countInt += 1
                        self.APIRequestdispatchGroup.leave()
                    } catch {
                        self.APIRequestdispatchGroup.leave()
                        print(APIClientError)
                    }
                }else{
                    self.APIRequestdispatchGroup.leave()
                }
            }
            
        }
        
        sensorConcurrentQueue.async(group: APIRequestdispatchGroup) {
            self.APIRequestdispatchGroup.enter()
            APIRequest.sharedInstance.getApiCall(url: "led") { ReponsData, APIClientError in
                if APIClientError == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                        print(json)
                        if let ledDic: Dictionary = json as? Dictionary<String, Any>{
                            self.led = ledDic
                        }
                        self.countInt += 1
                        self.APIRequestdispatchGroup.leave()
                    } catch {
                        self.APIRequestdispatchGroup.leave()
                        print(APIClientError)
                    }
                }else{
                    self.APIRequestdispatchGroup.leave()
                }
            }
        }
        sensorConcurrentQueue.async(group: APIRequestdispatchGroup) {
            self.APIRequestdispatchGroup.enter()
            APIRequest.sharedInstance.getApiCall(url: "gyroscope") { ReponsData, APIClientError in
                if APIClientError == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                        print(json)
                        if let gyroscopeDic: Dictionary = json as? Dictionary<String, Any>{
                            self.gyroscope = gyroscopeDic
                        }
                        self.countInt += 1
                        self.APIRequestdispatchGroup.leave()
                    } catch {
                        self.APIRequestdispatchGroup.leave()
                        print(APIClientError)
                    }
                }else{
                    self.APIRequestdispatchGroup.leave()
                }
            }
        }
        sensorConcurrentQueue.async(group: APIRequestdispatchGroup) {
            self.APIRequestdispatchGroup.enter()
            APIRequest.sharedInstance.getApiCall(url: "accelerometer") { ReponsData, APIClientError in
                if APIClientError == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                        print(json)
                        if let accelerometerDic: Dictionary = json as? Dictionary<String, Any>{
                            self.accelerometer = accelerometerDic
                        }
                        self.countInt += 1
                        self.APIRequestdispatchGroup.leave()
                    } catch {
                        self.APIRequestdispatchGroup.leave()
                        print(APIClientError)
                    }
                }else{
                    self.APIRequestdispatchGroup.leave()
                }
            }
        }
    }
        
        APIRequestdispatchGroup.notify(queue: .main) {
            if self.countInt == 6 {
                self.countInt = 0
            }
            self.getSensors()
        }
        APIRequestdispatchGroup.wait()
        print("All functions completed wait")
    }
    func getTemperatureData(completionBlock: @escaping completionBlock)  {
        APIRequest.sharedInstance.getApiCall(url: "temperature") { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                    print(json)
                    if let temperatureDic: Dictionary = json as? Dictionary<String, Any>{
                        completionBlock(temperatureDic, nil)
                    }
                } catch {
                    completionBlock(nil, APIClientError)
                    print(APIClientError)
                }
            }else{
                completionBlock(nil, APIClientError)
            }
        }
    }
    func getHumidityData(completionBlock: @escaping completionBlock)  {
        APIRequest.sharedInstance.getApiCall(url: "humidity") { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                    print(json)
                    if let temperatureDic: Dictionary = json as? Dictionary<String, Any>{
                        completionBlock(temperatureDic, nil)
                    }
                } catch {
                    completionBlock(nil, APIClientError)
                    print(APIClientError)
                }
            }else{
                completionBlock(nil, APIClientError)
            }
        }
    }
    func getLightData(completionBlock: @escaping completionBlock)  {
        APIRequest.sharedInstance.getApiCall(url: "light") { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                    print(json)
                    if let temperatureDic: Dictionary = json as? Dictionary<String, Any>{
                        completionBlock(temperatureDic, nil)
                    }
                } catch {
                    completionBlock(nil, APIClientError)
                    print(APIClientError)
                }
            }else{
                completionBlock(nil, APIClientError)
            }
        }
        
    }
    
    func checkServerAvailability() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            let usesWiFi = path.usesInterfaceType(.wifi)
            let usesCellular = path.usesInterfaceType(.cellular)
            if path.status == .satisfied {
                print("Internet connection is available.")
                // Perform actions when internet is available
            } else {
                print("Internet connection is not available.")
                // Perform actions when internet is not available
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
    }
    
}
