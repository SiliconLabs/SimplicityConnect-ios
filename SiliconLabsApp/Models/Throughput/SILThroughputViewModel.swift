//
//  SILThroughputViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 26.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILThroughputTestState {
    case initiatedCorrectly
    case noSubscriber
    case invalidCommunicationWithEFR
    case none
}

enum SILThroughputTestDirection {
    case phoneToEFR
    case EFRToPhone
    case none
}

struct SILThroughputResult {
    var sender: SILThroughputTestDirection
    var testType: SILThroughputTestType
    var valueInBits: Int
}

enum SILThroughputTestButtonState {
    case phoneToEFRTest
    case EFRToPhoneTest
    case readyForTesting
}

enum SILThroughputPhoneTestMode {
    case indicationsSelected
    case notificationsSelected
}

protocol SILThroughputViewModelType {
    var phyStatus: SILObservable<PHY> { get }
    var connectionIntervalStatus: SILObservable<Double> { get }
    var slaveLatencyStatus: SILObservable<Double> { get }
    var supervisionTimeoutStatus: SILObservable<Double> { get }
    var mtuStatus: SILObservable<Int> { get }
    var pduStatus: SILObservable<Int> { get }
    var peripheralConnectionStatus: SILObservable<Bool> { get }
    var bluetoothState: SILObservable<Bool> { get }
    var testState: SILObservable<SILThroughputTestState> { get }
    var testResult: SILObservable<SILThroughputResult> { get }
    var testButtonState: SILObservable<SILThroughputTestButtonState> { get }
    var phoneTestModeSelected: SILObservable<SILThroughputPhoneTestMode> { get }
    
    func changeTestState()
    func changePhoneTestModeSelection(newSelection: SILThroughputPhoneTestMode)
    func viewDidLoad()
    func viewWillDisappear()
}

class SILThroughputViewModel: SILThroughputViewModelType {
    var phyStatus: SILObservable<PHY> = SILObservable(initialValue: ._unknown)
    var connectionIntervalStatus: SILObservable<Double> = SILObservable(initialValue: -1.0)
    var slaveLatencyStatus: SILObservable<Double> = SILObservable(initialValue: -1.0)
    var supervisionTimeoutStatus: SILObservable<Double> = SILObservable(initialValue: -1.0)
    var mtuStatus: SILObservable<Int> = SILObservable(initialValue: -1)
    var pduStatus: SILObservable<Int> = SILObservable(initialValue: -1)
    var peripheralConnectionStatus: SILObservable<Bool> = SILObservable(initialValue: true)
    var bluetoothState: SILObservable<Bool> = SILObservable(initialValue: true)
    var testState: SILObservable<SILThroughputTestState> = SILObservable(initialValue: .none)
    var testResult: SILObservable<SILThroughputResult> = SILObservable(initialValue: SILThroughputResult(sender: .none, testType: .none, valueInBits: 0))
    var testButtonState: SILObservable<SILThroughputTestButtonState> = SILObservable(initialValue: .readyForTesting)
    var phoneTestModeSelected: SILObservable<SILThroughputPhoneTestMode> = SILObservable(initialValue: .indicationsSelected)
    
    private var peripheralManager: SILThroughputPeripheralManager
    private var centralManager: SILCentralManager
    private var connectedPeripheral: CBPeripheral
    private var peripheralDelegate: SILThroughputPeripheralDelegate
    
    private var peripheralDelegateSubscription: SILObservableToken?
    private var peripheralManagerSubscription: SILObservableToken?
    private var disposeBag = SILObservableTokenBag()
    
    private var isSubscribed: Bool = false
    
    
    init(peripheralManager: SILThroughputPeripheralManager, centralManager: SILCentralManager, connectedPeripheral: CBPeripheral) {
        self.peripheralManager = peripheralManager
        self.centralManager = centralManager
        self.connectedPeripheral = connectedPeripheral
        self.peripheralDelegate = SILThroughputPeripheralDelegate(peripheral: self.connectedPeripheral)
        self.peripheralManager.setSubscriber(uuid: connectedPeripheral.identifier.uuidString)
    }
    
    func viewDidLoad() {
        weak var weakSelf = self
        peripheralDelegateSubscription = peripheralDelegate.newState().observe({ state in
            guard let weakSelf = weakSelf else { return }
            switch state {
            case .initiated:
                weakSelf.peripheralDelegateSubscription?.invalidate()
                weakSelf.readConnectionParameters()
                weakSelf.peripheralManager.setMtu(mtu: weakSelf.peripheralDelegate.getMTU(for: .withResponse), for: .withResponse)
                weakSelf.peripheralManager.setMtu(mtu: weakSelf.peripheralDelegate.getMTU(for: .withoutResponse), for: .withoutResponse)
                
                if weakSelf.isSubscribed == true {
                    weakSelf.testState.value = .initiatedCorrectly
                } else {
                    weakSelf.testState.value = .noSubscriber
                }

            case let .failure(reason: reason):
                debugPrint("ERROR \(reason)")
                weakSelf.testState.value = .invalidCommunicationWithEFR
                
            default:
                return
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription!)
        
        let peripheralManagerIsSubscribed = peripheralManager.isSubscribed.observe( { value in
            guard let weakSelf = weakSelf else { return }
            debugPrint("EFR \(value) SUBSCRIBED!")
            weakSelf.isSubscribed = value
        })
        disposeBag.add(token: peripheralManagerIsSubscribed)
        
        let peripheralDelegateThroughputResult = peripheralDelegate.throughputResult.observe( { value in
            guard let weakSelf = weakSelf else { return }
            weakSelf.testResult.value = value
            if value.testType == .indications {
                weakSelf.changePhoneTestModeSelection(newSelection: .indicationsSelected)
            } else if value.testType == .notifications {
                weakSelf.changePhoneTestModeSelection(newSelection: .notificationsSelected)
            }
        })
        disposeBag.add(token: peripheralDelegateThroughputResult)
        
        let peripheralManagerThroughputResult = peripheralManager.throughputResult.observe( { value in
            guard let weakSelf = weakSelf else { return }
            weakSelf.testResult.value = value
            if value.testType == .indications {
                weakSelf.changePhoneTestModeSelection(newSelection: .indicationsSelected)
            } else if value.testType == .notifications {
                weakSelf.changePhoneTestModeSelection(newSelection: .notificationsSelected)
            }
        })
        disposeBag.add(token: peripheralManagerThroughputResult)
        
        let isTestActive = peripheralDelegate.currentTestDirection.observe({ currentTestDirection in
            guard let weakSelf = weakSelf else { return }
            switch currentTestDirection {
            case .EFRToPhone:
                debugPrint("TEST BUTTON STATE => EFR TO PHONE TEST")
                weakSelf.testButtonState.value = .EFRToPhoneTest
                
            case .phoneToEFR:
                debugPrint("TEST BUTTON STATE => PHONE TO EFR TEST")
                weakSelf.testButtonState.value = .phoneToEFRTest
                
            case .none:
                debugPrint("TEST BUTTON STATE => READY FOR TESTING")
                weakSelf.testButtonState.value = .readyForTesting
                weakSelf.peripheralManager.stopTest()
            }
        })
        disposeBag.add(token: isTestActive)
        
        subscribeToCentralManagerEvents()
        
        peripheralDelegate.discoverThroughputGATTServices()
    }
    
    func viewWillDisappear() {
        unregisterNotifications()
        peripheralDelegate.stopTesting()
        peripheralManager.stopTest()
        peripheralManager.stopAdvertising()
    }
    
    private func readConnectionParameters() {
        weak var weakSelf = self
        peripheralDelegateSubscription = peripheralDelegate.newState().observe( { state in
            guard let weakSelf = weakSelf else { return }
            switch state {
            case let .updateValue(data: data, for: characteristic):
                weakSelf.decodeConnectionParameter(data: data, characteristic: characteristic)
                
            default:
                return
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription!)
        
        peripheralDelegate.readConnectionParameters()
    }
    
    private func decodeConnectionParameter(data: Data, characteristic: CBCharacteristic) {
        let decoder = SILThroughputConnectionParametersDecoder()
        let decodedValue = decoder.decode(data: data, characterisitc: characteristic.uuid)
        
        switch decodedValue {
        case let .phy(phy: phy):
            self.phyStatus.value = phy
            
        case let .connectionInterval(value: value):
            self.connectionIntervalStatus.value = value
            self.peripheralManager.setConnectionInterval(in: Int(self.connectionIntervalStatus.value))
            
        case let .slaveLatency(value: value):
            self.slaveLatencyStatus.value = value
        
        case let .supervisionTimeout(value: value):
            self.supervisionTimeoutStatus.value = value
        
        case let .mtu(value: value):
            self.mtuStatus.value = value
            
        case let .pdu(value: value):
            self.pduStatus.value = value
            
        default:
            break
        }
    }
    
    func changeTestState() {
        if testButtonState.value == .readyForTesting {
            peripheralDelegate.phoneToEFRStatusChanged(isTesting: true)
            
            if phoneTestModeSelected.value == .indicationsSelected {
                peripheralManager.startTest(type: .indications)
            } else {
                peripheralManager.startTest(type: .notifications)
            }
        } else if testButtonState.value == .phoneToEFRTest {
            peripheralDelegate.phoneToEFRStatusChanged(isTesting: false)
            peripheralManager.stopTest()
        }
    }
    
    func changePhoneTestModeSelection(newSelection: SILThroughputPhoneTestMode) {
        if newSelection != phoneTestModeSelected.value {
            phoneTestModeSelected.value = newSelection
        }
    }
    
    private func subscribeToCentralManagerEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectPeripheral(notification:)), name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bluetoothIsDisabled(notification:)), name: .SILCentralManagerBluetoothDisabled, object: nil)
    }

    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerBluetoothDisabled, object: nil)
    }
    
    // MARK: - Notifcation Methods

    @objc private func didDisconnectPeripheral(notification: Notification) {
        peripheralConnectionStatus.value = false
    }
    
    @objc private func bluetoothIsDisabled(notification: Notification) {
        bluetoothState.value = false
    }
}
