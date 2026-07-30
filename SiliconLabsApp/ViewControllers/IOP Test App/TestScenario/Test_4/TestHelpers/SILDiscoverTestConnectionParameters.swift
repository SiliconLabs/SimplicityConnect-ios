//
//  SILDiscoverTestConnectionParameters.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILDiscoverTestConnectionParameters {
    private let log = IOPLog()
    enum State {
        case initiated
        case running
        case failed
        case completed(firmwareInfo: SILIOPTestFirmwareInfo, connectionParameters: SILIOPTestConnectionParameters)
    }
    
    var state: SILObservable<State> = SILObservable(initialValue: .initiated)
    
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var stackVersion: String!
    private var deviceName: String!
    private var connectionParameters: SILIOPTestConnectionParameters?
    private var firmware: SILIOPFirmware?
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var iopTestFeaturesRFUCharacteristic = SILIOPPeripheral.SILIOPTest.IOPTestConnection.cbUUID
    private var iopTestService = SILIOPPeripheral.SILIOPTest.cbUUID
    
    private var deviceInformationService = SILIOPPeripheral.DeviceInformationService.cbUUID
    private var modelNumberStringCharacteristic = SILIOPPeripheral.DeviceInformationService.ModelNumberStringCharacteristic.cbUUID
    
    private var isVersionNumberLesserThan3_3_0: Bool {
        return stackVersion.versionCompare("3.3.0") == .orderedAscending
    }
    
    private var isVersionNumberGreaterThan6_0_0: Bool {
        return stackVersion.versionCompare("6.0.0") == .orderedDescending || stackVersion.versionCompare("6.0.0") == .orderedSame
    }
 
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.peripheralDelegate = parameters["peripheralDelegate"] as? SILPeripheralDelegate
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
        self.stackVersion = parameters["stackVersion"] as? String
        self.deviceName = parameters["peripheralLocalName"] as? String
    }
    
    func run() {
        guard let _ = peripheral else {
            log.step(source: "SILDiscoverTestConnectionParameters",
                     action: "Cannot discover connection parameters",
                     detail: "Peripheral is nil.")
            self.state.value = .failed
            return
        }
        
        guard let _ = peripheralDelegate else {
            log.step(source: "SILDiscoverTestConnectionParameters",
                     action: "Cannot discover connection parameters",
                     detail: "Peripheral delegate is nil.")
            self.state.value = .failed
            return
        }
        
        log.step(source: "SILDiscoverTestConnectionParameters",
                 action: "Discover connection parameter characteristics",
                 detail: "rfuChar=\(iopTestFeaturesRFUCharacteristic.uuidString) | modelChar=\(modelNumberStringCharacteristic.uuidString) | stackVersion=\(stackVersion ?? "unknown")")
        self.state.value = .running
        subscribeToPeripheralDelegate()
        subscribeToCentralManager()
        
        guard let iopTestService = self.peripheral.services?.first(where: { service in service.uuid == iopTestService }) else {
            log.gatt(source: "SILDiscoverTestConnectionParameters",
                     operation: "Resolve IOP Test service",
                     serviceUUID: self.iopTestService,
                     outcome: "Required IOP Test service not found on peripheral")
            setFailed()
            return
        }
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestFeaturesRFUCharacteristic], for: iopTestService)
        
        if !isVersionNumberLesserThan3_3_0 {
            guard let deviceInformationService = self.peripheral.services?.first(where: { service in service.uuid == deviceInformationService }) else {
                log.gatt(source: "SILDiscoverTestConnectionParameters",
                         operation: "Resolve Device Information service",
                         serviceUUID: self.deviceInformationService,
                         outcome: "Device Information service not found on peripheral")
                setFailed()
                return
            }
            peripheralDelegate.discoverCharacteristics(characteristics: [modelNumberStringCharacteristic], for: deviceInformationService)
        }
        
    }
    
    private func subscribeToCentralManager() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                weakSelf.log.connection(source: "SILDiscoverTestConnectionParameters",
                                        action: "Connection parameter discovery disconnected",
                                        peripheralName: weakSelf.peripheral?.name,
                                        identifier: weakSelf.peripheral?.identifier,
                                        error: error)
                weakSelf.setFailed()
            
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILDiscoverTestConnectionParameters",
                                      action: "Connection parameter discovery interrupted",
                                      detail: "Bluetooth was disabled.")
                    weakSelf.setFailed()
                }
                
            case .unknown:
                break
            
            default:
                weakSelf.log.step(source: "SILDiscoverTestConnectionParameters",
                                  action: "Connection parameter discovery failed",
                                  detail: "Received an unexpected central manager status.")
                weakSelf.setFailed()
            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func subscribeToPeripheralDelegate() {
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForCharacteristics(characteristics):
                switch characteristics.first?.service?.uuid {
                case weakSelf.deviceInformationService:
                    if !weakSelf.isVersionNumberLesserThan3_3_0 {
                        guard let modelNumberStringCharacteristic = weakSelf.peripheralDelegate.findCharacteristic(with: weakSelf.modelNumberStringCharacteristic,
                                                                                                                   in: characteristics) else  {
                            weakSelf.log.gatt(source: "SILDiscoverTestConnectionParameters",
                                              operation: "Resolve model number characteristic",
                                              uuid: weakSelf.modelNumberStringCharacteristic,
                                              serviceUUID: weakSelf.deviceInformationService,
                                              outcome: "Model number characteristic not found")
                            weakSelf.setFailed()
                            return
                        }
                        weakSelf.log.gatt(source: "SILDiscoverTestConnectionParameters",
                                          operation: "Read model number characteristic",
                                          uuid: modelNumberStringCharacteristic.uuid,
                                          serviceUUID: weakSelf.deviceInformationService,
                                          outcome: "Reading board name from Device Information service")
                        weakSelf.peripheralDelegate.readCharacteristic(characteristic: modelNumberStringCharacteristic)
                    }
                case weakSelf.iopTestService:
                    guard let featuresRFUCharacteristic = weakSelf.peripheralDelegate.findCharacteristic(with: weakSelf.iopTestFeaturesRFUCharacteristic,
                                                                                                         in: characteristics) else {
                        weakSelf.log.gatt(source: "SILDiscoverTestConnectionParameters",
                                          operation: "Resolve RFU connection parameter characteristic",
                                          uuid: weakSelf.iopTestFeaturesRFUCharacteristic,
                                          serviceUUID: weakSelf.iopTestService,
                                          outcome: "RFU characteristic not found")
                        weakSelf.setFailed()
                        return
                    }
                    weakSelf.log.gatt(source: "SILDiscoverTestConnectionParameters",
                                      operation: "Read RFU connection parameter characteristic",
                                      uuid: featuresRFUCharacteristic.uuid,
                                      serviceUUID: weakSelf.iopTestService,
                                      outcome: "Reading MTU, PDU, interval, latency, supervision timeout, and PHY")
                    weakSelf.peripheralDelegate.readCharacteristic(characteristic: featuresRFUCharacteristic)
                default:
                    break
                }
               
            case let .successGetValue(value: data, characteristic: characteristic):
                switch characteristic.uuid {
                case weakSelf.iopTestFeaturesRFUCharacteristic:
                    if let byteData =  data?.bytes {
                        let arrayData = weakSelf.getFirmwareData(bytes: byteData)
                        
                        weakSelf.readIcNameFromBytesIfPossible(bytes: arrayData)
                        
                        let indexOfFirstData = weakSelf.isVersionNumberLesserThan3_3_0 ? 1 : 0
                        let mtu_size: Int = arrayData[indexOfFirstData]
                        let pdu_size: Int = arrayData[indexOfFirstData + 1]
                        let interval: Double = Double(arrayData[indexOfFirstData + 2]) * 1.25
                        let latency: Int = arrayData[indexOfFirstData + 3]
                        var supervision_timeout: Int = arrayData[indexOfFirstData + 4]
                        if weakSelf.isVersionNumberGreaterThan6_0_0 {
                            supervision_timeout = supervision_timeout * 10
                        }
                        var phy: Int = 0
                        if weakSelf.isVersionNumberGreaterThan6_0_0 {
                            phy = arrayData[indexOfFirstData + 5]
                        }
                        
                        weakSelf.log.gatt(source: "SILDiscoverTestConnectionParameters",
                                          operation: "Parse RFU connection parameter payload",
                                          uuid: characteristic.uuid,
                                          actual: data?.hexa(),
                                          outcome: "MTU=\(mtu_size) | PDU=\(pdu_size) | interval=\(interval) ms | latency=\(latency) | supervisionTimeout=\(supervision_timeout) | phy=\(phy)")
                        weakSelf.connectionParameters = SILIOPTestConnectionParameters(mtu_size: mtu_size,
                                                                                       pdu_size: pdu_size,
                                                                                       interval: interval,
                                                                                       latency: latency,
                                                                                       supervision_timeout: supervision_timeout,
                                                                                       phy: phy)
                        weakSelf.setCompletedIfPossible()
                        return
                    }
                case weakSelf.modelNumberStringCharacteristic:
                    if let data = data, let boardName = String(data: data, encoding: .utf8) {
                        weakSelf.log.gatt(source: "SILDiscoverTestConnectionParameters",
                                          operation: "Read model number characteristic",
                                          uuid: characteristic.uuid,
                                          actual: boardName,
                                          outcome: "Resolved board name from Device Information service")
                        weakSelf.firmware = .readName(boardName)
                        weakSelf.setCompletedIfPossible()
                        return
                    }
                default:
                    return
                }
                
                weakSelf.setFailed()
            
            case .unknown:
                break
                
            default:
                weakSelf.log.step(source: "SILDiscoverTestConnectionParameters",
                                  action: "Connection parameter discovery failed",
                                  detail: "Received an unexpected peripheral delegate status.")
                weakSelf.setFailed()
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
    }
    
    private func readIcNameFromBytesIfPossible(bytes: [Int]) {
        if isVersionNumberLesserThan3_3_0 {
            let ic_name: Int = bytes[0]
            if ic_name == 0 {
                firmware = .unknown
            } else if ic_name == 1 {
                firmware = .BRD4104A
            } else if ic_name == 2 {
                firmware = .BRD4181A
            } else if ic_name == 3 {
                firmware = .BRD4181B
            } else if ic_name == 4 {
                firmware = .BRD4182A
            } else if ic_name == 5 {
                firmware = .BRD4186B
            }
        }
    }
    
    private func setCompletedIfPossible() {
        guard let connectionParameters = self.connectionParameters else {
            return
        }
        guard let firmware = self.firmware else {
            return
        }
        let version = SILIOPFirmwareVersion(version: stackVersion)
        let firmwareInfo = SILIOPTestFirmwareInfo(originalVersion: version, name: deviceName, firmware: firmware)
        log.step(source: "SILDiscoverTestConnectionParameters",
                 action: "Connection parameter discovery completed",
                 detail: "Firmware=\(firmware.rawValue) | MTU=\(connectionParameters.mtu_size) | PDU=\(connectionParameters.pdu_size) | interval=\(connectionParameters.interval) ms | latency=\(connectionParameters.latency) | supervisionTimeout=\(connectionParameters.supervision_timeout) | phy=\(connectionParameters.phy)")
        invalidateObservableTokens()
        state.value = .completed(firmwareInfo: firmwareInfo, connectionParameters: connectionParameters)
    }
    
    private func setFailed() {
        log.step(source: "SILDiscoverTestConnectionParameters",
                 action: "Connection parameter discovery failed",
                 detail: "Unable to resolve all required firmware or RFU fields.")
        invalidateObservableTokens()
        state.value = .failed
    }
    
    private func getFirmwareData(bytes: [UInt8]) -> [Int] {
        let pairs = stride(from: 0, to: bytes.endIndex, by: 2).map { (val) -> Int in
            let firstVal = Int(bytes[val])
            let secondVal: Int = val < bytes.index(before: bytes.endIndex) ? Int(bytes[val.advanced(by: 1)])*256 : 0
            
            return firstVal + secondVal
        }

        return pairs
    }
    
    func invalidateObservableTokens() {
        for token in observableTokens {
            token?.invalidate()
        }
        
        observableTokens = []
    }
    
    func stopTesting() {
        invalidateObservableTokens()
    }
}
