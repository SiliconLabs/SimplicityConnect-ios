//
//  SILRangeTestPeripheralManufacturerData.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 04.07.2018.
//  Copyright © 2018 SiliconLabs. All rights reserved.
//

import Foundation

class SILRangeTestManufacturerData: NSObject {
    let rawData: Data
    private(set) var companyIdentifier: UInt16? = nil
    private(set) var structureType: UInt8? = nil
    private(set) var rssi: Int8? = nil
    private(set) var packetsCounter: UInt16? = nil
    private(set) var packetsReceived: UInt16? = nil
    
    init(manufacturerData: Data) {
        self.rawData = manufacturerData
        
        super.init()
        
        parseManufacturerData()
    }
    
    private func parseManufacturerData() {
        var offset: UInt = 0
        
        self.companyIdentifier = getValue(withLength: 2, andOffset: &offset)
        self.structureType = getValue(withLength: 1, andOffset: &offset)
        self.rssi = getValue(withLength: 1, andOffset: &offset)
        self.packetsCounter = getValue(withLength: 2, andOffset: &offset)
        self.packetsReceived = getValue(withLength: 2, andOffset: &offset)
    }
    
    private func getValue<T>(withLength length: UInt, andOffset offset: inout UInt) -> T? {
        defer {
            offset += length
        }
        
        let data = getData(withLength: length, andOffset: offset)
        
        return convert(data: data)
    }
    
    private func getData(withLength length: UInt, andOffset offset: UInt) -> Data? {
        guard rawData.count >= offset + length else {
            return nil
        }
        
        return rawData.subdata(in: Int(offset)..<Int(offset + length))
    }
    
    private func convert<T>(data: Data?) -> T? {
        return data?.withUnsafeBytes({ (pointer: UnsafePointer<T>) -> T in
            return pointer.pointee
        })
    }
}
