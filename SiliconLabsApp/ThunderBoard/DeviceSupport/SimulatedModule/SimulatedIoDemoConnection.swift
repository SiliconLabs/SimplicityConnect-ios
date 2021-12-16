//
//  SimulatedIoDemoConnection.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

class SimulatedIoDemoConnection : IoDemoConnection {
    
    var device: Device
    weak var connectionDelegate: IoDemoConnectionDelegate?
    
    // For demo, switches will shadow the LEDs
    var numberOfLeds: Int = 1
    var numberOfSwitches: Int = 2
    fileprivate var deviceState: [LedState] = []
    
    init(device: SimulatedDevice) {
        self.device = device

        deviceState.append(LedState.digital(false, device.ledColor(0)))
        deviceState.append(LedState.digital(false, device.ledColor(1)))
        deviceState.append(LedState.rgb(false, LedRgb(red: 0.90, green: 0.50, blue: 0)))
    }

    func setLed(_ led: Int, state: LedState) {
        let index = Int(led)
        if index < deviceState.count {
            deviceState[index] = state
            
            delay(0.5) {
                self.connectionDelegate?.buttonPressed(index, pressed: self.isSwitchPressed(index))
            }

            self.connectionDelegate?.updatedLed(led, state: state)
        }
    }
    
    func ledState(_ led: Int) -> LedState {
        return deviceState[led]
    }
    
    func isSwitchPressed(_ switchIndex: Int) -> Bool {
        let state = ledState(switchIndex)
        switch state {
        case .digital(let on, _):
            return on
        case .rgb(let on, _):
            return on
        }
    }
}
