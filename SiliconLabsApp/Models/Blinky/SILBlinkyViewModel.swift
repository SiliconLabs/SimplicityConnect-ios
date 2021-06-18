//
//  SILBlinkyViewModel.swift
//  BlueGecko
//
//  Created by Vasyl Haievyi on 08/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILBlinkyLightState {
    case On
    case Off
}

enum SILBlinkyReportButtonState {
    case Pressed
    case Released
}

class SILBlinkyViewModel {
    var LightState: SILObservable<SILBlinkyLightState> = SILObservable(initialValue: .Off)
    var ReportButtonState: SILObservable<SILBlinkyReportButtonState> = SILObservable(initialValue: .Released)
    var BlinkyState: SILObservable<SILBlinkyPeripheralDelegateState> = SILObservable(initialValue: .unknown)
    
    private var disposeBag = SILObservableTokenBag()

    private var centralManager: SILCentralManager
    private var connectedPeripheral: CBPeripheral
    private var peripheralDelegate: SILBlinkyPeripheralDelegate

    init(centralManager: SILCentralManager, connectedPeripheral: CBPeripheral) {
            self.centralManager = centralManager
            self.connectedPeripheral = connectedPeripheral
            self.peripheralDelegate = SILBlinkyPeripheralDelegate(peripheral: self.connectedPeripheral)
    }
    
    public func viewDidLoad() {
        weak var weakSelf = self
        
        let peripheralStateSubscription = peripheralDelegate.newState().observe({ state in
            guard let weakSelf = weakSelf else {
                return
            }
                weakSelf.BlinkyState.value = state
        })
        disposeBag.add(token: peripheralStateSubscription)
        
        let lightCharacteristicStateSubscription = peripheralDelegate.newLightCharacteristicState().observe({state in
            guard let weakSelf = weakSelf else {
                return
            }
            
            switch state {
            case .unknown:
                break
            case .updateValue(let value):
                switch value {
                case SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.WriteValues.TurnOn:
                    weakSelf.LightState.value = .On
                case SILBlinkyPeripheralGATTDatabase.BlinkyService.LightCharacteristic.WriteValues.TurnOff:
                    weakSelf.LightState.value = .Off
                default:
                    return
                }
            }
        })
        disposeBag.add(token: lightCharacteristicStateSubscription)
        
        let reportButtonCharacteristicStateSubscription = peripheralDelegate.newReportButtonCharacteristicState().observe({state in
            guard let weakSelf = weakSelf else {
                return
            }
            
            switch state {
            case .unknown:
                break
            case .updateValue(let value):
                switch value {
                case SILBlinkyPeripheralGATTDatabase.BlinkyService.ReportButtonCharacteristic.ReadValues.Pressed:
                    weakSelf.ReportButtonState.value = .Pressed
                case SILBlinkyPeripheralGATTDatabase.BlinkyService.ReportButtonCharacteristic.ReadValues.Released:
                    weakSelf.ReportButtonState.value = .Released
                default:
                    return
                }
            }
        })
        disposeBag.add(token: reportButtonCharacteristicStateSubscription)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleCentralManagerDisconnectNotification),
                                               name: NSNotification.Name.SILCentralManagerDidDisconnectPeripheral,
                                               object: self.centralManager)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleCentralManagerBluetoothDisabledNotification),
                                               name:NSNotification.Name.SILCentralManagerBluetoothDisabled ,
                                               object: self.centralManager)
        
        self.peripheralDelegate.discoverBlinkyService()
    }
    
    public func viewWillDisappear() {
        NotificationCenter.default.removeObserver(self)
        centralManager.disconnect(from: self.connectedPeripheral)
    }
    
    @objc func handleCentralManagerDisconnectNotification() {
        debugPrint("Did disconnect peripheral")
        
        NotificationCenter.default.removeObserver(self)
        BlinkyState.value = .failure(reason: "Device disconnected")
    }
    
    @objc func handleCentralManagerBluetoothDisabledNotification() {
        debugPrint("Did disable Bluetooth")
        
        NotificationCenter.default.removeObserver(self)
        BlinkyState.value = .failure(reason: "Bluetooth disabled")
    }
    
    public func changeLightState() {
        switch LightState.value {
        case .On:
            LightState.value = .Off
            peripheralDelegate.writeOffValueToLightCharacteristic()
        case .Off:
            LightState.value = .On
            peripheralDelegate.writeOnValueToLightCharacteristic()
        }
    }
}
