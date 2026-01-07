//
//  SILSmartLockSubscribeViewModel.swift
//  BlueGecko
//
//  Created by Mantosh Kumar on 06/07/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation
import AWSIoT

protocol SILSmartLockSubscribeViewModelProtocol {
    func notifySmartLockSubscribeData(subscribeData: String?)
}

class SILSmartLockSubscribeViewModel {
    var SILSmartLockSubscribeViewModelDelegate: SILSmartLockSubscribeViewModelProtocol?
    
    init(SILSmartLockSubscribeViewModelDelegate: SILSmartLockSubscribeViewModelProtocol? = nil) {
        self.SILSmartLockSubscribeViewModelDelegate = SILSmartLockSubscribeViewModelDelegate
    }
    
    func subscribeOverTopic(topicId: String) {
        getSmartLockSubscribeData(topicId: topicId) { (responsData: String?, APIClientError) in
            self.SILSmartLockSubscribeViewModelDelegate?.notifySmartLockSubscribeData(subscribeData: responsData ?? nil)
        }
    }
    
    private func getSmartLockSubscribeData<T:Codable>(topicId: String, completionBlockSensor: @escaping (_ ReponsData: T?, _ APIClientError:Error?) -> Void)  {
        let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                      
        iotDataManager.subscribe(toTopic: topicId, qoS: .messageDeliveryAttemptedAtMostOnce, messageCallback: {
            (payload) ->Void in
            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)!
            print("received call back Subscribe: \(stringValue)")
            completionBlockSensor(stringValue as? T, nil)
        } )
    }
}
