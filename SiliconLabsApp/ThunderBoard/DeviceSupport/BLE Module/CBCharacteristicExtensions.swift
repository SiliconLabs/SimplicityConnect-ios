//
//  CBCharacteristicExtensions.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import CoreBluetooth

extension CBCharacteristicProperties : CustomStringConvertible {
    public var description : String {
        let strings = [
            "Broadcast",
            "Read",
            "WriteWithoutResponse",
            "Write",
            "Notify",
            "Indicate",
            "AuthenticatedSignedWrites",
            "ExtendedProperties",
            "NotifyEncryptionRequired",
            "IndicateEncryptionRequired",
        ]
        
        var propertyDescriptions = [String]()
        for (index, string) in strings.enumerated() where contains(CBCharacteristicProperties(rawValue: UInt(1 << index))) {
            propertyDescriptions.append(string)
        }
        
        return propertyDescriptions.description
    }
}

extension CBCharacteristic {
    
    func tb_supportsNotificationOrIndication() -> Bool {
        let notification = self.properties.rawValue & CBCharacteristicProperties.notify.rawValue != 0
        let indication = self.properties.rawValue & CBCharacteristicProperties.indicate.rawValue != 0
        
        return notification || indication
    }
    
    func tb_supportsRead() -> Bool {
        return self.properties.rawValue & CBCharacteristicProperties.read.rawValue != 0
    }
    
    func tb_supportsWrite() -> Bool {
        return self.properties.rawValue & CBCharacteristicProperties.write.rawValue != 0
    }

    func tb_int8Value() -> Int8? {
        if let data = self.value {
            var byte: Int8 = 0
            (data as NSData).getBytes(&byte, length: 1)

            return byte
        }
        
        return nil
    }

    func tb_int32Value() -> Int32? {
        if let data = self.value {
            var value: Int32 = 0
            (data as NSData).getBytes(&value, length: 4)
            return value
        }

        return nil
    }
    
    func tb_uint8Value() -> UInt8? {
        if let data = self.value {
            var byte: UInt8 = 0
            (data as NSData).getBytes(&byte, length: 1)

            return byte
        }
        
        return nil
    }
    
    func tb_int16Value() -> Int16? {
        if let data = self.value {
            var value: Int16 = 0
            (data as NSData).getBytes(&value, length: 2)
            
            return value
        }
        
        return nil
    }
    
    func tb_uint16Value() -> UInt16? {
        if let data = self.value {
            var value: UInt16 = 0
            (data as NSData).getBytes(&value, length: 2)
            
            return value
        }
        
        return nil
    }
    
    func tb_uint32Value() -> UInt32? {
        if let data = self.value {
            var value: UInt32 = 0
            (data as NSData).getBytes(&value, length: 4)
            return value
        }
        
        return nil
    }
    
    func tb_uint64value() -> UInt64? {
        if let data = self.value {
            var value: UInt64 = 0
            (data as NSData).getBytes(&value, length: 8)
            return value
        }
        
        return nil
    }
    
    func tb_stringValue() -> String? {
        if let data = self.value {
            return String(data: data, encoding: String.Encoding.utf8)
        }
        
        return nil
    }
    
    func tb_hexStringValue() -> String? {
        guard let data = self.value else {
            return nil
        }
        
        let len = data.count
        let result = NSMutableString(capacity: len*2)
        var byteArray = [UInt8](repeating: 0x0, count: len)
        (data as NSData).getBytes(&byteArray, length:len)
        for (index, element) in byteArray.enumerated() {
            if index % 8 == 0 && index > 0 {
                result.appendFormat("\n")
            }
            result.appendFormat("%02x ", element)
        }
        
        return String(result)
    }
    
    func tb_hexDump() {
        if let hex = self.tb_hexStringValue() {
            log.debug("\(hex)")
        }
    }
    
    func tb_inclinationValue() -> ThunderboardInclination? {
        if let data = self.value {
            if data.count >= 6 {
                var xDegreesTimes100: Int16 = 0;
                var yDegreesTimes100: Int16 = 0;
                var zDegreesTimes100: Int16 = 0;
                (data as NSData).getBytes(&xDegreesTimes100, range: NSMakeRange(0, 2))
                (data as NSData).getBytes(&yDegreesTimes100, range: NSMakeRange(2, 2))
                (data as NSData).getBytes(&zDegreesTimes100, range: NSMakeRange(4, 2))
                let xDegrees = Degree(xDegreesTimes100) / 100.0;
                let yDegrees = Degree(yDegreesTimes100) / 100.0;
                let zDegrees = Degree(zDegreesTimes100) / 100.0;
                return ThunderboardInclination(x: xDegrees, y: yDegrees, z: zDegrees)
            }
        }
        
        return nil
    }
    
    func tb_vectorValue() -> ThunderboardVector? {
        if let data = self.value {
            if data.count >= 6 {
                var xAccelerationTimes1k: Int16 = 0;
                var yAccelerationTimes1k: Int16 = 0;
                var zAccelerationTimes1k: Int16 = 0;
                (data as NSData).getBytes(&xAccelerationTimes1k, range: NSMakeRange(0, 2))
                (data as NSData).getBytes(&yAccelerationTimes1k, range: NSMakeRange(2, 2))
                (data as NSData).getBytes(&zAccelerationTimes1k, range: NSMakeRange(4, 2))
                let xAcceleration = α(xAccelerationTimes1k) / 1000.0;
                let yAcceleration = α(yAccelerationTimes1k) / 1000.0;
                let zAcceleration = α(zAccelerationTimes1k) / 1000.0;
                return ThunderboardVector(x: xAcceleration, y: yAcceleration, z: zAcceleration)
            }
        }
        
        return nil
    }
    
    func tb_cscMeasurementValue() -> ThunderboardCSCMeasurement? {
        if let data = self.value {
            if data.count >= 7 {
                var revolutionsSinceConnecting:            UInt32 = 0
                var secondsSinceConnectingTimes1024:       UInt16 = 0
                (data as NSData).getBytes(&revolutionsSinceConnecting, range: NSMakeRange(1, 4))
                (data as NSData).getBytes(&secondsSinceConnectingTimes1024, range: NSMakeRange(5, 2))
                let secondsSinceConnecting: TimeInterval = Double(secondsSinceConnectingTimes1024) / 1024
                return ThunderboardCSCMeasurement(revolutions:UInt(revolutionsSinceConnecting), seconds:secondsSinceConnecting)
            }
        }
        
        return nil
    }
    
    func tb_analogLedState() -> LedState? {
        guard let data = self.value else {
            return nil
        }
        
        // 0x0F FF FF FF
        //    |  |  |  +- blue
        //    |  |  +---- green
        //    |  +------- red
        //    +---------- enabled
        if data.count != 4 {
            return nil
        }
        
        let enabled = data.tb_getByteAtIndex(0)
        let red = Float(data.tb_getByteAtIndex(1))
        let green = Float(data.tb_getByteAtIndex(2))
        let blue = Float(data.tb_getByteAtIndex(3))
        
        // note: for now, we're only supporting all-on for the LEDs
        let on = (enabled == 0) ? false : true
        return LedState.rgb(on, LedRgb(red: red/255, green: green/255, blue: blue/255))
    }
}
