//
//  Data+Extensions.swift
//  Thunderboard
//
//  Created by Max Litteral on 8/3/17.
//  Copyright © 2017 Silicon Labs. All rights reserved.
//

import Foundation

extension Data {
    init(bytes: [UInt8]) {
        self = .init(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
    }
}
