//
//  IODemoInteraction.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

class IoDemoInteraction: IoDemoConnectionDelegate {
    
    fileprivate weak var output: IoDemoInteractionOutput?
    fileprivate var connection: IoDemoConnection?

    var isBobcatDevice: Bool {
        get {
            return self.connection?.device.model == .bobcat
        }
    }
    
    //MARK: Public
    
    init(output: IoDemoInteractionOutput?, demoConnection: IoDemoConnection) {
        self.output = output
        self.connection = demoConnection
        self.connection?.connectionDelegate = self
    }
    
    func updateView() {
        guard let connection = connection else { return }
                
        if connection.numberOfLeds == 1 {
            updateLed()
        } else {
            updateLeds()
        }
    
        if connection.numberOfSwitches == 1 {
            updateButton()
        } else {
            updateButtons()
        }
        
        if connection.capabilities.contains(.rgbOutput) == false {
            output?.disableRgb()
        }
        
        if connection.device.model == .bobcat {
            output?.disableLeds()
        }
    }
        
    func updateButton() {
        guard let connection = connection else { return }
        buttonPressed(0, pressed: connection.isSwitchPressed(0))
        output?.enable(true, switch: 0)
    }
    
    func updateButtons() {
        guard let connection = connection else { return }
        for switchIndex in 0 ..< connection.numberOfSwitches {
            buttonPressed(0, pressed: connection.isSwitchPressed(0))
            output?.enable(true, switch: switchIndex)
        }
    }
    
    func updateLed() {
        guard let connection = connection else { return }
        updatedLed(0, state: connection.ledState(0))
        output?.enable(true, led: 0)
    }
    
    func updateLeds() {
        guard let connection = connection else { return }
        for ledIndex in 0 ..< connection.numberOfLeds {
            updatedLed(ledIndex, state: connection.ledState(0))
            output?.enable(true, led: ledIndex)
        }
    }
    
    func turnOffLed(_ ledNum: Int) {
        guard let connection = connection else { return }
        let state = connection.ledState(ledNum)
        connection.setLed(ledNum, state: state.off())
    }
    
    func toggleLed(_ ledNum: Int) {
        guard let connection = connection else { return }
        let state = connection.ledState(ledNum)
        connection.setLed(ledNum, state: state.toggle())
    }
    
    func setColor(_ index: Int, color: LedRgb) {
        guard let connection = connection else { return }
        let state = connection.ledState(index).setColor(color)
        connection.setLed(index, state: state)
    }
    
    //MARK: IoDemoConnectionDelegate
    
    func demoDeviceDisconnected() { }
    
    func buttonPressed(_ button: Int, pressed: Bool) {
        output?.showButtonState(button, pressed: pressed)
    }
    
    func updatedLed(_ led: Int, state: LedState) {
        output?.showLedState(led, state: state)
    }
}
