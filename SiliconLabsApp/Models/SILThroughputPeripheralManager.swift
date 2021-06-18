//
//  SILThroughputPeripheralManager.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 21.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum SILThroughputTestType {
    case indications
    case notifications
    case none
}

struct SILThroughputSubscriber {
    var subscriber: CBCentral?
    var connectedPeripheralUUID: String?
    var subscribeTo: [String: Bool] = [SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputIndications.uuid : false,
                                       SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputNotifications.uuid : false,
                                       SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.uuid : false]
    
    func isSubscribed() -> Bool {
        guard let subscriber = subscriber, connectedPeripheralUUID == subscriber.identifier.uuidString else {
            return false
        }
        
        for (_, characteristic) in subscribeTo.enumerated() {
            if !characteristic.value {
                return false
            }
        }
        
        return true
    }
}

protocol SILThroughputPeripheralManagerType {
    var state: SILObservable<CBManagerState> { get }
    var isSubscribed: SILObservable<Bool> { get }
    var throughputResult: SILObservable<SILThroughputResult> { get }
    
    func startAdveritising()
    func stopAdvertising()
    func setSubscriber(uuid: String)
    func setMtu(mtu: Int, for writeType: CBCharacteristicWriteType)
    func setConnectionInterval(in ms: Int)
    func startTest(type: SILThroughputTestType)
    func stopTest()
}

class SILThroughputPeripheralManager: NSObject, SILThroughputPeripheralManagerType, CBPeripheralManagerDelegate {
    var state: SILObservable<CBManagerState> = SILObservable(initialValue: .unknown)
    var isSubscribed: SILObservable<Bool> = SILObservable(initialValue: false)
    var throughputResult: SILObservable<SILThroughputResult> = SILObservable(initialValue: SILThroughputResult(sender: .none, testType: .none, valueInBits: 0))
    
    private var peripheralManager: CBPeripheralManager!
    private var subscriber: SILThroughputSubscriber = SILThroughputSubscriber()
    
    private var throughputService: CBMutableService?
    private var indicationCharacteristic: CBMutableCharacteristic?
    private var notificationCharacteristic: CBMutableCharacteristic?
    private var transmissionOnCharacteristic: CBMutableCharacteristic?
    
    private var connectionInterval: Int = -1
    private var mtuWriteResponse: Int = -1
    private var mtuWriteNoResponse: Int = -1
    private var writeToCharTimer: Timer?
    private var releaseTimer: Timer?
    private var throughputCountInBits = 0
    private var currentTestType = SILThroughputTestType.none
    
    private var checkIfEFRSubscribedTimer: Timer?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        throughputService = createThroughputService()
    }
    
    func startAdveritising() {
        if state.value == .poweredOn {
            debugPrint("START ADVERTISING!")
            peripheralManager.add(throughputService!)
            peripheralManager.startAdvertising(nil)
        }
    }
    
    func stopAdvertising() {
        if state.value == .poweredOn {
            debugPrint("DID STOP ADVERTISING!")
            peripheralManager.delegate = nil
            peripheralManager.stopAdvertising()
            peripheralManager.removeAllServices()
        }
        
        checkIfEFRSubscribedTimer?.invalidate()
    }
    
    func setSubscriber(uuid: String) {
        debugPrint("SUBSCRIBER SET TO \(uuid)")
        subscriber.connectedPeripheralUUID = uuid
        
        checkIfEFRSubscribedTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: { timer in
            timer.invalidate()
            
            self.isSubscribed.value = self.subscriber.isSubscribed()
        })
    }
    
    func setConnectionInterval(in ms: Int) {
        debugPrint("SET CONNECTION INTERVAL TO \(ms)")
        self.connectionInterval = ms
    }
    
    func setMtu(mtu: Int, for writeType: CBCharacteristicWriteType) {
        debugPrint("SET MTU TO \(mtu) for \(writeType.rawValue)")
        if writeType == .withResponse {
            self.mtuWriteResponse = mtu
        } else {
            self.mtuWriteNoResponse = mtu
        }
    }
    
    func startTest(type: SILThroughputTestType) {
        var dataSize = 0
        var characteristicToWrite = self.indicationCharacteristic!
        if type == .indications {
            debugPrint("START INDICATIONS TEST")
            characteristicToWrite = self.indicationCharacteristic!
            dataSize = self.mtuWriteNoResponse
        } else if type == .notifications {
            debugPrint("START NOTICATIONS TEST")
            characteristicToWrite = self.notificationCharacteristic!
            dataSize = self.mtuWriteResponse
        } else {
            return
        }
        
        self.peripheralManager.updateValue(SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.WriteValues.active, for: transmissionOnCharacteristic!, onSubscribedCentrals: nil)
        
        writeToCharTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(Double(connectionInterval) / 1000.0), repeats: true, block: { timer in
            self.peripheralManager.updateValue(Data(repeating: 0x00, count: dataSize), for: characteristicToWrite, onSubscribedCentrals: nil)
            self.throughputCountInBits += dataSize * 8
        })
        
        releaseTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { timer in
            debugPrint("RELEASE FROM PHONE \(self.throughputCountInBits)")
            self.throughputResult.value = SILThroughputResult(sender: .phoneToEFR, testType: type, valueInBits: self.throughputCountInBits * 5)
            self.throughputCountInBits = 0
        })
        
        throughputResult.value = SILThroughputResult(sender: .phoneToEFR, testType: type, valueInBits: 0)
    }

    func stopTest() {
        writeToCharTimer?.invalidate()
        releaseTimer?.invalidate()
        throughputCountInBits = 0
        throughputResult.value = SILThroughputResult(sender: .phoneToEFR, testType: .none, valueInBits: 0)
        
        self.peripheralManager.updateValue(SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.WriteValues.disable, for: transmissionOnCharacteristic!, onSubscribedCentrals: nil)
    }
    
    private func createThroughputService() -> CBMutableService {
        let service = CBMutableService(type: SILThroughputPeripheralGATTDatabase.ThroughputService.cbUUID, primary: true)
        
        indicationCharacteristic = CBMutableCharacteristic(type: SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputIndications.cbUUID,
                                                               properties: [.indicate],
                                                               value: nil,
                                                               permissions: .readable)
        notificationCharacteristic = CBMutableCharacteristic(type: SILThroughputPeripheralGATTDatabase.ThroughputService.ThroughputNotifications.cbUUID,
                                                                 properties: [.notify],
                                                                 value: nil,
                                                                 permissions: .readable)
        transmissionOnCharacteristic = CBMutableCharacteristic(type: SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.cbUUID,
                                                                  properties: [.write, .read, .notify],
                                                                  value: nil,
                                                                  permissions: [.readable, .writeable])
        
        let characteristics = [indicationCharacteristic!, notificationCharacteristic!, transmissionOnCharacteristic!]
        service.characteristics = characteristics
        
        return service
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        debugPrint("DID UPDATE STATE!")
        state.value = peripheral.state
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        debugPrint("DID START ADVERTISING!")
    }
        
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        debugPrint("DID ADD SERVICE!")
    }
        
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        debugPrint("DID RECEIVE READ!")
        peripheral.respond(to: request, withResult: .success)
    }
        
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        debugPrint("DID RECEIVE WRITE!")
        peripheral.respond(to: requests.first!, withResult: .success)
    }
        
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        debugPrint("DID SUBSCRIBE TO \(characteristic.uuid) BY \(central.identifier.uuidString)!")
        increaseThroughput(central: central)
        
        if self.subscriber.subscriber == nil {
            self.subscriber.subscriber = central
        }

        self.subscriber.subscribeTo[characteristic.uuid.uuidString] = true
    }
        
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        debugPrint("DID UNSUBSCRIBE FROM!")
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        debugPrint("OVERFLOW!!!!")
    }
    
    private func increaseThroughput(central: CBCentral) {
        peripheralManager.setDesiredConnectionLatency(.high, for: central)
    }
}
