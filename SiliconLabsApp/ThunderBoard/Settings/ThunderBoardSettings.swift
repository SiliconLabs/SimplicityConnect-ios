//
//  ThunderboardSettings.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ThunderboardSettings: NSObject {

    fileprivate let defaults = UserDefaults.standard

    override init() {
        super.init()
        registerDefaults()
    }
    
    //MARK: Measurement Units
    fileprivate let measurementKey = "measurementUnits"
    var measurement: MeasurementUnits {
        get {
            return MeasurementUnits(rawValue: defaults.integer(forKey: measurementKey))!
        }
        set (newValue) {
            defaults.set(newValue.rawValue, forKey: measurementKey)
        }
    }
    
    //MARK: Temperature Units
    fileprivate let temperatureKey = "temperatureUnits"
    var temperature: TemperatureUnits {
        get {
            return TemperatureUnits(rawValue: defaults.integer(forKey: temperatureKey))!
        }
        set (newValue) {
            defaults.set(newValue.rawValue, forKey: temperatureKey)
        }
    }
    
    //MARK: Motion Demo
    fileprivate let motionDemoModelKey = "motionDemoModel"
    var motionDemoModel: MotionDemoModel {
        get {
            return MotionDemoModel(rawValue: defaults.integer(forKey: motionDemoModelKey))!
        }
        set (newValue) {
            defaults.set(newValue.rawValue, forKey: motionDemoModelKey)
        }
    }
    
    
    //MARK: - Internal
    fileprivate func registerDefaults() {
        
        let defaultValues = [
            self.measurementKey     : MeasurementUnits.imperial.rawValue,
            self.temperatureKey     : TemperatureUnits.fahrenheit.rawValue,
            self.motionDemoModelKey : MotionDemoModel.board.rawValue,
        ] as [String : Any]
        
        self.defaults.register(defaults: defaultValues as [String : AnyObject])
    }
    
    fileprivate func identityOrNilForEmpty(_ value: String?) -> String? {
        if value?.count > 1 {
            return value
        }
        
        return nil
    }
}
