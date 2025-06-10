//
//  SILWiFiLedSensorsViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 27/06/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation

class SILWiFiLedSensorsViewModel {
    
    typealias completionBlockSensors = (_ sensorsData: Dictionary<String, Any>?, _ APIClientError:Error?) -> Void

    
    func getLedData(completionBlockSensors: @escaping completionBlockSensors)  {
        APIRequest.sharedInstance.getApiCall(url: "led", demoType: .WiFiSensor) { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                    print(json)
                    if let ledDic: Dictionary = json as? Dictionary<String, Any>{
                        completionBlockSensors(ledDic, nil)
                    }
                } catch {
                    completionBlockSensors(nil, APIClientError)
                    print(APIClientError)
                }
            }else{
                completionBlockSensors(nil, APIClientError)
            }
        }
    }
    
    func ledOnOf(ledType: String, parameter: String, urlEndpoint: String, completionBlockSensors: @escaping completionBlockSensors){
        APIRequest.sharedInstance.postApiCall(parameterDictionary: parameter, url: urlEndpoint, demoType: .WiFiSensor) { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                    print(json)
                    if let ledDic: Dictionary = json as? Dictionary<String, Any>{
                        completionBlockSensors(ledDic, nil)
                    }
                } catch {
                    completionBlockSensors(nil, APIClientError)
                    print(APIClientError)
                }
            }else{
                completionBlockSensors(nil, APIClientError)
            }
        }
    }
    func statusLed(requestMethod:String, completionBlockSensors: @escaping completionBlockSensors) {
        //{"status_led": "on/off"}
        if requestMethod == HttpMethods.POST.rawValue {
            let paramStr = """
                        {"status_led": "off"}
                        """
            APIRequest.sharedInstance.postApiCall(parameterDictionary: paramStr, url: "status_led", demoType: .WiFiSensor) { ReponsData, APIClientError in
                if APIClientError == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                        print(json)
                        if let statusLedDic: Dictionary = json as? Dictionary<String, Any>{
                            completionBlockSensors(statusLedDic, nil)
                        }
                    } catch {
                        completionBlockSensors(nil, APIClientError)
                        print(APIClientError)
                    }
                }else{
                    completionBlockSensors(nil, APIClientError)
                }
                
            }
        }else if requestMethod == HttpMethods.GET.rawValue {
            APIRequest.sharedInstance.getApiCall(url: "status_led", demoType: .WiFiSensor) { ReponsData, APIClientError in
                if APIClientError == nil {
                    do {
                        let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
                        print(json)
                        if let statusLedDic: Dictionary = json as? Dictionary<String, Any>{
                            completionBlockSensors(statusLedDic, nil)
                        }
                    } catch {
                        completionBlockSensors(nil, APIClientError)
                        print(APIClientError)
                    }
                }else{
                    completionBlockSensors(nil, APIClientError)
                }
            }
        }
        
    }

}
