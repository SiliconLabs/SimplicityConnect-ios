//
//  WiFiMotionDemoConnection.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 29/06/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class WiFiMotionDemoConnection: MotionDemoConnection {
    var device: any Device
    
    
    fileprivate var bleDevice: BleDevice {
        get { return device as! BleDevice }
    }
    
    weak var connectionDelegate: MotionDemoConnectionDelegate?

    fileprivate let startCalibrationId = 0x01
    fileprivate let resetOrientationId = 0x02

    init(device: BleDevice) {
        self.device = device
        self.bleDevice.demoConnectionCharacteristicValueUpdated = { [weak self] (characteristic: CBCharacteristic) in
            self?.characteristicUpdated(characteristic)
        }
        self.bleDevice.demoDeviceDisconnectedHook = { [weak self] in
            self?.connectionDelegate?.demoDeviceDisconnected()
        }
    }
    
    func characteristicUpdated(_ characteristic: CBCharacteristic) {

        switch characteristic.uuid {
        case CBUUID.CSCMeasurement:
            notifyRotation(characteristic)

        case CBUUID.AccelerationMeasurement:
            notifyAcceleration(characteristic)

        case CBUUID.OrientationMeasurement:
            notifyOrientation(characteristic)

        case CBUUID.Command:
            notifyCommand(characteristic)

        case CBUUID.CSCControlPoint:
            notifyCSCControlPoint(characteristic)
            
        case CBUUID.SenseRGBOutput:
            notifyColorUpdated(characteristic)
            
        default:
            log.debug("unknown UUID: \(characteristic.uuid)")
            break
        }
    }

    // MotionDemoConnection protocol
    
    func startCalibration() {
        let data = Data(bytes: [UInt8(0x01)])
        self.bleDevice.writeValueForCharacteristic(CBUUID.Command, value: data)
        
        self.connectionDelegate?.startedCalibration()
    }
    
    func resetOrientation() {
        let data = Data(bytes: [UInt8(0x02)])
        self.bleDevice.writeValueForCharacteristic(CBUUID.Command, value: data)
        
        self.connectionDelegate?.startedOrientationReset()
    }
    
    func resetRevolutions() {
        let data = Data(bytes: [UInt8(0x01), 0, 0, 0, 0])
        self.bleDevice.writeValueForCharacteristic(CBUUID.CSCControlPoint, value: data)
        
        self.connectionDelegate?.startedRevolutionsReset()
    }
    
    func readLedColor() {
        self.bleDevice.readValuesForCharacteristic(CBUUID.SenseRGBOutput)
    }
    
    // Internal
    
    fileprivate func notifyRotation(_ characteristic: CBCharacteristic) {
        if let cscMeasurement:ThunderboardCSCMeasurement = characteristic.tb_cscMeasurementValue() {
            
            let revolutions = cscMeasurement.revolutionsSinceConnecting
            let elapsedTime = cscMeasurement.secondsSinceConnecting
            self.connectionDelegate?.rotationUpdated(UInt(revolutions), elapsedTime: elapsedTime)
        }
    }
    
    fileprivate func notifyOrientation(_ characteristic: CBCharacteristic) {
        if let inclination = characteristic.tb_inclinationValue() {
            self.connectionDelegate?.orientationUpdated(inclination)
        }
    }
    
    fileprivate func notifyAcceleration(_ characteristic: CBCharacteristic) {
        if let vector = characteristic.tb_vectorValue() {
            self.connectionDelegate?.accelerationUpdated(vector)
        }
    }
    
    fileprivate func notifyCommand(_ characteristic: CBCharacteristic) {
        if let value = characteristic.tb_uint32Value() {
            
            let command = Int(value >> 8) & 0b11
            if command == startCalibrationId {
                self.connectionDelegate?.finishedCalbration()
            }
            
            else if command == resetOrientationId {
                self.connectionDelegate?.finishedOrientationReset()
            }
            
            else {
                log.debug("Unknown notify command: \(command)")
            }
        }
    }
    
    fileprivate func notifyColorUpdated(_ characteristic: CBCharacteristic) {
        guard let ledState = characteristic.tb_analogLedState() else {
            return
        }
        
        switch ledState {
        case .rgb(let on, let color):
            connectionDelegate?.ledColorUpdated(on, color: color)
        default:
            break
        }
    }
    
    fileprivate func notifyCSCControlPoint(_ characteristic: CBCharacteristic) {
        self.connectionDelegate?.finishedRevolutionsReset()
    }
}
