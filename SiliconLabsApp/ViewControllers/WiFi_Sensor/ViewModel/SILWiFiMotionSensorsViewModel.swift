//
//  SILWiFiMotionSensorsViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 27/06/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
protocol SILWiFiMotionSensorsViewModelProtocol {
  // blueprint of a method
    func notifyMotionSensorsData(sensorsData: Dictionary<String, Any>?)
}

class SILWiFiMotionSensorsViewModel {
    
    var SILWiFiMotionSensorsViewModelDelegate: SILWiFiMotionSensorsViewModelProtocol?
    typealias completionBlockMotionSensors = (_ sensorsData: Dictionary<String, Any>?, _ APIClientError:Error?) -> Void
    var motionSensorsData = Dictionary<String, Any>()
    var gyroscope = Dictionary<String, Any>()
    var accelerometer = Dictionary<String, Any>()
    let APIRequestdispatchGroup = DispatchGroup()
    let concurrentQueue = DispatchQueue(label: "com.gcd.motionsensordispatchGroup", attributes: .concurrent)
    var countInt = 0
    
    func getGyroscopeData(completionBlockMotionSensors: @escaping completionBlockMotionSensors)  {
        APIRequest.sharedInstance.getApiCall(url: "gyroscope") { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                    print(json)
                    if let temperatureDic: Dictionary = json as? Dictionary<String, Any>{
                        completionBlockMotionSensors(temperatureDic, nil)
                    }
                } catch {
                    completionBlockMotionSensors(nil, APIClientError)
                    print(APIClientError)
                }
            }else{
                completionBlockMotionSensors(nil, APIClientError)
            }
        }
    }
    
    func getAccelerometerData(completionBlockMotionSensors: @escaping completionBlockMotionSensors)  {
        APIRequest.sharedInstance.getApiCall(url: "accelerometer") { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                    print(json)
                    if let temperatureDic: Dictionary = json as? Dictionary<String, Any>{
                        completionBlockMotionSensors(temperatureDic, nil)
                    }
                } catch {
                    completionBlockMotionSensors(nil, APIClientError)
                    print(APIClientError)
                }
            }else{
                completionBlockMotionSensors(nil, APIClientError)
            }
        }
    }
    
    func getMotionData()  {
            
        if countInt == 3 {
            countInt = 0
        }
        //APIRequestdispatchGroup.leave()

            concurrentQueue.async(group: APIRequestdispatchGroup) {
                self.APIRequestdispatchGroup.enter()
                self.getGyroscopeData { sensorsData, APIClientError in
                    if APIClientError == nil {
                        if let ledDic: Dictionary = sensorsData {
                            self.gyroscope = ledDic
                            self.APIRequestdispatchGroup.leave()
                        }else{
                            self.APIRequestdispatchGroup.leave()
                        }
                        
                    }else{
                        self.APIRequestdispatchGroup.leave()
                    }
                }
            }
            concurrentQueue.async(group: APIRequestdispatchGroup) {
                self.APIRequestdispatchGroup.enter()
                self.getAccelerometerData { sensorsData, APIClientError in
                    if APIClientError == nil {
                        if let ledDic: Dictionary = sensorsData {
                            self.accelerometer = ledDic
                            self.APIRequestdispatchGroup.leave()
                        }else{
                            self.APIRequestdispatchGroup.leave()
                        }
                    }else{
                        self.APIRequestdispatchGroup.leave()
                    }
                }
            }

            APIRequestdispatchGroup.notify(queue: .main) {
                print("All functions completed notify")
                print("All API done: \(self.countInt)")
                print("gyroscope: \(self.gyroscope) ")
                print("accelerometer: \(self.accelerometer) ")
                  self.sendMotionData()
              }
            APIRequestdispatchGroup.wait()
            print("All functions completed wait")
        }
    
    func sendMotionData() {
        self.motionSensorsData = [:]
        self.motionSensorsData = ["gyroscope": gyroscope, "accelerometer": accelerometer]
        if self.motionSensorsData.count > 0 {
            SILWiFiMotionSensorsViewModelDelegate?.notifyMotionSensorsData(sensorsData: self.motionSensorsData)
        }
    }
}
