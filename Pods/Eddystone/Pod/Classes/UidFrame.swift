//
//  UidFrame.swift
//  Pods
//
//  Created by Tanner Nelson on 8/24/15.
//
//

import UIKit

class UidFrame: Frame {
    
    var namespace: String
    var instance: String
    var uid: String {
        get {
            return namespace + instance
        }
    }
    
    init(namespace: String, instance: String) {
        self.namespace = namespace
        self.instance = instance
        
        super.init()
    }
   
    override class func frameWithBytes(_ bytes: [Byte]) -> UidFrame? {
        var namespace = ""
        var instance = ""
        
        for (offset, byte) in bytes.enumerated() {
            var hex = String(byte, radix: 16)
            if hex.characters.count == 1 {
                hex = "0" + hex
            }
            
            switch offset {
            case 2...11:
                namespace += hex
            case 12...17:
                instance += hex
            default:
                break
            }
            
        }
        
        if namespace.characters.count == 20 && instance.characters.count == 12 {
            return UidFrame(namespace: namespace, instance: instance)
        } else {
            log("Invalid UID frame")
        }

        return nil
    }
    
}
