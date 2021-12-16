//
//  SILMotionViewModel.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 21/09/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILMotionViewModel {
    var centralManager: SILCentralManager
    var connectedPeripheral: CBPeripheral
    
    var peripheralConnectionStatus: SILObservable<Bool> = SILObservable(initialValue: true)
    var bluetoothState: SILObservable<Bool> = SILObservable(initialValue: true)

    init(centralManager: SILCentralManager, connectedPeripheral: CBPeripheral) {
        self.centralManager = centralManager
        self.connectedPeripheral = connectedPeripheral
    }
    
    public func viewWillDisappear() {
        NotificationCenter.default.removeObserver(self)
        centralManager.disconnect(from: self.connectedPeripheral)
    }
    
    @objc private func didDisconnectPeripheral(notification: Notification) {
        peripheralConnectionStatus.value = false
    }
    
    @objc private func bluetoothIsDisabled(notification: Notification) {
        bluetoothState.value = false
    }
    
    func checkPeripheralName() -> String {
        return connectedPeripheral.name!
    }
}
