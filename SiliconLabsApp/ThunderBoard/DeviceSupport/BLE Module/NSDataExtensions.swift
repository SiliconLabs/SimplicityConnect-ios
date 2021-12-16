//
//  NSDataExtensions.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

extension Data {
    func tb_getByteAtIndex(_ index: Int) -> UInt8 {
        var byte: UInt8 = 0
        (subdata(in: index..<(index+1)) as NSData).getBytes(&byte, length: 1)
        return byte
    }
}
