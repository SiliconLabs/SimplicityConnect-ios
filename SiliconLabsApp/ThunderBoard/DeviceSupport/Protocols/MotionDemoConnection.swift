//
//  MotionDemoConnection.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol MotionDemoConnection: DemoConnection {
    var connectionDelegate: MotionDemoConnectionDelegate? { get set }
    
    func startCalibration()
    func resetOrientation()
    func resetRevolutions()
    func readLedColor()
}

protocol MotionDemoConnectionDelegate: class {
    func demoDeviceDisconnected()

    func startedCalibration()
    func finishedCalbration()
    
    func startedOrientationReset()
    func finishedOrientationReset()
    
    func startedRevolutionsReset()
    func finishedRevolutionsReset()
    
    func orientationUpdated(_ inclination: ThunderboardInclination)
    func accelerationUpdated(_ vector: ThunderboardVector)
    func rotationUpdated(_ revolutions: UInt, elapsedTime: TimeInterval)
    func ledColorUpdated(_ on: Bool, color: LedRgb)
}

extension MotionDemoConnection {
    var capabilities: Set<DeviceCapability> {
        let environmentCapabilities: Set<DeviceCapability> = [
            .acceleration,
            .orientation,
            .calibration,
            .revolutions,
            .rgbOutput,
        ]
        
        return device.capabilities.intersection(environmentCapabilities)
    }
}
