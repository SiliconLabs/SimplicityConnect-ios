//
//  MotionDemoInteraction.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol MotionDemoInteractionOutput : class {
    func updateOrientation(_ orientation: ThunderboardInclination)
    func updateAcceleration(_ acceleration: ThunderboardVector)
    func updateWheel(_ diameter: Meters)
    func updateLocation(_ distance: Float, speed: Float, rpm: Float, totalRpm: UInt)
    func updateLedColor(_ on: Bool, color: LedRgb)
    func deviceCalibrating(_ isCalibrating: Bool)
    func displayInfoAbout(missingCapabilities: Set<DeviceCapability>)
}

class MotionDemoInteraction: MotionDemoConnectionDelegate {

    fileprivate weak var output: MotionDemoInteractionOutput?
    fileprivate var connection: MotionDemoConnection?
    
    fileprivate static let defaultWheelSize: Meters = 0.0301

    fileprivate var acceleration = ThunderboardVector()
    fileprivate var orientation = ThunderboardInclination()
    fileprivate var position = ThunderboardWheel(diameter: defaultWheelSize)
    fileprivate var calibrating = false
    
    fileprivate var calibrationComplete: (() -> Void)?
    fileprivate var resetOrientationComplete: (() -> Void)?
    fileprivate var resetRevolutionsComplete: (() -> Void)?
    fileprivate var calibrationTimer: Timer?
    
    //MARK: - Public
    
    init(output: MotionDemoInteractionOutput?, demoConnection: MotionDemoConnection) {
        self.output = output
        self.connection = demoConnection
        self.connection?.connectionDelegate = self
    }
    
    func checkMissingSensors() {
        guard let missingCapabilities = connection?.missingCapabilities else { return }
        
        if missingCapabilities.count > 0 {
            output?.displayInfoAbout(missingCapabilities: missingCapabilities)
        }
    }
    
    func updateView() {
        output?.deviceCalibrating(calibrating)
        
        orientationUpdated(orientation)
        accelerationUpdated(acceleration)
        rotationUpdated(position.revolutionsSinceConnecting, elapsedTime: position.secondsSinceConnecting)
        
        connection?.readLedColor()
    }
    
    func calibrate() {
        
        guard let connection = connection else {
            return
        }
        
        calibrating = true
        output?.deviceCalibrating(calibrating)
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Start calibration process (this may take up to 10 seconds)
        let calibration = queue.tb_addAsyncOperationBlock("calibration") { [weak self] (operation: AsyncOperation) -> Void in
            self?.calibrationComplete = { operation.done() }
            self?.connection?.startCalibration()
        }
        
        // Reset Orientation
        let orientation = queue.tb_addAsyncOperationBlock("orientation") { [weak self] (operation: AsyncOperation) -> Void in
            self?.resetOrientationComplete = { operation.done() }
            self?.connection?.resetOrientation()
        }
        
        
        // Notify VC
        let finished = queue.tb_addAsyncOperationBlock("finished") { [weak self] (operation: AsyncOperation) -> Void in
            OperationQueue.main.addOperation({ [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.calibrating = false
                strongSelf.output?.deviceCalibrating(strongSelf.calibrating)
                operation.done()
            })
        }

        orientation.addDependency(calibration)
        finished.addDependency(orientation)
        finished.addDependency(calibration)

        // Reset Revolutions - only if cycling service is available
        if connection.capabilities.contains(.revolutions) {
            let revolutions = queue.tb_addAsyncOperationBlock("revolutions") { [weak self] (operation: AsyncOperation) -> Void in
                self?.resetRevolutionsComplete = { operation.done() }
                self?.connection?.resetRevolutions()
            }
            
            revolutions.addDependency(calibration)
            revolutions.addDependency(orientation)
            finished.addDependency(revolutions)
        }

        queue.isSuspended = false
    }
    
    func wheelDiameter() -> Meters {
        return position.diameter
    }
    
    //MARK: - MotionDemoConnectionDelegate
    
    func demoDeviceDisconnected() {
        finishedCalbration()
        finishedOrientationReset()
        finishedRevolutionsReset()
    }
    
    func startedCalibration() {
        log.info("Calibration Started")
    }
    
    func finishedCalbration() {
        log.info("Calibration Finished")
        self.calibrationComplete?()
        self.calibrationComplete = nil
    }
    
    func startedOrientationReset() {
        log.info("Orientation Reset Started")
    }
    
    func finishedOrientationReset() {
        log.info("Orientation Reset Finished")
        self.resetOrientationComplete?()
        self.resetOrientationComplete = nil
    }
    
    func startedRevolutionsReset() {
        log.info("Revolutions Reset Started")
    }
    
    func finishedRevolutionsReset() {
        log.info("Revolutions Reset Finished")
        self.resetRevolutionsComplete?()
        self.resetRevolutionsComplete = nil
    }
    
    func orientationUpdated(_ inclination: ThunderboardInclination) {
        orientation = inclination
        output?.updateOrientation(inclination)
    }
    
    func accelerationUpdated(_ vector: ThunderboardVector) {
        acceleration = vector
        output?.updateAcceleration(vector)
    }
    
    func ledColorUpdated(_ on: Bool, color: LedRgb) {
        output?.updateLedColor(on, color: color)
    }
    
    func rotationUpdated(_ revolutions: UInt, elapsedTime: TimeInterval) {
        position.updateRevolutions(revolutions, cumulativeSecondsSinceConnecting: elapsedTime)
        let speed    = position.speedInMetersPerSecond
        let distance = position.distance
        let rpm      = position.rpm
        let total    = position.revolutionsSinceConnecting
        output?.updateLocation(distance, speed: speed, rpm: rpm, totalRpm: total)
    }
}
