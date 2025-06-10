//
//  SILWiFiProvisionViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 29/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation

class SILWiFiProvisionViewModel {
    func connectAPI<T:Codable>(paramData: String, completionBlock: @escaping(_ responseData: T?, _ APIClientError:Error? ) -> Void){
        print(paramData)
        APIRequest.sharedInstance.postApiCall(parameterDictionary: paramData, url: "connect", demoType: .WiFiProvisioning) { ReponsData, APIClientError in
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
    
    func passwordIsEmpty(textFieldTemp: UITextField) -> Bool {
        if let textStr = textFieldTemp.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return textStr
        }
        return false
    }
}
