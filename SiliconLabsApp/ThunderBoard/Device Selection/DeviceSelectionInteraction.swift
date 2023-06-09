//
//  DeviceSelectionInteraction.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol DeviceSelectionInteractionOutput : class {
    
    // power
    func bleEnabled(_ enabled: Bool)
    
    // scanning
    func bleScanningListUpdated()
    func bleDeviceUpdated(_ device: DiscoveredDeviceDisplay, index: Int)
    
    // connection
    func interactionShowConnectionTimedOut(_ deviceName: String)
    func interactionShowConnectionFailed()
    func interactionDidFinishDeviceConfiguration(_ connection: DemoConnection, deviceConnector: DeviceConnection)
    func interactionDidConnectWithBlinkyDevice(_ device: Device, deviceConnector: DeviceConnection, isThunderboard: Bool)
}

@objcMembers
class DiscoveredDeviceDisplay: NSObject {
    var name: String
    private var _RSSI: Int?
    var RSSI: NSNumber? {
        get {
            return _RSSI as NSNumber?
        }
        set(newValue) {
            _RSSI = newValue?.intValue
        }
    }
    var connecting: Bool
    
    init(name: String, RSSI: NSNumber?, connecting: Bool) {
        self.name = name
        self.connecting = connecting
        super.init()
        
        self.RSSI = RSSI
    }
}

struct DiscoveredDevice {
    let device: Device
    let latestDiscovery: Date
}

class DeviceSelectionInteraction : DeviceScannerDelegate, DeviceConnectionDelegate, DemoConfigurationDelegate {
    
    fileprivate var deviceScanner: DeviceScanner?
    fileprivate var deviceConnector: DeviceConnection?
    var discoveredDevices = Array<DiscoveredDevice>()
    
    fileprivate var autoConnectDeviceName: String?
    fileprivate var abandonAutoConnectTimer: WeakTimer?
    fileprivate var expiredDiscoveryTimer: WeakTimer?
    fileprivate let expirationDuration: TimeInterval = 10
    fileprivate let updateThrottle = Throttle(interval: 0.75)
    
    var interactionOutput: DeviceSelectionInteractionOutput?
    private let appType: SILAppType
    private let filter: ((Device) -> Bool)?
    
    var connectedDevice: BleDevice?
    
    init(scanner: DeviceScanner, connector: DeviceConnection, appType: SILAppType, filter: ((Device) -> Bool)? = nil) {
        self.appType = appType
        self.filter = filter
        
        self.deviceScanner = scanner
        self.deviceScanner?.scanningDelegate = self
        
        self.deviceConnector = connector
        self.deviceConnector?.connectionDelegate = self
        
    }
    
    //MARK:- Public
    
    func startScanning() {
        self.deviceConnector?.disconnectAllDevices()
        self.deviceScanner?.startScanning()
        self.expiredDiscoveryTimer = WeakTimer.scheduledTimer(1, repeats: true, action: expiredDiscoveryTask)
    }
    
    func stopScanning() {
        self.deviceScanner?.stopScanning()
        self.clearDeviceList()
        self.expiredDiscoveryTimer = nil
    }
    
    func automaticallyConnectToDevice(_ identifier: String) {
        log.info("\(identifier)")
        setupAutoConnection(identifier)
    }
    
    func connectToDevice(_ index: Int) {
        if index < self.discoveredDevices.count {
            self.deviceConnector?.connect(self.discoveredDevices[index].device)
            
            abandonAutoConnectionDevice()
        }
    }
    
    func connectToDevice(_ device: Device) {
        if let index = self.discoveredDevices.firstIndex(where: { $0.device.deviceIdentifier == device.deviceIdentifier }) {
            connectToDevice(index)
        }
    }
    
    func numberOfDevices() -> Int {
        return self.discoveredDevices.count
    }
    
    func deviceAtIndex(_ index: Int) -> DiscoveredDeviceDisplay? {
        if self.discoveredDevices.count > index {
            let device = self.discoveredDevices[index].device
            let rssi = device.RSSI != nil ? NSNumber(value: device.RSSI!) : nil
            return DiscoveredDeviceDisplay(name: device.displayName(), RSSI: rssi, connecting: device.connectionState == .connecting)
        }
        return nil
    }
    
    //MARK:- Internal
    
    fileprivate func notifyPowerState(_ state: DeviceTransportState) {
        switch (state) {
        case .disabled:
            self.interactionOutput?.bleEnabled(false)
        case .enabled:
            self.interactionOutput?.bleEnabled(true)
        }
    }
    
    fileprivate func clearDeviceList() {
        self.discoveredDevices.removeAll()
    }
    
    fileprivate func indexOfDevice(_ device: BleDevice) -> Int {

        // It causes displaying only one blinky example
        for (index, d) in self.discoveredDevices.enumerated() {
            if let bleDevice = d.device as? BleDevice, bleDevice.cbPeripheral.identifier == device.cbPeripheral.identifier {
                return index
            }
        }
        
        return NSNotFound
    }
    
    fileprivate func expiredDiscoveryTask() {
        let validDevices = self.discoveredDevices.filter({
            let now = Date()
            let lastTime = now.timeIntervalSince($0.latestDiscovery)
            return lastTime < expirationDuration
        })

        let notify = self.discoveredDevices.count != validDevices.count
        defer { if notify { self.interactionOutput?.bleScanningListUpdated() } }
        
        self.discoveredDevices = validDevices
    }
    
    //MARK: - Internal (Auto Connection)
    
    fileprivate func setupAutoConnection(_ identifier: String) {
        autoConnectDeviceName = identifier
        abandonAutoConnectTimer = WeakTimer.scheduledTimer(5, repeats: false, action: { [weak self] () -> Void in
            log.info("Abandoning attempts to connect to \(identifier) - timeout")
            self?.abandonAutoConnectionDevice()
        })
        
        attemptAutoConnection()
    }
    
    fileprivate func attemptAutoConnection() {
        guard let name = autoConnectDeviceName else {
            return
        }
        
        log.debug("discovered devices: \(self.discoveredDevices)")
        guard let discovered = self.discoveredDevices.filter({ return $0.device.name == name }).first else {
            log.info("No discovered devices match pending auto-connect device")
            return
        }
        
        guard let connector = self.deviceConnector else {
            log.error("No device connector available")
            return
        }
        
        if connector.isConnectedToDevice(discovered.device) {
            log.info("already connected to \(name), ignoring auto-connect request")
            abandonAutoConnectionDevice()
        }
        else {
            log.info("Attempting auto connection to device \(name)")
            self.connectToDevice(discovered.device)
        }
    }
    
    fileprivate func abandonAutoConnectionDevice() {
        autoConnectDeviceName = nil
        abandonAutoConnectTimer?.stop()
        abandonAutoConnectTimer = nil
    }
    
    //MARK:- DeviceScannerDelegate
    
    func transportPowerStateUpdated(_ state: DeviceTransportState) {

        notifyPowerState(state)
        
        switch (state) {
        case .disabled:
            stopScanning()
        case .enabled:
            startScanning()
        }
    }
    
    func discoveredDevice(_ device: Device) {
        if let filter = self.filter, !filter(device) {
            return
        }
        
        guard let device = device as? BleDevice else {
            return
        }

        let index = indexOfDevice(device)
        let discovered = DiscoveredDevice(device: device, latestDiscovery: Date())
        
        if index == NSNotFound {
            discoveredDevices.append(discovered)
            interactionOutput?.bleScanningListUpdated()
        }
        else {
            if let display = deviceAtIndex(index) {
                discoveredDevices[index] = discovered
                updateThrottle.run({ 
                    self.interactionOutput?.bleDeviceUpdated(display, index: index)
                })
            }
        }

        attemptAutoConnection()
    }
    
    private func configureForBlinky(_ device: Device) {
        if device.modelName == "BRD4184A" || device.modelName == "BRD4184B" {
            self.interactionOutput?.interactionDidConnectWithBlinkyDevice(device, deviceConnector: self.deviceConnector!,
                                                                          isThunderboard: true)
            return
        }
        self.configureDevice(device)
    }
    
    private func configureDevice(_ device: Device) {
        var thunderboardDemo: ThunderboardDemo
        switch self.appType {
        case .typeMotion:
            thunderboardDemo = .motion
        case .typeBlinky:
            thunderboardDemo = .io
        case .typeEnvironment:
            thunderboardDemo = .environment
        default:
            return
        }
        device.configureForDemo(thunderboardDemo)
    }
    
    //MARK:- DeviceConnectionDelegate
    
    func connectedToDevice(_ device: Device) {
        if self.appType == .typeBlinky, device.name!.hasPrefix("Blinky") {
            self.interactionOutput?.interactionDidConnectWithBlinkyDevice(device, deviceConnector: self.deviceConnector!,
                                                                          isThunderboard: false)
            return
        }
        device.configurationDelegate = self
    }
    
    func connectionToDeviceFailed() {
        interactionOutput?.interactionShowConnectionFailed()
    }
    
    func connectionToDeviceTimedOut(_ device: Device) {
        guard let name = device.name else {
            self.interactionOutput?.interactionShowConnectionTimedOut("")
            return
        }
        
        interactionOutput?.interactionShowConnectionTimedOut(name)
    }
    
    // MARK: DemoConfigurationDelegate
    
    func deviceIdentifierUpdated(_ deviceId: DeviceId) { }
    
    func modelNameReady(device: Device) {
        if self.appType == .typeBlinky {
            configureForBlinky(device)
        } else {
            configureDevice(device)
        }
    }
    
    func configuringIoDemo() { }
    
    func ioDemoReady(_ connection: IoDemoConnection) {
        self.interactionOutput?.interactionDidFinishDeviceConfiguration(connection, deviceConnector: deviceConnector!)
    }
    
    func configuringMotionDemo() {
        debugPrint("Thunderboard: Configuring Motion Demo")
    }
    
    func motionDemoReady(_ connection: MotionDemoConnection) {
        self.interactionOutput?.interactionDidFinishDeviceConfiguration(connection, deviceConnector: deviceConnector!)
    }
    
    func configuringEnvironmentDemo() {
        debugPrint("Thunderboard: Configuring Environment Demo")
    }
    
    func environmentDemoReady(_ connection: EnvironmentDemoConnection) {
        self.interactionOutput?.interactionDidFinishDeviceConfiguration(connection, deviceConnector: deviceConnector!)
    }
    
    func demoConfigurationReset() {
        debugPrint("Thunderboard: Demo configuration reset")
    }
}
