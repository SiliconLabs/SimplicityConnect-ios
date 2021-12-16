//
//  ThunderboardTypes.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

let ThunderboardBeaconId = UUID(uuidString: "CEF797DA-2E91-4EA4-A424-F45082AC0682")!

enum ThunderboardDemo: Int {
    case motion
    case environment
    case io
}
//
enum MotionDemoModel: Int {
    case board
    case car
}

typealias Degree      = Float
typealias Radian      = Float
typealias Meters      = Float
typealias Centimeters = Float
typealias Inches      = Float
typealias Feet        = Float

enum LedState {
    case digital(Bool, LedStaticColor)
    case rgb(Bool, LedRgb)
}

enum LedStaticColor {
    case red
    case green
    case blue
}

struct LedRgb {
    let red: Float
    let green: Float
    let blue: Float
}

extension LedState {
    func toggle() -> LedState {
        switch self {
        case .digital(let on, let color):
            return .digital(!on, color)
        case .rgb(let on, let color):
            return .rgb(!on, color)
        }
    }
    
    func off() -> LedState {
        switch self {
        case .digital(_ , let color):
            return .digital(false, color)
        case .rgb(_, let color):
            return .rgb(false, color)
        }
    }
    
    func setColor(_ color: LedRgb) -> LedState {
        switch self {
        case .digital:
            return self
        case .rgb(let on, _):
            return .rgb(on, color)
        }
    }
    
    func setColor(_ red: Float, green: Float, blue: Float) -> LedState {
        return setColor(LedRgb(red: red, green: green, blue: blue))
    }
    
    var on: Bool {
        switch self {
        case .digital(let on, _):
            return on
        case .rgb(let on, _):
            return on
        }
    }
}

extension Degree {
    func tb_toRadian() -> Radian {
        return self * .pi / 180.0
    }
    
    func tb_toString(_ maximumDecimalPlaces: Int, minimumDecimalPlaces: Int = 0) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minimumDecimalPlaces
        formatter.maximumFractionDigits = maximumDecimalPlaces
        return formatter.string(from: NSNumber(value: self as Float))
    }
}

extension Double {
    func tb_toString(_ precision: Int) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = precision
        return formatter.string(from: NSNumber(value: self as Double))
    }
}

extension Meters {
    func tb_toInches() -> Inches {
        return self * Float(39.3701)
    }
    func tb_toFeet() -> Feet {
        return self * Float(3.28084)
    }
}

struct ThunderboardInclination {
    let x, y, z: Degree
    
    init() {
        x = 0
        y = 0
        z = 0
    }
    
    init(x: Degree, y: Degree, z: Degree) {
        self.x = x;
        self.y = y;
        self.z = z;
    }
}

typealias α = Float

struct ThunderboardVector {
    let x, y, z: α
    
    init() {
        x = 0
        y = 0
        z = 0
    }
    
    init(x: α, y: α, z: α) {
        self.x = x;
        self.y = y;
        self.z = z;
    }

}

struct ThunderboardCSCMeasurement {
    let revolutionsSinceConnecting: UInt
    let secondsSinceConnecting:     TimeInterval
    
    init() {
        revolutionsSinceConnecting  = 0;
        secondsSinceConnecting = 0;
    }
    
    init(revolutions: UInt, seconds: TimeInterval) {
        revolutionsSinceConnecting  = revolutions
        secondsSinceConnecting      = seconds
    }
}

enum MeasurementUnits: Int {
    case metric
    case imperial
}

enum TemperatureUnits: Int {
    case celsius
    case fahrenheit
}

typealias Temperature = Double
typealias Humidity = Double
typealias Lux = Double
typealias UVIndex = Double
typealias AirQualityCO2 = Double
typealias AirQualityVOC = Double
typealias SoundLevel = Double
typealias AtmosphericPressure = Double
typealias MagneticFieldStrength = Double
    
extension Temperature {
    var tb_FahrenheitValue: Temperature {
        // T(°F) = T(°C) × 9/5 + 32
        get { return (self * (9/5)) + 32 }
    }

    func tb_roundToTenths() -> Temperature {
        var selfTimes10 = self * 10.0
        selfTimes10.round(.toNearestOrAwayFromZero)
        return selfTimes10 / 10.0
    }
}

struct EnvironmentData {
    var temperature: Temperature?
    var humidity: Humidity?
    var ambientLight: Lux?
    var uvIndex: UVIndex?
    var co2: CarbonDioxideReading?
    var voc: VolatileOrganicCompoundsReading?
    var sound: SoundLevel?
    var pressure: AtmosphericPressure?
    var hallEffectState: HallEffectState?
    var hallEffectFieldStrength: MagneticFieldStrength?
}

struct CarbonDioxideReading {
    let enabled: Bool
    let value: AirQualityCO2?
}

struct VolatileOrganicCompoundsReading {
    let enabled: Bool
    let value: AirQualityVOC?
}

enum HallEffectState: UInt8 {
    case closed = 0
    case open = 1
    case tamper = 2
}

struct ThunderboardWheel {
    var diameter:                               Meters
    var revolutionsSinceConnecting:             UInt           = 0
    var secondsSinceConnecting:                 TimeInterval = 0

    fileprivate let rotationTimeOut:                UInt           = 12
    fileprivate var previousSecondsSinceConnecting: TimeInterval = 0
    fileprivate var previousRevolutions:            UInt           = 0
    fileprivate let secondsPerMinute:               Float          = 60
    
    var distance: Meters {
        
        get {
            return Meters(Double(revolutionsSinceConnecting) * .pi * Double(diameter))
        }
    }
    
    var rpm: Float {
    
        get {
            if deltaSeconds() == 0 {
                return 0.0
            } else {
                return Float(Double(deltaRevolutions()) / deltaSeconds() * Double(secondsPerMinute))
            }
        }
    }

    var speedInMetersPerSecond: Float {
        
        get {
            if deltaSeconds() == 0 {
                return 0.0
            } else {
                let distance = Meters(deltaRevolutions()) * .pi * diameter
                let distancePerSecond = distance / Float(deltaSeconds())
                return distancePerSecond
            }
        }
    }
    
    init(diameter: Meters) {
        self.diameter = diameter
    }

    fileprivate var countOfRepeatedSameValues: UInt = 0
    
    mutating func updateRevolutions(_ cumulativeRevolutions: UInt, cumulativeSecondsSinceConnecting: TimeInterval) {
        if cumulativeRevolutions != revolutionsSinceConnecting {
            previousSecondsSinceConnecting = secondsSinceConnecting
            previousRevolutions            = revolutionsSinceConnecting
            revolutionsSinceConnecting     = cumulativeRevolutions
            secondsSinceConnecting         = cumulativeSecondsSinceConnecting
            countOfRepeatedSameValues      = 0
        } else {
            countOfRepeatedSameValues += 1
            if countOfRepeatedSameValues >= rotationTimeOut {
                previousSecondsSinceConnecting = secondsSinceConnecting
                previousRevolutions            = revolutionsSinceConnecting
            }
        }
    }
    
    mutating func reset() {
        revolutionsSinceConnecting     = 0
        secondsSinceConnecting         = 0
        previousRevolutions            = 0
        previousSecondsSinceConnecting = 0
    }
    
    fileprivate func deltaRevolutions() -> UInt {
        var delta: UInt = 0
        if revolutionsSinceConnecting > previousRevolutions {
            delta = revolutionsSinceConnecting - previousRevolutions
        }
        return delta
    }
    
    fileprivate func deltaSeconds() -> TimeInterval {
        return secondsSinceConnecting - previousSecondsSinceConnecting
    }
}
