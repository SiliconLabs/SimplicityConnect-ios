//
//  SimulatedEnvironmentDemo.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

class SimulatedEnvironmentDemoConnection : EnvironmentDemoConnection {
    
    var device: Device
    weak var connectionDelegate: EnvironmentDemoConnectionDelegate?
    var updateTimer: WeakTimer?
    fileprivate var previous = EnvironmentData()
    
    fileprivate var co2Enabled = true
    fileprivate var vocEnabled = true
    fileprivate let screenshotData = false
    
    // MARK:
    
    init(device: SimulatedDevice) {
        self.device = device

        updateTimer = WeakTimer.scheduledTimer(1.0, repeats: true, action: { [weak self] () -> Void in
            self?.notifyLatestData()
        })
    }

    // MARK:

    fileprivate func notifyLatestData() {
        var data = EnvironmentData()
        
        capabilities.forEach({
            switch $0 {
            case .ambientLight:
                data.ambientLight = (previous.ambientLight ?? 10) + 10
                if screenshotData { data.ambientLight = 1624 }
            case .humidity:
                data.humidity = (previous.humidity ?? 26) + 1
                if screenshotData { data.humidity = 43 }
            case .uvIndex:
                data.uvIndex = (previous.uvIndex ?? 1.2) + 0.05
                if screenshotData { data.uvIndex = 0 }
            case .temperature:
                data.temperature = (previous.temperature ?? 0) + 0.3
                if screenshotData { data.temperature = 25 }
            case .airQualityVOC:
                data.voc = VolatileOrganicCompoundsReading(enabled: vocEnabled, value: AirQualityVOC((previous.voc?.value ?? 100) + 5))
                if screenshotData { data.voc = VolatileOrganicCompoundsReading(enabled: true, value: 0) }
            case .airQualityCO2:
                data.co2 = CarbonDioxideReading(enabled: co2Enabled, value: AirQualityCO2((previous.co2?.value ?? 0) + 10))
                if screenshotData { data.co2 = CarbonDioxideReading(enabled: true, value: 400) }
            case .airPressure:
                data.pressure = (previous.pressure ?? 980) + 1
                if screenshotData { data.pressure = 955 }
            case .soundLevel:
                data.sound = (previous.sound ?? 0) + 3
                if screenshotData { data.sound = 51 }
            case .hallEffectState:
                data.hallEffectState = HallEffectState(rawValue: ((previous.hallEffectState?.rawValue ?? 0) + 1) % 3)
                if screenshotData { data.hallEffectState = .closed }
            case .hallEffectFieldStrength:
                data.hallEffectFieldStrength = (previous.hallEffectFieldStrength ?? 1000) + 100
                if screenshotData { data.hallEffectFieldStrength = 539 }
            default:
                break
            }
        })
        
        self.connectionDelegate?.updatedEnvironmentData(data)
        previous = data
    }

    func resetTamper() { /* TODO: Add way to simulate tampering and reset it here */ }
}
