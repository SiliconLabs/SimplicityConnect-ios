//
//  SILAdvertisingSet.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers
class SILAdvertisingSetEntity: Object {
    dynamic var uuid: String = UUID().uuidString
    dynamic var name: String = ""
    dynamic var createdAt: Date = Date()
    
    var isCompleteLocalName: Bool = false
    
    dynamic var _completeList16: String?
    var completeList16: [String]? {
        get {
            if let list = _completeList16 {
                return list.split(separator: ",").map({String($0)})
            } else {
                return nil
            }
        }
        set {
            _completeList16 = newValue?.joined(separator: ",")
        }
    }
    
    dynamic var _completeList128: String?
    var completeList128: [String]? {
        get {
            if let list = _completeList128 {
                return list.split(separator: ",").map({String($0)})
            } else {
                return nil
            }
        }
        set {
            _completeList128 = newValue?.joined(separator: ",")
        }
    }
    
    var isExecutionTime: Bool = false
    var executionTime: Int = 10
    
    override public static func primaryKey() -> String? {
        return "uuid"
    }
    
    func getCopy() -> SILAdvertisingSetEntity {
        let copiedAdvertiser = SILAdvertisingSetEntity()
        copiedAdvertiser.name = self.name
        copiedAdvertiser.isCompleteLocalName = self.isCompleteLocalName
        copiedAdvertiser.completeList16 = self.completeList16
        copiedAdvertiser.completeList128 = self.completeList128
        copiedAdvertiser.isExecutionTime = self.isExecutionTime
        copiedAdvertiser.executionTime = self.executionTime
        return copiedAdvertiser
    }
}
