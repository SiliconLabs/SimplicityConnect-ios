//
//  SILDiscoverTestConnectionParameters.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILDiscoverTestConnectionParameters {
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
            self.state.value = .failed
            return
        }
        
        guard let _ = peripheralDelegate else {
            self.state.value = .failed
            return
        }
        
        self.state.value = .running
        subscribeToPeripheralDelegate()
        subscribeToCentralManager()
        
        guard let iopTestService = self.peripheral.services?.first(where: { service in service.uuid == iopTestService }) else {
            setFailed()
            return
        }
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestFeaturesRFUCharacteristic], for: iopTestService)
        
        if !isVersionNumberLesserThan3_3_0 {
            guard let deviceInformationService = self.peripheral.services?.first(where: { service in service.uuid == deviceInformationService }) else {
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
                debugPrint("Peripheral disconnected with \(String(describing: error?.localizedDescription))")
                weakSelf.setFailed()
            
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    weakSelf.setFailed()
                }
                
            case .unknown:
                break
            
            default:
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
                switch characteristics.first?.service.uuid {
                case weakSelf.deviceInformationService:
                    if !weakSelf.isVersionNumberLesserThan3_3_0 {
                        guard let modelNumberStringCharacteristic = weakSelf.peripheralDelegate.findCharacteristic(with: weakSelf.modelNumberStringCharacteristic,
                                                                                                                   in: characteristics) else  {
                            weakSelf.setFailed()
                            return
                        }
                        weakSelf.peripheralDelegate.readCharacteristic(characteristic: modelNumberStringCharacteristic)
                    }
                case weakSelf.iopTestService:
                    guard let featuresRFUCharacteristic = weakSelf.peripheralDelegate.findCharacteristic(with: weakSelf.iopTestFeaturesRFUCharacteristic,
                                                                                                         in: characteristics) else {
                        weakSelf.setFailed()
                        return
                    }
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
                        let interval: Int = Int(Double(arrayData[indexOfFirstData + 2]) * 1.25)
                        let latency: Int = arrayData[indexOfFirstData + 3]
                        let supervision_timeout: Int = arrayData[indexOfFirstData + 4]
                        weakSelf.connectionParameters = SILIOPTestConnectionParameters(mtu_size: mtu_size,
                                                                                  pdu_size: pdu_size,
                                                                                  interval: interval,
                                                                                  latency: latency,
                                                                                  supervision_timeout: supervision_timeout)
                        weakSelf.setCompletedIfPossible()
                        return
                    }
                case weakSelf.modelNumberStringCharacteristic:
                    if let data = data, let boardName = String(data: data, encoding: .utf8) {
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
        invalidateObservableTokens()
        state.value = .completed(firmwareInfo: firmwareInfo, connectionParameters: connectionParameters)
    }
    
    private func setFailed() {
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
