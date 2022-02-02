//
//  DeviceExtensions.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

extension Device {
    func ledColor(_ index: Int) -> LedStaticColor {
        // There isn't a way to query the Thunderboard devices for their LED
        // colors, so this is table for known configurations.
        switch self.model {
        case .react:
            return [ LedStaticColor.blue, LedStaticColor.green ][index]
        case .sense:
            return [ LedStaticColor.red, LedStaticColor.green ][index]
        case .unknown, .bobcat:
            return .green
        }
    }
    
    func displayName() -> String {
        if let name = name {
            return name
        } else if let advertisedName = advertisementDataLocalName {
            return advertisedName
        } else {
            return "Unnamed"
        }
    }
}
