//
//  SILDiscoverRFUFeatures.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILDiscoverRFUFeatures {
    enum State {
        case initiated
        case running
        case failed
        case completed(firmwareInfo: SILIOPTestFirmwareInfo, connectionParameters: SILIOPTestConnectionParameters)
    }
    
    var state: SILObservable<State> = SILObservable(initialValue: .initiated)
    
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILIOPTesterPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var stackVersion: String!
    private var deviceName: String!
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var iopTestFeaturesRFUCharacteristic = SILIOPPeripheral.SILIOPTest.IOPTestFeaturesRFU.cbUUID
    private var iopTestService = SILIOPPeripheral.SILIOPTest.cbUUID
 
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.peripheralDelegate = parameters["peripheralDelegate"] as? SILIOPTesterPeripheralDelegate
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
            self.invalidateObservableTokens()
            self.state.value = .failed
            return
        }
        
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestFeaturesRFUCharacteristic], for: iopTestService)
    }
    
    private func subscribeToCentralManager() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                debugPrint("Peripheral disconnected with \(String(describing: error?.localizedDescription))")
                weakSelf.invalidateObservableTokens()
                weakSelf.state.value = .failed
            
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    weakSelf.invalidateObservableTokens()
                    weakSelf.state.value = .failed
                }
                
            case .unknown:
                break
            
            default:
                weakSelf.invalidateObservableTokens()
                weakSelf.state.value = .failed
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
                for characteristic in characteristics {
                    if characteristic.uuid == weakSelf.iopTestFeaturesRFUCharacteristic {
                        weakSelf.peripheralDelegate.readCharacteristic(characteristic: characteristic)
                        return
                    }
                }
                
                weakSelf.invalidateObservableTokens()
                weakSelf.state.value = .failed
               
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestFeaturesRFUCharacteristic, let byteData =  data?.bytes {
                    let arrayData = weakSelf.getFirmwareData(bytes: byteData)
                    let ic_name: Int = arrayData[0]
                    var firmware: SILIOPFirmware = .unknown
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
                    }
                    let pdu_size: Int = arrayData[2]
                    let mtu_size: Int = arrayData[1]
                    let interval: Int = Int(Double(arrayData[3]) * 1.25)
                    let latency: Int = arrayData[4]
                    let supervision_timeout: Int = arrayData[5]
                    
                    let firmwareInfo = SILIOPTestFirmwareInfo(version: weakSelf.stackVersion,
                                                              name: weakSelf.deviceName,
                                                              firmware: firmware)
                    let connectionParameters = SILIOPTestConnectionParameters(mtu_size: mtu_size,
                                                                              pdu_size: pdu_size,
                                                                              interval: interval,
                                                                              latency: latency,
                                                                              supervision_timeout: supervision_timeout)
                    
                    weakSelf.invalidateObservableTokens()
                    weakSelf.state.value = .completed(firmwareInfo: firmwareInfo,
                                                      connectionParameters: connectionParameters)
                    return
                }
                
                weakSelf.invalidateObservableTokens()
                weakSelf.state.value = .failed
            
            case .unknown:
                break
                
            default:
                weakSelf.invalidateObservableTokens()
                weakSelf.state.value = .failed
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
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
