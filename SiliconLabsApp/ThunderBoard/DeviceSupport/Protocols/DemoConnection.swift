//
//  DemoConnection.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol DemoConnection: class {
    var device: Device { get set }
    var capabilities: Set<DeviceCapability> { get }
}