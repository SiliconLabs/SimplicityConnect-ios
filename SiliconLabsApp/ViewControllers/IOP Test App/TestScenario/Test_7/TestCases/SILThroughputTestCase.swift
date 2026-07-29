//
//  SILThroughputTestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILThroughputTestCase: SILTestCase, SILTestCaseTimeout {
    private let log = IOPLog()
    var testResult: SILObservable<SILTestResult?> = SILObservable(initialValue: nil)
    var testID: String = "7.1"
    var testName: String = "Throughput-GATT Notification."

    var timeoutMS: Int64 = 5500
    var startTime: Int64?
    var stopTime: Int64?
        
    private var discoveredPeripheral: SILDiscoveredPeripheral!
    private var iopCentralManager: SILIOPTesterCentralManager!
    private var peripheral: CBPeripheral!
    private var mtu_size: Int?
    private var pdu_size: Int?
    private var interval: Double?
    private var phy: Int?
    private let PHY = (Unknown: 0, _1M: 1, _2M: 2)
    
    private var peripheralDelegate: SILPeripheralDelegate!
    
    var observableTokens: [SILObservableToken?] = []
    private var disposeBag = SILObservableTokenBag()
    private var throughputStopWorkItem: DispatchWorkItem?
    private var liveThroughputTimer: Timer?
    private var throughputMeasurementStart: Date?
    private var maxMeasuredThroughputKbps: Double = 0
    
    private var iopTestPhase3ThroughputGATT = SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Throughput_GATT.cbUUID
    private var iopTestPhase3Control = SILIOPPeripheral.SILIOPTestPhase3.IOPTest_Phase3_Control.cbUUID
    private var iopTestPhase3ThroughputCharacteristic: CBCharacteristic!
    private var iopTestPhase3Service  = SILIOPPeripheral.SILIOPTestPhase3.cbUUID
    
    private let InitialValue = "0x020000"
    private var countCharacteristicThroughput = 0
    private var connectionTimeout: Timer?
    
    init() { }
    
    func injectParameters(parameters: Dictionary<String, Any>) {
        self.iopCentralManager = parameters["iopCentralManager"] as? SILIOPTesterCentralManager
        self.discoveredPeripheral = parameters["discoveredPeripheral"] as? SILDiscoveredPeripheral
        self.peripheral = parameters["peripheral"] as? CBPeripheral
        self.mtu_size = parameters["mtu_size"] as? Int
        self.pdu_size = parameters["pdu_size"] as? Int
        self.interval = parameters["interval"] as? Double
        self.phy = parameters["phy"] as? Int
    }
    
    func performTestCase() {
        
        guard let iopCentralManager = iopCentralManager else {
            self.publishTestResult(passed: false, description: "IOP central manager is nil.")
            log.step(source: "SILThroughputTestCase", testID: testID, action: "Cannot start throughput test", detail: "IOP central manager is nil.")
            postThroughputDeferredContinueWithoutPopup()
            return
        }
        
        guard iopCentralManager.bluetoothState else {
            self.publishTestResult(passed: false, description: "Bluetooth disabled!")
            log.step(source: "SILThroughputTestCase", testID: testID, action: "Cannot start throughput test", detail: "Bluetooth is disabled.")
            postThroughputDeferredContinueWithoutPopup()
            return
        }
        
        guard let peripheral = peripheral else {
            self.publishTestResult(passed: false, description: "Peripheral is nil.")
            log.step(source: "SILThroughputTestCase", testID: testID, action: "Cannot start throughput test", detail: "Peripheral is nil before connection check.")
            postThroughputDeferredContinueWithoutPopup()
            return
        }

//        guard let _ = discoveredPeripheral else {
//            self.publishTestResult(passed: false, description: "Discovered peripheral is nil.")
//            IOPLog().iopLogSwiftFunction(message: "Discovered peripheral is nil.")
//            postThroughputDeferredContinueWithoutPopup()
//            return
//        }
//        
//        guard let _ = peripheral else {
//            self.publishTestResult(passed: false, description: "Peripheral is nil.")
//            IOPLog().iopLogSwiftFunction(message: "Peripheral is nil.")
//            postThroughputDeferredContinueWithoutPopup()
//            return
//        }
//
//        publishStartTestEvent()
//        testThroughput()
        
        if peripheral.state == .connected {
            self.startThroughPut()
        } else {
            tryConnection(attempt: 1)
        }
        
    }
    
   private func startThroughPut() {
        guard let _ = discoveredPeripheral else {
            self.publishTestResult(passed: false, description: "Discovered peripheral is nil.")
            log.step(source: "SILThroughputTestCase", testID: testID, action: "Cannot start throughput test", detail: "Discovered peripheral is nil.")
            postThroughputDeferredContinueWithoutPopup()
            return
        }
        
        guard let _ = peripheral else {
            self.publishTestResult(passed: false, description: "Peripheral is nil.")
            log.step(source: "SILThroughputTestCase", testID: testID, action: "Cannot start throughput test", detail: "Peripheral is nil.")
            postThroughputDeferredContinueWithoutPopup()
            return
        }

        publishStartTestEvent()
        log.step(source: "SILThroughputTestCase",
                 testID: testID,
                 action: "Preparing throughput measurement",
                 detail: "service=\(iopTestPhase3Service.uuidString) | char=\(iopTestPhase3ThroughputGATT.uuidString) | control=\(iopTestPhase3Control.uuidString) | timeout=\(timeoutMS) ms | mtu=\(mtu_size.map(String.init) ?? "unknown") | pdu=\(pdu_size.map(String.init) ?? "unknown") | interval=\(interval.map { String(format: "%.1f", $0) } ?? "unknown") ms | phy=\(phy.map(String.init) ?? "unknown")")
        testThroughput()
    }
    
    func tryConnection(attempt: Int) {
        let maxAttempts = 3
        if attempt > maxAttempts {
            publishTestResult(passed: false, description: "Failed to reconnect peripheral before throughput test.")
            log.step(source: "SILThroughputTestCase", testID: testID, action: "Reconnect failed before throughput test", detail: "Exceeded \(maxAttempts) attempts.")
            postThroughputDeferredContinueWithoutPopup()
            return
        }
        if self.peripheral?.state == .connected {
            startThroughPut()
            return
        }
        
        log.retry(source: "SILThroughputTestCase",
                  testID: testID,
                  attempt: attempt,
                  maxAttempts: maxAttempts,
                  action: "Reconnect peripheral before throughput measurement",
                  timeoutDescription: "reconnect scan")
        reconnectToDevice(attempt: attempt, maxAttempts: maxAttempts)
    }
    
      private func reconnectToDevice(attempt: Int, maxAttempts: Int) {
          guard let reconnectPeripheral = self.peripheral else {
              publishTestResult(passed: false, description: "Cannot reconnect peripheral. Peripheral is nil.")
              log.step(source: "SILThroughputTestCase", testID: testID, action: "Reconnect aborted", detail: "Peripheral is nil.")
              postThroughputDeferredContinueWithoutPopup()
              return
          }
          
          guard let iopCentralManager = self.iopCentralManager else {
              publishTestResult(passed: false, description: "Cannot reconnect peripheral. IOP central manager is nil.")
              log.step(source: "SILThroughputTestCase", testID: testID, action: "Reconnect aborted", detail: "IOP central manager is nil.")
              postThroughputDeferredContinueWithoutPopup()
              return
          }
          
          guard let reconnectName = reconnectPeripheralName() else {
              publishTestResult(passed: false, description: "Cannot reconnect peripheral. Device name is unavailable.")
              log.step(source: "SILThroughputTestCase", testID: testID, action: "Reconnect aborted", detail: "Device name is unavailable.")
              postThroughputDeferredContinueWithoutPopup()
              return
          }
          
          weak var weakSelf = self
          let reconnectManager = SILIOPTestReconnectManager(with: reconnectPeripheral, iopCentralManager: iopCentralManager)
          let reconnectManagerSubscription = reconnectManager.reconnectStatus.observe { reconnectStatus in
              guard let weakSelf = weakSelf else { return }
              switch reconnectStatus {
              case let .success(discoveredPeripheral: discoveredPeripheral, stackVersion: stackVersion):
                  weakSelf.discoveredPeripheral = discoveredPeripheral
                  weakSelf.peripheral = discoveredPeripheral?.peripheral
                  weakSelf.invalidateObservableTokens()
                  weakSelf.log.connection(source: "SILThroughputTestCase",
                                          testID: weakSelf.testID,
                                          action: "Reconnect succeeded before throughput test",
                                          peripheralName: discoveredPeripheral?.advertisedLocalName,
                                          identifier: discoveredPeripheral?.peripheral?.identifier)
                  weakSelf.log.step(source: "SILThroughputTestCase",
                                    testID: weakSelf.testID,
                                    action: "Reconnect context ready",
                                    detail: "Firmware version=\(stackVersion)")
                  weakSelf.startThroughPut()

              case let .failure(reason: reason):
                  weakSelf.invalidateObservableTokens()
                  weakSelf.log.step(source: "SILThroughputTestCase",
                                    testID: weakSelf.testID,
                                    action: "Reconnect attempt failed before throughput test",
                                    detail: reason)
                  weakSelf.tryConnection(attempt: attempt + 1)
                  
              case .unknown:
                  break
              }
          }
          self.disposeBag.add(token: reconnectManagerSubscription)
          observableTokens.append(reconnectManagerSubscription)
          reconnectManager.reconnectToDevice(withName: reconnectName)
      }
      
      private func reconnectPeripheralName() -> String? {
          
          if let otaUpdatedName = UserDefaults.standard.string(forKey: "deviceNameAfterOtaUpdate"), !otaUpdatedName.isEmpty {
              return otaUpdatedName
          }
          
          if let advertisedName = discoveredPeripheral?.advertisedLocalName, !advertisedName.isEmpty {
              return advertisedName
          }
          
          if let peripheralName = peripheral?.name, !peripheralName.isEmpty {
              return peripheralName
          }
          
          return nil
      }
    
    
    private func subscribeToCentralManager() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                weakSelf.log.connection(source: "SILThroughputTestCase",
                                        testID: weakSelf.testID,
                                        action: "Throughput test disconnected",
                                        peripheralName: weakSelf.peripheral?.name,
                                        identifier: weakSelf.peripheral?.identifier,
                                        error: error)
                weakSelf.publishTestResult(passed: false, description: "Peripheral was disconnected with \(String(describing: error?.localizedDescription)).")
                weakSelf.postThroughputDeferredContinueWithoutPopup()
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    weakSelf.log.step(source: "SILThroughputTestCase", testID: weakSelf.testID, action: "Throughput test interrupted", detail: "Bluetooth was disabled.")
                    weakSelf.publishTestResult(passed: false, description: "Bluetooth disabled.")
                    weakSelf.postThroughputDeferredContinueWithoutPopup()
                }
                
            case .unknown:
                break
            
            default:
                weakSelf.publishTestResult(passed: false, description: "Unknown failure from central manager.")
                weakSelf.log.step(source: "SILThroughputTestCase", testID: weakSelf.testID, action: "Throughput central manager failure", detail: "Received an unexpected central manager status.")
                weakSelf.postThroughputDeferredContinueWithoutPopup()
            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func testThroughput() {
        countCharacteristicThroughput = 0
        throughputMeasurementStart = nil
        maxMeasuredThroughputKbps = 0
        liveThroughputTimer?.invalidate()
        liveThroughputTimer = nil
        self.peripheralDelegate = SILPeripheralDelegate(peripheral: self.peripheral)
        
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForServices(services):
                guard let iopTestPhase3Service = services.first(where: { service in service.uuid == weakSelf.iopTestPhase3Service }) else {
                    weakSelf.publishTestResult(passed: false, description: "Service Test Phase 3 didn't found.")
                    weakSelf.log.gatt(source: "SILThroughputTestCase",
                                      testID: weakSelf.testID,
                                      operation: "Discover throughput service",
                                      serviceUUID: weakSelf.iopTestPhase3Service,
                                      outcome: "Phase 3 service not found on peripheral")
                    weakSelf.postThroughputDeferredContinueWithoutPopup()
                    return
                }
                weakSelf.log.gatt(source: "SILThroughputTestCase",
                                  testID: weakSelf.testID,
                                  operation: "Discover throughput characteristics",
                                  serviceUUID: iopTestPhase3Service.uuid,
                                  outcome: "Phase 3 service found")
                
                weakSelf.peripheralDelegate.discoverCharacteristics(characteristics: [weakSelf.iopTestPhase3ThroughputGATT, weakSelf.iopTestPhase3Control], for: iopTestPhase3Service)
                
            case let .successForCharacteristics(characteristics):
                guard let throughputCharacteristic = characteristics.first(where: { characteristic in
                    characteristic.uuid == weakSelf.iopTestPhase3ThroughputGATT
                }) else {
                    weakSelf.publishTestResult(passed: false, description: "Throughput characteristic didn't found.")
                    weakSelf.log.gatt(source: "SILThroughputTestCase",
                                      testID: weakSelf.testID,
                                      operation: "Resolve throughput characteristic",
                                      uuid: weakSelf.iopTestPhase3ThroughputGATT,
                                      serviceUUID: weakSelf.iopTestPhase3Service,
                                      outcome: "Characteristic not found")
                    weakSelf.postThroughputDeferredContinueWithoutPopup()
                    return
                }
                
                weakSelf.iopTestPhase3ThroughputCharacteristic = throughputCharacteristic
                
                for characteristic in characteristics {
                    if characteristic.uuid == weakSelf.iopTestPhase3Control, let dataToWrite = weakSelf.InitialValue.data(withCount: 1) {
                        weakSelf.log.gatt(source: "SILThroughputTestCase",
                                          testID: weakSelf.testID,
                                          operation: "Write throughput control value",
                                          uuid: characteristic.uuid,
                                          serviceUUID: weakSelf.iopTestPhase3Service,
                                          writeType: .withResponse,
                                          value: weakSelf.InitialValue,
                                          outcome: "Start notification throughput test")
                        weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: characteristic, writeType: .withResponse)
                        return
                    }
                }
                
                weakSelf.publishTestResult(passed: false, description: "Failure when writing to a characteristic.")
                weakSelf.log.gatt(source: "SILThroughputTestCase",
                                  testID: weakSelf.testID,
                                  operation: "Write throughput control value",
                                  uuid: weakSelf.iopTestPhase3Control,
                                  serviceUUID: weakSelf.iopTestPhase3Service,
                                  value: weakSelf.InitialValue,
                                  outcome: "Control characteristic not available for write")
                weakSelf.postThroughputDeferredContinueWithoutPopup()
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestPhase3ThroughputGATT, let data = data {
                    weakSelf.countCharacteristicThroughput += data.count
                }
                
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestPhase3Control {
                    weakSelf.log.gatt(source: "SILThroughputTestCase",
                                      testID: weakSelf.testID,
                                      operation: "Enable throughput notifications",
                                      uuid: weakSelf.iopTestPhase3ThroughputCharacteristic?.uuid,
                                      serviceUUID: weakSelf.iopTestPhase3Service,
                                      outcome: "Control write acknowledged")
                    weakSelf.peripheralDelegate.notifyCharacteristic(characteristic: weakSelf.iopTestPhase3ThroughputCharacteristic)
                    return
                }
                
                weakSelf.publishTestResult(passed: false, description: "Failure when notifying a characteristic.")
                weakSelf.log.gatt(source: "SILThroughputTestCase",
                                  testID: weakSelf.testID,
                                  operation: "Enable throughput notifications",
                                  uuid: characteristic.uuid,
                                  serviceUUID: weakSelf.iopTestPhase3Service,
                                  outcome: "Unexpected characteristic acknowledged instead of control")
                weakSelf.postThroughputDeferredContinueWithoutPopup()

            case let .updateNotificationState(characteristic: characteristic, state: state):
                if characteristic.uuid == weakSelf.iopTestPhase3ThroughputGATT {
                    if state == true {
                        weakSelf.iopTestPhase3ThroughputCharacteristic = characteristic
                        weakSelf.throughputMeasurementStart = Date()
                        weakSelf.log.gatt(source: "SILThroughputTestCase",
                                          testID: weakSelf.testID,
                                          operation: "Notifications enabled",
                                          uuid: characteristic.uuid,
                                          serviceUUID: weakSelf.iopTestPhase3Service,
                                          outcome: "Streaming throughput data for \(weakSelf.timeoutMS) ms")
                        weakSelf.startLiveThroughputUpdates()
                        DispatchQueue.main.async {
                            weakSelf.postThroughputResultPopupNotification(isCompleted: false)
                        }
                        weakSelf.scheduleThroughputStop()
                    } else {
                        weakSelf.cancelScheduledThroughputStop()
                        weakSelf.liveThroughputTimer?.invalidate()
                        weakSelf.liveThroughputTimer = nil
                        let finalMeasuredThroughputKbps = weakSelf.measuredThroughputKbps()
                        weakSelf.maxMeasuredThroughputKbps = max(weakSelf.maxMeasuredThroughputKbps, finalMeasuredThroughputKbps)
                        let throughputSpped = Double(weakSelf.countCharacteristicThroughput / 5)
                        weakSelf.log.gatt(source: "SILThroughputTestCase",
                                          testID: weakSelf.testID,
                                          operation: "Notifications disabled",
                                          uuid: characteristic.uuid,
                                          serviceUUID: weakSelf.iopTestPhase3Service,
                                          outcome: String(format: "bytesReceived=%d | avg=%.1f kbps | peak=%.1f kbps", weakSelf.countCharacteristicThroughput, finalMeasuredThroughputKbps, weakSelf.maxMeasuredThroughputKbps))
                        
                        DispatchQueue.main.async {
                            weakSelf.postThroughputResultPopupNotification(isCompleted: true)
                        }
                        
                        let acceptableThroughput = weakSelf.calculateThroughput()
                        if acceptableThroughput == 0 {
                            weakSelf.invalidateObservableTokens()
                            weakSelf.log.step(source: "SILThroughputTestCase",
                                              testID: weakSelf.testID,
                                              action: "Throughput completed with unknown target threshold",
                                              detail: String(format: "Measured %.1f Bytes/s but acceptable throughput could not be calculated.", throughputSpped))
                            weakSelf.testResult.value = SILTestResult(testID: weakSelf.testID, testName: weakSelf.testName, testStatus: .unknown(reason: "(Throughput: \(throughputSpped) Bytes/s)"))
                        } else if weakSelf.calculateThroughput() <= throughputSpped {
                            weakSelf.publishTestResult(passed: true, description: "(Throughput: \(throughputSpped) Bytes/s, Acceptable Throughput: \(weakSelf.calculateThroughput()) Bytes/s).")
                        } else {
                            weakSelf.publishTestResult(passed: false, description: "(Throughput: \(throughputSpped) Bytes/s, Acceptable Throughput: \(weakSelf.calculateThroughput()) Bytes/s).")
                        }
                    }
                }
               
            case .unknown:
                break
                
            default:
                weakSelf.publishTestResult(passed: false, description: "Unknown failure from peripheral delegate.")
                weakSelf.log.step(source: "SILThroughputTestCase", testID: weakSelf.testID, action: "Throughput peripheral delegate failure", detail: "Received an unexpected peripheral delegate status.")
                weakSelf.postThroughputDeferredContinueWithoutPopup()
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
     
        subscribeToCentralManager()
        
        peripheralDelegate.discoverServices(services: [iopTestPhase3Service])
    }
    
    private func scheduleThroughputStop() {
        cancelScheduledThroughputStop()
        let workItem = DispatchWorkItem { [weak self] in
            self?.disableNotifyThroughput()
        }
        throughputStopWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntervalFromTimeout, execute: workItem)
    }
    
    private func cancelScheduledThroughputStop() {
        throughputStopWorkItem?.cancel()
        throughputStopWorkItem = nil
    }
    
    @objc func disableNotifyThroughput() {
        cancelScheduledThroughputStop()
        log.gatt(source: "SILThroughputTestCase",
                 testID: testID,
                 operation: "Stop throughput notifications",
                 uuid: self.iopTestPhase3ThroughputCharacteristic?.uuid,
                 serviceUUID: iopTestPhase3Service,
                 outcome: "Measurement window \(timeoutMS) ms reached")
        self.peripheralDelegate.notifyCharacteristic(characteristic: self.iopTestPhase3ThroughputCharacteristic, enabled: false)
    }
    
    private func calculateThroughput() -> Double {
        if self.phy != PHY.Unknown {
            return calculateThroughputInBLE_6_0_0AndNewer()
        } else {
            return calculateThroughputBeforeBLE_6_0_0()
        }
    }
    
    private func calculateThroughputBeforeBLE_6_0_0() -> Double {
        guard let mtu_size = mtu_size, let pdu_size = pdu_size else {
            return 0
        }
        
        if pdu_size < mtu_size {
            return Double(4 * ((pdu_size - 7) / 15) * 1000) * 0.65
        } else {
            let expectThroughputSpeed = ((mtu_size - 3) / 15) * 1000
            return Double((4 * expectThroughputSpeed)) * 0.65
        }
    }
    
    private func calculateThroughputInBLE_6_0_0AndNewer() -> Double {
        guard let pdu_size = pdu_size, let phy = phy, let interval = interval else {
            return calculateThroughputBeforeBLE_6_0_0()
        }
        
        //something with changing MTU by peripheral doesn't work, used default value on the iOS
        let mtu_size = 23
            
        var timeNeededForSendOnePacketMicroSeconds = 0
        if phy == PHY._1M {
            timeNeededForSendOnePacketMicroSeconds = 8 * pdu_size + 492
        } else if phy == PHY._2M {
            timeNeededForSendOnePacketMicroSeconds = 4 * pdu_size + 396
        }
        
        guard timeNeededForSendOnePacketMicroSeconds > 0 else {
            return 0
        }
        
        let intervalMicroSeconds = interval * 1000
        let intervalSeconds = interval / 1000.0
        let quantity = floor(intervalMicroSeconds / Double(timeNeededForSendOnePacketMicroSeconds))
        let sizeEffective = Double(mtu_size - 3)
        let fragmentationCount = ceil(Double(mtu_size) / Double(pdu_size - 4))
        let speedPerSecond = quantity * sizeEffective / fragmentationCount / intervalSeconds
        
        return floor(speedPerSecond * 0.5)
    }
    
    func getTestArtifacts() -> Dictionary<String, Any> {
        return ["peripheral" : self.peripheral,
                "peripheralDelegate" : self.peripheralDelegate, "discoveredPeripheral": self.discoveredPeripheral]
    }
    
    func stopTesting() {
        cancelScheduledThroughputStop()
        liveThroughputTimer?.invalidate()
        liveThroughputTimer = nil
        invalidateObservableTokens()
    }
    
    private func startLiveThroughputUpdates() {
        DispatchQueue.main.async {
            self.liveThroughputTimer?.invalidate()
            self.liveThroughputTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.postThroughputResultPopupNotification(isCompleted: false)
            }
        }
    }
    
    /// Bytes/s → kbps (kilobits per second) using the elapsed notification window.
    private func measuredThroughputKbps() -> Double {
        let intervalSec = throughputMeasurementStart.map { max(Date().timeIntervalSince($0), 0.001) } ?? (Double(timeoutMS) / 1000.0)
        guard intervalSec > 0 else { return 0 }
        let bytesPerSec = Double(countCharacteristicThroughput) / intervalSec
        return bytesPerSec * 8.0 / 1000.0
    }
    
    private func targetThroughputKbps() -> Double {
        bytesPerSecondToKbps(calculateThroughput())
    }
    
    private func bytesPerSecondToKbps(_ bytesPerSecond: Double) -> Double {
        guard bytesPerSecond > 0 else { return 0 }
        return bytesPerSecond * 8.0 / 1000.0
    }

    private func postThroughputResultPopupNotification(isCompleted: Bool) {
        let mtu = mtu_size ?? 247
        let buffer = max(0, mtu - 3)
        let measuredThroughputKbps = measuredThroughputKbps()
        maxMeasuredThroughputKbps = max(maxMeasuredThroughputKbps, measuredThroughputKbps)
        NotificationCenter.default.post(
            name: .SILIOPThroughputResultReady,
            object: nil,
            userInfo: [
                SILIOPThroughputPopupKeys.speedKbps: measuredThroughputKbps,
                SILIOPThroughputPopupKeys.mtuSize: mtu,
                SILIOPThroughputPopupKeys.bufferSize: buffer,
                SILIOPThroughputPopupKeys.isCompleted: isCompleted,
                SILIOPThroughputPopupKeys.maxSpeedKbps: maxMeasuredThroughputKbps,
                SILIOPThroughputPopupKeys.averageSpeedKbps: measuredThroughputKbps,
                SILIOPThroughputPopupKeys.targetSpeedKbps: targetThroughputKbps()
            ]
        )
    }

    /// Throughput scenario deferred advancing until user dismisses the gauge popup; early failures skip the popup and use this instead.
    private func postThroughputDeferredContinueWithoutPopup() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .SILIOPThroughputContinueWithoutPopup, object: nil)
        }
    }
}
