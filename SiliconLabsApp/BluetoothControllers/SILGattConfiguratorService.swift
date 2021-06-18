//
//  SILGattConfiguratorService.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 04/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

protocol SILGattConfiguratorServiceType : class {
    var runningGattConfiguration: SILObservable<SILGattConfigurationEntity?> { get set }
    var blutoothEnabled: SILObservable<Bool> { get set }
    
    func start(configuration: SILGattConfigurationEntity)
    func stop()
    func isRunning(configuration: SILGattConfigurationEntity) -> Bool
}

@objcMembers
class SILGattConfiguratorService: NSObject, SILGattConfiguratorServiceType, CBPeripheralManagerDelegate {
    static let shared = SILGattConfiguratorService()
    
    var runningGattConfiguration: SILObservable<SILGattConfigurationEntity?> = SILObservable(initialValue: nil)
    var blutoothEnabled: SILObservable<Bool> = SILObservable(initialValue: true)
    var helper: SILGattConfiguratorServiceHelper!
    lazy var peripheralManager: CBPeripheralManager = {
        return CBPeripheralManager()
    }()
    
    private var runningConfiguration: SILGattConfigurationEntity? {
        didSet {
            updateRunningConfiguration()
        }
    }
    
    private override init() {
        super.init()
    }
    
    deinit {
        stop()
    }
    
    func start(configuration: SILGattConfigurationEntity) {
        stop()
        
        debugPrint("start")
        self.runningConfiguration = configuration
        peripheralManager.delegate = self
        helper = SILGattConfiguratorServiceHelper(configuration: configuration)
        createServices(peripheralManager)
    }

    func stop() {
        debugPrint("stop")
        self.runningConfiguration = nil
        peripheralManager.delegate = nil
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        helper = nil
    }
    
    func isRunning(configuration: SILGattConfigurationEntity) -> Bool {
        return runningGattConfiguration.value?.uuid == configuration.uuid
    }

    private func updateRunningConfiguration() {
        runningGattConfiguration.value = runningConfiguration
    }
    
    func writeToLocalCharacteristic(data: Data, service: CBService, characteristic: CBCharacteristic) {
        helper.writeToLocalCharacteristic(data: data, service: service, characteristic: characteristic)
    }
    
    func updateLocalCharacteristicValue(data: Data, service: CBService, characteristic: CBCharacteristic) {
        helper.updateLocalCharacteristicValue(peripheral: peripheralManager, data: data, service: service, characteristic: characteristic)
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        createServices(peripheral)
    }
    
    func createServices(_ peripheral: CBPeripheralManager) {
        guard peripheralManager === peripheral else {
            return
        }
        
        if peripheral.state == CBManagerState.poweredOn {
            if blutoothEnabled.value == false {
                blutoothEnabled.value = true
                print("Bluetooth enabled")
            }
            
            let services = helper.services
            for service in services {
                peripheral.add(service)
            }
            helper.setCharacteristicValues()
            let advertisementData = helper.advertisementData
            peripheral.startAdvertising(advertisementData)
        } else if peripheral.state == CBManagerState.poweredOff {
            blutoothEnabled.value = false
            print("Bluetooth disabled")
            stop()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard let _ = runningConfiguration, peripheralManager === peripheral else {
            return
        }
        
        if let error = error {
            print("Error starting advertising gatt server", error.localizedDescription)
            stop()
        } else {
            print("Peripheral manager did start advertising gatt server")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard  peripheralManager === peripheral else {
            return
        }
        
        if let error = error {
            print("Error adding service to gatt configuration: ", error.localizedDescription)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Peripheral manager did receive read request from central", request.central)
        helper.peripheralManager(peripheral, didReceiveRead: request)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("Peripheral manager did receive write request from central", requests.first!.central)
        helper.peripheralManager(peripheral, didReceiveWrite: requests)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        helper.peripheralManager(peripheral, central: central, didSubscribeTo: characteristic)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        helper.peripheralManager(peripheral, central: central, didUnsubscribeFrom: characteristic)
    }
}
