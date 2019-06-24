//
//  TlmFrame.swift
//  Pods
//
//  Created by Tanner Nelson on 8/24/15.
//
//

import UIKit

class TlmFrame: Frame {
    
    var batteryVolts: Int
    var temperature: Double
    var advertisementCount: Int
    var onTime: Int
    
    init(batteryVolts: Int, temperature: Double, advertisementCount: Int, onTime: Int) {
        self.batteryVolts = batteryVolts
        self.temperature = temperature
        self.advertisementCount = advertisementCount
        self.onTime = onTime
        
        super.init()
    }
    
    override class func frameWithBytes(_ bytes: [Byte]) -> TlmFrame? {
        var batteryVolts: Int?
        var temperature: Double?
        var advertisementCount: Int?
        var onTime: Int?
        
        if bytes.count <= 2 || bytes[1] != 0 {
            log("Invalid TLM version, only 0 is supported")
            return nil
        }
        
        if bytes.count >= 4 {
            let vbattBytes = [bytes[2], bytes[3]]
            batteryVolts = Int.fromByteArray(vbattBytes.map { byte in
                return UInt8(byte)
            })
        }
        
        if bytes.count >= 6 {
            temperature = Double.from88FixedPoint(UInt8(bytes[4]), UInt8(bytes[5]))
        }
        
        if bytes.count >= 10 {
            let advCountBytes = [bytes[6], bytes[7], bytes[8], bytes[9]]
            advertisementCount = Int.fromByteArray(advCountBytes.map { byte in
                return UInt8(byte)
            })
        }
        
        if bytes.count >= 14 {
            let onTimeBytes = [bytes[10], bytes[11], bytes[12], bytes[13]]
            onTime = Int.fromByteArray(onTimeBytes.map { byte in
                return UInt8(byte)
            })
        }
        
        if  let batteryVolts = batteryVolts,
            let temperature = temperature,
            let advertisementCount = advertisementCount,
            let onTime = onTime {
            return TlmFrame(batteryVolts: batteryVolts, temperature: temperature, advertisementCount: advertisementCount, onTime: onTime)
        } else {
            log("Invalid TLM frame")
        }
        
        return nil
    }
    
}
