//
//  TLMData.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 6/29/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import Foundation

final class TLMData: NSObject {
    var batteryVolts: Double
    var temperature: Double
    var advertisementCount: Int
    var onTime: TimeInterval

    init(batteryVolts: Double, temperature: Double, advertisementCount: Int, onTime: TimeInterval) {
        self.batteryVolts = batteryVolts
        self.temperature = temperature
        self.advertisementCount = advertisementCount
        self.onTime = onTime
    }
}
