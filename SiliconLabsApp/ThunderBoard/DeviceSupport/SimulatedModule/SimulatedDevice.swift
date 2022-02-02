//
//  SimulatedDevice.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

class SimulatedDevice : Device, DemoConfiguration, Equatable, CustomDebugStringConvertible {
    
    var modelName: String
    fileprivate (set) var model: DeviceModel
    var name: String?
    var advertisementDataLocalName: String?
    var deviceIdentifier: DeviceId? {
        didSet {
            self.deviceIdentifierUpdated()
        }
    }
    var RSSI: Int?
    var firmwareVersion: String?
    var connectionState: DeviceConnectionState {
        didSet {
            switch connectionState {
            case .disconnected:
                break
                
            case .connecting:
                break
                
            case .connected:
                delay(1) {
                    self.power = [
                        .usb,
                        .aa(99),
                        .aa(70),
                        .coinCell(27),
                        .coinCell(13),
                        .coinCell(5),
                    ].random()
                    self.firmwareVersion = "0.4.0";
                    self.notifyConnectedDelegate()
                }
            }
        }
    }
    
    fileprivate (set) var power: PowerSource = .unknown
    fileprivate (set) var capabilities: Set<DeviceCapability> = []
    
    weak var connectedDelegate: ConnectedDeviceDelegate?
    weak var simulatedScanner: SimulatedDeviceScanner?
    weak var demoConnection: DemoConnection?
    
    init(name: String, identifier: DeviceId, capabilities: Set<DeviceCapability>, rssi: Int? = nil, model: DeviceModel? = .react) {
        self.model = model ?? .react
        self.name = name
        self.deviceIdentifier = identifier
        self.capabilities = capabilities
        self.RSSI = rssi ?? -40
        self.modelName = ""
        connectionState = .disconnected
        
        delay(2.0) {
            self.deviceIdentifier = DeviceId(100)
            self.notifyConnectedDelegate()
        }
    }
    
    fileprivate func notifyConnectedDelegate() {
        self.connectedDelegate?.connectedDeviceUpdated(self.name!, RSSI: self.RSSI, power: self.power, identifier: self.deviceIdentifier, firmwareVersion: self.firmwareVersion)
    }
    
    typealias CalibrationCompletion = ( () -> Void )
    func startCalibration(_ completion: CalibrationCompletion?) {
        
        delay(5) {
            completion?()
        }
        
        // simulate a disconnect
//        delay(1) { [weak self] in
//            self?.simulateLostConnection()
//        }
    }
    
    func isThunderboardDevice() -> Bool {
        return true
    }
    
    var debugDescription: String {
        get { return "\(String(describing: name)): \(String(describing: deviceIdentifier)) \(capabilities) \(power)" }
    }
    
    //MARK: - Private
    
    fileprivate func simulateLostConnection() {

        self.simulatedScanner?.simulateLostConnection(self)
    }
    
    //MARK: - DemoConfiguration
    
    weak var configurationDelegate: DemoConfigurationDelegate?
    func configureForDemo(_ demo: ThunderboardDemo) {

        switch demo {
        case .io:
            configureIoDemo()
            
        case .environment:
            configureEnvironmentDemo()

        case .motion:
            configureMotionDemo()
        }
    }
    
    func resetDemoConfiguration() {
        log.debug("Demo Reset Requested")
        delay(1) {
            self.configurationDelegate?.demoConfigurationReset()
        }
    }
    
    fileprivate func deviceIdentifierUpdated() {
        guard let deviceIdentifier = deviceIdentifier else { return }
        self.configurationDelegate?.deviceIdentifierUpdated(deviceIdentifier)
    }
    
    fileprivate func configureIoDemo() {
        self.configurationDelegate?.configuringIoDemo()
        delay(0.2) {
            let connection = SimulatedIoDemoConnection(device: self)
            self.configurationDelegate?.ioDemoReady(connection)
            self.demoConnection = connection
        }
    }
    
    fileprivate func configureEnvironmentDemo() {
        self.configurationDelegate?.configuringEnvironmentDemo()
        
        delay(0.5) {
            let connection = SimulatedEnvironmentDemoConnection(device: self)
            self.configurationDelegate?.environmentDemoReady(connection)
            self.demoConnection = connection
        }
    }
    
    fileprivate func configureMotionDemo() {
        self.configurationDelegate?.configuringMotionDemo()
        
        delay(0.5) {
            let connection = SimulatedMotionDemoConnection(device: self)
            self.configurationDelegate?.motionDemoReady(connection)
            self.demoConnection = connection
        }
    }
}

func ==(lhs: SimulatedDevice, rhs: SimulatedDevice) -> Bool {
    return lhs.deviceIdentifier == rhs.deviceIdentifier
}

extension Array {
    
    func random() -> Element {
        let randomIndex = Int(arc4random()) % count
        return self[randomIndex]
    }
}
