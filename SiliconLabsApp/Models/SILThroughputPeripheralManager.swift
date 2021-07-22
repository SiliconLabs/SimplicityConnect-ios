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
    private var writeToCharTimer: Timer?
    private var releaseTimer: Timer?
    private var throughputCountInBits = 0
    private var currentTestType = SILThroughputTestType.none
    
    private var packetNumber = 1
    private var dataSize = 0
    private var checkIfEFRSubscribedTimer: Timer?
    private var packetSentCount = 0
    
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
        
        let timeForEFRToSubscribeCharacteristics = TimeInterval(2.5)
        checkIfEFRSubscribedTimer = Timer.scheduledTimer(withTimeInterval: timeForEFRToSubscribeCharacteristics, repeats: false, block: { timer in
            timer.invalidate()
            
            self.isSubscribed.value = self.subscriber.isSubscribed()
        })
    }
    
    func setConnectionInterval(in ms: Int) {
        debugPrint("SET CONNECTION INTERVAL TO \(ms)")
        self.connectionInterval = ms
    }
    
    // Notifications can be sent without waiting for response, indications can be sent one per 2 * interval
    // More information here https://www.silabs.com/community/wireless/bluetooth/knowledge-base.entry.html/2015/08/06/throughput_with_blue-Wybp
    func startTest(type: SILThroughputTestType) {
        var characteristicToWrite = self.indicationCharacteristic!
        var timeInterval: TimeInterval
        dataSize = subscriber.subscriber!.maximumUpdateValueLength
        if type == .indications {
            characteristicToWrite = self.indicationCharacteristic!
            timeInterval = TimeInterval(Double(self.connectionInterval * 2) / 1000.0)
            debugPrint("START INDICATIONS TEST WITH DATA SIZE \(dataSize)")
        } else if type == .notifications {
            characteristicToWrite = self.notificationCharacteristic!
            timeInterval = TimeInterval(0.005)
            debugPrint("START NOTIFICATIONS TEST WITH DATA SIZE \(dataSize)")
        } else {
            return
        }

        self.peripheralManager.updateValue(SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.WriteValues.active, for: transmissionOnCharacteristic!, onSubscribedCentrals: nil)
        
        writeToCharTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { timer in
            var dataArray = [UInt8]()
            dataArray.append(UInt8(self.packetNumber))
            
            for i in 0..<self.dataSize - 1 {
                dataArray.append(self.appendNextLetter(i: i))
            }
                
            if self.peripheralManager.updateValue(Data(dataArray), for: characteristicToWrite, onSubscribedCentrals: nil) {
                debugPrint("UPDATE - SENT")
                self.throughputCountInBits += self.dataSize * 8
                self.packetNumber = (self.packetNumber + 1) % 100
                self.packetSentCount += 1
            } else {
                debugPrint("UPDATE - NOT SENT")
            }
        })
        
        let timeBetweenUIUpdates = TimeInterval(0.2)
        releaseTimer = Timer.scheduledTimer(withTimeInterval: timeBetweenUIUpdates, repeats: true, block: { timer in
            debugPrint("RELEASE FROM PHONE \(self.throughputCountInBits)")
            self.throughputResult.value = SILThroughputResult(sender: .phoneToEFR, testType: type, valueInBits: self.throughputCountInBits * 5)
            self.throughputCountInBits = 0
        })
        
        throughputResult.value = SILThroughputResult(sender: .phoneToEFR, testType: type, valueInBits: 0)
    }
    
    func appendNextLetter(i: Int) -> UInt8 {
        return UInt8(97 + (i - 1) % 26)
    }

    func stopTest() {
        writeToCharTimer?.invalidate()
        releaseTimer?.invalidate()
        throughputCountInBits = 0
        packetNumber = 1
        dataSize = 0
        throughputResult.value = SILThroughputResult(sender: .phoneToEFR, testType: .none, valueInBits: 0)
        
        debugPrint("CNT: \(self.packetSentCount)")
        self.packetSentCount = 0
        
        let timeToEnsureThatDisableMessageIsSentAfterLastDataPacket = TimeInterval(0.2)
        _ = Timer.scheduledTimer(withTimeInterval: timeToEnsureThatDisableMessageIsSentAfterLastDataPacket, repeats: false, block: { timer in
            timer.invalidate()
            debugPrint("SEND DISABLE TEST SIGNAL")
            self.peripheralManager.updateValue(SILThroughputPeripheralGATTDatabase.ThroughputService.TransmissionOn.WriteValues.disable, for: self.transmissionOnCharacteristic!, onSubscribedCentrals: nil)
        })
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
