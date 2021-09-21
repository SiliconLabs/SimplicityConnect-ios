//
//  SILDiscoverFirmwareInfo.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

class SILDiscoverFirmwareInfo {
    enum State {
        case initiated
        case running
        case failed
        case completed(stackVersion: String)
    }
    
    var state: SILObservable<State> = SILObservable(initialValue: .initiated)
    
    private var peripheral: CBPeripheral!
    private var peripheralDelegate: SILIOPTesterPeripheralDelegate!
    private var iopCentralManager: SILIOPTesterCentralManager!
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    
    private var iopTestVersionCharacteristic = SILIOPPeripheral.SILIOPTest.IOPTestVersion.cbUUID
    private var iopTestService = SILIOPPeripheral.SILIOPTest.cbUUID
 
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.peripheralDelegate = parameters["peripheralDelegate"] as? SILIOPTesterPeripheralDelegate
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
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
        
        peripheralDelegate.discoverCharacteristics(characteristics: [iopTestVersionCharacteristic], for: iopTestService)
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
                break

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
                    if characteristic.uuid == weakSelf.iopTestVersionCharacteristic {
                        weakSelf.peripheralDelegate.readCharacteristic(characteristic: characteristic)
                        return
                    }
                }
                
                weakSelf.invalidateObservableTokens()
                weakSelf.state.value = .failed
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestVersionCharacteristic,
                   let stackVersion = weakSelf.parseStackVersion(data: data) {
                    weakSelf.invalidateObservableTokens()
                    weakSelf.state.value = .completed(stackVersion: stackVersion)
                    return
                }
    
                weakSelf.invalidateObservableTokens()
                weakSelf.state.value = .failed
                
            case .unknown:
                break
                
            default:
                weakSelf.invalidateObservableTokens()
                weakSelf.state.value = .failed
                break
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
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
    
    private func parseStackVersion(data: Data?) -> String? {
        guard let data = data else { return nil }
        
        let simpleVersioningLength = 1
        let semanticVersioningLength = 8
        
        if data.count == simpleVersioningLength {
            return parseSimpleVersioning(data: data)
        } else if data.count == semanticVersioningLength {
            return parseSemanticVersioningLittleEndian(data: data)
        } else {
            return nil;
        }
    }
    
    private func parseSimpleVersioning(data: Data) -> String {
        return data.hexString
    }
    
    private func parseSemanticVersioningLittleEndian(data: Data) -> String {
        let major = data.subdata(in: 0..<2).integerValueFromData()
        let minor = data.subdata(in: 2..<4).integerValueFromData()
        let patch = data.subdata(in: 4..<6).integerValueFromData()
        
        let parsedSemanticVersioning = "\(major).\(minor).\(patch)"
        
        return parsedSemanticVersioning
    }
}
