//
//  DeviceTransportDelegate.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

enum DeviceTransportState {
    case enabled
    case disabled
}

protocol DeviceTransportPowerDelegate: class {
    func transportPowerStateUpdated(_ state: DeviceTransportState)
}
