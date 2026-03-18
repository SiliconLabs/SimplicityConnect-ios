//
//  SILSmartLockViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 26/06/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation

enum SILSmartLockState {
    case lock //on
    case unlock //off
    case unknown //unknown
}

class SILSmartLockViewModel {
    var smartLockOnOffState: SILObservable<SILSmartLockState> = SILObservable(initialValue: .unknown)
    var smartLockPeripheralState: SILObservable<SILSmartLockPeripheralDelegateState> = SILObservable(initialValue: .unknown)
    
    private var deviceName: String
    private var disposeBag = SILObservableTokenBag()
    private var connectedPeripheral: CBPeripheral
    private var peripheralDelegate: SILSmartLockPeripheralDelegate
    
    init( connectedPeripheral: CBPeripheral, name: String) {
        //self.deviceConnector = deviceConnector
        self.connectedPeripheral = connectedPeripheral
        self.deviceName = name
        self.peripheralDelegate = SILSmartLockPeripheralDelegate(peripheral: self.connectedPeripheral, name: name)
    }
    
    public func viewDidLoad() {
        weak var weakSelf = self
        
        let peripheralStateSubscription = peripheralDelegate.newState().observe({ state in
            guard let weakSelf = weakSelf else {
                return
            }
            weakSelf.smartLockPeripheralState.value = state
        })
        disposeBag.add(token: peripheralStateSubscription)
        
        let reportButtonCharacteristicStateSubscription = peripheralDelegate.newLockStateCharacteristicState().observe({state in
            guard let weakSelf = weakSelf else {
                return
            }
            
            switch state {
            case .unknown:
                break
            case .updateValue(let value):
                if value.count > 0 {
                    debugPrint(value[0])
                    debugPrint(value[1])
                    debugPrint(value[2])
                    if value[0] == 9 && value[1] == 1 && value[2] == 1 {
                        weakSelf.smartLockOnOffState.value = .lock
                        debugPrint(" = Lock BLE = ")
                    } else if value[0] == 9 && value[1] == 1 && value[2] == 0 {
                        weakSelf.smartLockOnOffState.value = .unlock
                        debugPrint(" = Unlock BLE = ")
                    } else if value[0] == 11 && value[1] == 1 && value[2] == 1 {
                        weakSelf.smartLockOnOffState.value = .lock
                        debugPrint(" = Lock BLE = ")
                    }else if value[0] == 11 && value[1] == 1 && value[2] == 0 {
                        weakSelf.smartLockOnOffState.value = .unlock
                        debugPrint("= Unlock BLE =")
                    }
                }
            }
        })
        disposeBag.add(token: reportButtonCharacteristicStateSubscription)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDisconnectNotification),
                                               name: .SILThunderboardDeviceDisconnect,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleBluetoothDisabledNotification),
                                               name: .SILThunderboardBluetoothDisabled,
                                               object: nil)
        
        self.peripheralDelegate.discoverSmartLockService()
    }
    
    @objc func handleDisconnectNotification() {
        debugPrint("Did disconnect peripheral")
        NotificationCenter.default.removeObserver(self)
        smartLockPeripheralState.value = .failure(reason: "Device disconnected")
    }
    
    @objc func handleBluetoothDisabledNotification() {
        debugPrint("Did disable Bluetooth")
        NotificationCenter.default.removeObserver(self)
        smartLockPeripheralState.value = .failure(reason: "Bluetooth disabled")
    }
        
    public func changeOnSmartLockState() {
        peripheralDelegate.writeOnValueToSmartLockCharacteristic()
    }
    
    public func changeOffSmartLockState() {
        peripheralDelegate.writeOffValueToSmartLockCharacteristic()
    }
    
    public func queryCurrentStatus() {
        peripheralDelegate.writeReadQueryValueToSmartLockCharacteristic()
    }
}
