//
//  SILWifiProvisioningAPViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 25/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILWifiProvisioningAPViewModelProtocol {
  // blueprint of a method
    func notifyAPData(APData: [ScanResult]?, apiResponseError:Error?)
}

class SILWifiProvisioningAPViewModel {
    typealias completionBlockSensors<T:Codable> = (_ getData: T?, _ APIClientError:Error?) -> Void

    var SILWifiProvisioningAPViewModelDelegate: SILWifiProvisioningAPViewModelProtocol?
    
    func getAPIForWifiProvision<T:Codable>(apiEndPoint: String, completionBlock: @escaping(_ getData: T?, _ APIClientError:Error? ) -> Void) {
        APIRequest.sharedInstance.getApiCall(url: apiEndPoint, demoType: .WiFiProvisioning) { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let decodaData = try JSONDecoder().decode(T.self, from: ReponsData ?? Data())
                    print(decodaData)
                    completionBlock(decodaData, APIClientError)
                } catch {
                    completionBlock(nil, APIClientError)
                }
            }else{
                completionBlock(nil, APIClientError)
            }
        }
    }
    
//    func scanAP(completionBlock: @escaping(_ scanedAP: SILAPDataList?, _ APIClientError:Error? ) -> Void) {
//        APIRequest.sharedInstance.getApiCall(url: "scan") { ReponsData, APIClientError in
//            if APIClientError == nil {
//                do {
//                    let json = try JSONSerialization.jsonObject(with: ReponsData ?? Data(), options: [])
//                    print(json)
//                    
//
//                } catch {
//                    print(APIClientError)
//                }
//                
//                do {
//                    let decodaData = try JSONDecoder().decode(SILAPDataList.self, from: ReponsData ?? Data())
//                    print(decodaData)
//                    completionBlock(decodaData, APIClientError)
//                } catch {
//                    completionBlock(nil, APIClientError)
//                }
//            }else{
//            }
//        }
//    }
    
    func postAPIForWifiProvision<T:Codable>(apiEndPoint: String, param: String, completionBlock: @escaping(_ scanedAP: T?, _ APIClientError:Error? ) -> Void) {
        APIRequest.sharedInstance.postApiCall(parameterDictionary: param, url: apiEndPoint, demoType: .WiFiProvisioning) { ReponsData, APIClientError in
            if APIClientError == nil {
                do {
                    let decodaData = try JSONDecoder().decode(T.self, from: ReponsData ?? Data())
                    print(decodaData)
                    completionBlock(decodaData, APIClientError)
                } catch {
                    completionBlock(nil, APIClientError)
                }
            }else{
                completionBlock(nil, APIClientError)
            }
        }
    }
    
    
    func apiCallForIntialLoad(){
        getAPIForWifiProvision(apiEndPoint: "status_led") { [self] (_ responseValue: SILStatusLED?, APIClientError) in
            if APIClientError == nil{
                if responseValue?.statusLED == "off" {
                    changeLEDStatus(ledState: "on")
                }else{
                    getScanData()
                }
            }else{
                SILWifiProvisioningAPViewModelDelegate?.notifyAPData(APData: nil, apiResponseError: APIClientError)
            }
        }

    }
    func changeLEDStatus(ledState: String){
        let paramStr = """
                    {"status_led": "\(ledState)"}
                    """
        postAPIForWifiProvision(apiEndPoint: "status_led", param: paramStr){ [self] (_ responseValue:SILStatusLED?, APIClientError ) in
            if APIClientError == nil{
                if responseValue?.statusLED == "on" {
                    getScanData()
                }else{
                    SILWifiProvisioningAPViewModelDelegate?.notifyAPData(APData: nil, apiResponseError: APIClientError)
                }
            }else{
                SILWifiProvisioningAPViewModelDelegate?.notifyAPData(APData: nil, apiResponseError: APIClientError)
            }
        }
    }
    func getScanData() {
        getAPIForWifiProvision(apiEndPoint: "scan") { [self] (_ responseValue: SILAPDataList?, APIClientError) in
            if APIClientError == nil {
                SILWifiProvisioningAPViewModelDelegate?.notifyAPData(APData: responseValue?.scanResults, apiResponseError: APIClientError)
            }else{
                SILWifiProvisioningAPViewModelDelegate?.notifyAPData(APData: nil, apiResponseError: APIClientError)
            }
        }
    }
}
