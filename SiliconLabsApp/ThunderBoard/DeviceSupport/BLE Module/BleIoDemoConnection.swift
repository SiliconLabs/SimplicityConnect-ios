//
//  BleIoDemoConnection.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation
import CoreBluetooth

class BleIoDemoConnection: IoDemoConnection {

    var device: Device
    
    var numberOfLeds: Int {
        if modelHasOneLedAndOneButton(modelName: bleDevice.modelName) {
            return 1
        }
        
        return 2 + ((hasAnalogRgb) ? 1 : 0)
    }
    
    var numberOfSwitches: Int {
        if modelHasOneLedAndOneButton(modelName: bleDevice.modelName) {
            return 1
        }
        
        return 2    // TODO: detect this value based on digital characteristics
    }

    fileprivate var bleDevice: BleDevice {
        get { return device as! BleDevice }
    }
    
    fileprivate var ledMask: UInt8    = 0
    fileprivate var buttonMask: UInt8 = 0
    fileprivate let digitalBits = 2 // TODO: each digital uses two bits
    fileprivate let digitalInputIndexes = [ 0, 1 ]
    fileprivate let digitalOutputIndexes = [ 0, 1 ]
    fileprivate var analogState: LedState?  // only support one analog LED currently
    fileprivate let hasAnalogRgb: Bool
    fileprivate let ledWriteThrottle = Throttle(interval: 0.25) // up to four writes per second

    init(device: BleDevice) {
        self.device = device
        
        hasAnalogRgb = device.capabilities.contains(.rgbOutput)
        
        self.bleDevice.demoConnectionCharacteristicValueUpdated = { [weak self] (characteristic: CBCharacteristic) in
            self?.characteristicUpdated(characteristic)
        }
        
        self.bleDevice.demoDeviceDisconnectedHook = { [weak self] in
            self?.connectionDelegate?.demoDeviceDisconnected()
        }

        self.bleDevice.readValuesForCharacteristic(CBUUID.Digital)
    }
    
    var deviceId: DeviceId {
        guard let id = device.deviceIdentifier else {
            return 0
        }
        
        return id
    }
    
    func characteristicUpdated(_ characteristic: CBCharacteristic) {
        log.debug("updated \(characteristic)")
        switch characteristic.uuid {
        case CBUUID.Digital:
            if characteristic.tb_supportsNotificationOrIndication() {
                updateButtonState(characteristic)
                notifyButtonState()
            }
            else {
                updateLedState(characteristic)
                notifyLedState()
            }
            
        case CBUUID.SenseRGBOutput:
            updateLedState(characteristic)
            notifyLedState()
            
        default:
            break
        }
    }
    
    weak var connectionDelegate: IoDemoConnectionDelegate? {
        didSet {
            self.bleDevice.readValuesForCharacteristic(CBUUID.Digital)
            self.bleDevice.readValuesForCharacteristic(CBUUID.SenseRGBOutput)
        }
    }

    func setLed(_ led: Int, state: LedState) {
        switch state {
        case .digital(let on, _):
            setDigitalOutput(led, on: on)
        case .rgb(let on, let color):
            setAnalogOutput(on, color: color)
        }
    }

    func ledState(_ led: Int) -> LedState {
        if digitalOutputIndexes.contains(led) {
            return digitalState(ledMask, index: led)
        }
        else {
            return analogState(2)
        }
    }
    
    func isSwitchPressed(_ switchIndex: Int) -> Bool {
        return isDigitalHigh(buttonMask, index: switchIndex)
    }

    //MARK: - Internal
    
    fileprivate func setDigitalOutput(_ index: Int, on: Bool) {
        let shift = UInt(index) * UInt(digitalBits)
        var mask = ledMask
        
        if on {
            mask = mask | UInt8(1 << shift)
        }
        else {
            mask = mask & ~UInt8(1 << shift)
        }
        
        let data = Data(bytes: [mask])
        self.bleDevice.writeValueForCharacteristic(CBUUID.Digital, value: data)
        
        // *** Note: sending notification optimistically ***
        // Since we're writing the full mask value, LILO applies here,
        // and we *should* end up consistent with the device. Waiting to
        // read back after write causes rubber-banding during fast write sequences. -tt
        ledMask = mask
        notifyLedState()
    }
    
    fileprivate func setAnalogOutput(_ on: Bool, color: LedRgb) {
        let data = colorDataForLedRgb(on, color: color)
        
        ledWriteThrottle.run() {
            self.bleDevice.writeValueForCharacteristic(CBUUID.SenseRGBOutput, value: data)
        }

        // Send analog notification optimistically
        analogState = LedState.rgb(on, color)
        notifyLedState()
    }
    
    fileprivate func digitalState(_ mask: UInt8, index: Int) -> LedState {
        let ledColor = device.ledColor(index)
        return LedState.digital(isDigitalHigh(ledMask, index: index), ledColor)
    }
    
    fileprivate func analogState(_ index: Int) -> LedState {
        guard let analogState = analogState else {
            log.error("invalid analog state")
            return LedState.rgb(false, LedRgb(red: 0, green: 0, blue: 0))
        }
        
        return analogState
    }
    
    fileprivate func isDigitalHigh(_ mask: UInt8, index: Int) -> Bool {
        let shift = index * Int(digitalBits)
        return (mask & UInt8(1 << shift)) != 0
    }
    
    fileprivate func updateButtonState(_ characteristic: CBCharacteristic) {
        guard let newMask = characteristic.tb_uint8Value() else {
            return
        }

        buttonMask = newMask
    }
    
    fileprivate func notifyButtonState() {
        for index in digitalInputIndexes {
            self.connectionDelegate?.buttonPressed(index, pressed: isDigitalHigh(buttonMask, index: index))
        }
    }

    fileprivate func updateLedState(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Digital:
            ledMask = characteristic.tb_uint8Value() ?? ledMask
            break
        case CBUUID.SenseRGBOutput:
            analogState = characteristic.tb_analogLedState()
            break
        default:
            break
        }
    }
    
    fileprivate func notifyLedState() {
        for index in digitalOutputIndexes {
            let state = digitalState(ledMask, index: index)
            self.connectionDelegate?.updatedLed(index, state: state)
        }
        
        if let analogState = analogState {
            self.connectionDelegate?.updatedLed(2, state: analogState)
        }
    }
    
    fileprivate func colorDataForLedRgb(_ on: Bool, color: LedRgb) -> Data {
        // 0000
        // 0001 0x01 back, lower (near USB)
        // 0010 0x02 back, upper
        // 0100 0x04 front, upper
        // 1000 0x08 front, lower (near USB)
        let enabledLeds = on ? bleDevice.turnOnRGBLedCommand : UInt8(0x00)
        return Data(bytes: [enabledLeds,
                            UInt8(color.red * 255),
                            UInt8(color.green * 255),
                            UInt8(color.blue * 255)])
    }
    
    fileprivate func modelHasOneLedAndOneButton(modelName: String) -> Bool {
        let modelsWithOneLetAndOneButton = [
            "BRD4184A",
            "BRD4184B"
        ]
        
        return modelsWithOneLetAndOneButton.contains(modelName)
    }
}
