//
//  SILThroughputTestCase.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 25.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILThroughputTestCase: SILTestCase, SILTestCaseTimeout {
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
    private var throughputTimer: Timer?
    
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
        guard iopCentralManager.bluetoothState else {
            self.publishTestResult(passed: false, description: "Bluetooth disabled!")
            IOPLog().iopLogSwiftFunction(message: "FBluetooth disabled!")
            return
        }
        
        guard let _ = discoveredPeripheral else {
            self.publishTestResult(passed: false, description: "Discovered peripheral is nil.")
            IOPLog().iopLogSwiftFunction(message: "Discovered peripheral is nil.")
            return
        }
        
        guard let _ = peripheral else {
            self.publishTestResult(passed: false, description: "Peripheral is nil.")
            IOPLog().iopLogSwiftFunction(message: "Peripheral is nil.")
            return
        }

        publishStartTestEvent()
        testThroughput()
    }
    
    private func subscribeToCentralManager() {
        weak var weakSelf = self
        let centralManagerSubscription = iopCentralManager.newPublishConnectionStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .disconnected(peripheral: _, error: error):
                debugPrint("Peripheral disconnected with \(String(describing: error?.localizedDescription))")
                IOPLog().iopLogSwiftFunction(message: "Peripheral disconnected with \(String(describing: error?.localizedDescription))")

                weakSelf.publishTestResult(passed: false, description: "Peripheral was disconnected with \(String(describing: error?.localizedDescription)).")
            
            case let .bluetoothEnabled(enabled: enabled):
                if !enabled {
                    debugPrint("Bluetooth disabled!")
                    IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled!")

                    weakSelf.publishTestResult(passed: false, description: "Bluetooth disabled.")
                }
                
            case .unknown:
                break
            
            default:
                weakSelf.publishTestResult(passed: false, description: "Unknown failure from central manager.")
                IOPLog().iopLogSwiftFunction(message: "Unknown failure from central manager.")

            }
        })
        disposeBag.add(token: centralManagerSubscription)
        observableTokens.append(centralManagerSubscription)
    }
    
    private func testThroughput() {
        self.peripheralDelegate = SILPeripheralDelegate(peripheral: self.peripheral)
        
        weak var weakSelf = self
        let peripheralDelegateSubscription = peripheralDelegate.newStatus().observe( { status in
            guard let weakSelf = weakSelf else { return }
            switch status {
            case let .successForServices(services):
                guard let iopTestPhase3Service = services.first(where: { service in service.uuid == weakSelf.iopTestPhase3Service }) else {
                    weakSelf.publishTestResult(passed: false, description: "Service Test Phase 3 didn't found.")
                    IOPLog().iopLogSwiftFunction(message: "Service Test Phase 3 didn't found.")
                    return
                }
                
                weakSelf.peripheralDelegate.discoverCharacteristics(characteristics: [weakSelf.iopTestPhase3ThroughputGATT, weakSelf.iopTestPhase3Control], for: iopTestPhase3Service)
                
            case let .successForCharacteristics(characteristics):
                guard let throughputCharacteristic = characteristics.first(where: { characteristic in
                    characteristic.uuid == weakSelf.iopTestPhase3ThroughputGATT
                }) else {
                    weakSelf.publishTestResult(passed: false, description: "Throughput characteristic didn't found.")
                    IOPLog().iopLogSwiftFunction(message: "Throughput characteristic didn't found.")
                    return
                }
                
                weakSelf.iopTestPhase3ThroughputCharacteristic = throughputCharacteristic
                
                for characteristic in characteristics {
                    if characteristic.uuid == weakSelf.iopTestPhase3Control, let dataToWrite = weakSelf.InitialValue.data(withCount: 1) {
                        weakSelf.peripheralDelegate.writeToCharacteristic(data: dataToWrite, characteristic: characteristic, writeType: .withResponse)
                        return
                    }
                }
                
                weakSelf.publishTestResult(passed: false, description: "Failure when writing to a characteristic.")
                IOPLog().iopLogSwiftFunction(message: "Failure when writing to a characteristic.")
                
            case let .successGetValue(value: data, characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestPhase3ThroughputGATT, let data = data {
                    weakSelf.countCharacteristicThroughput += data.count
                }
                
            case let .successWrite(characteristic: characteristic):
                if characteristic.uuid == weakSelf.iopTestPhase3Control {
                    weakSelf.peripheralDelegate.notifyCharacteristic(characteristic: weakSelf.iopTestPhase3ThroughputCharacteristic)
                    return
                }
                
                weakSelf.publishTestResult(passed: false, description: "Failure when notifying a characteristic.")
                IOPLog().iopLogSwiftFunction(message: "Failure when notifying a characteristic.")
                
            case let .updateNotificationState(characteristic: characteristic, state: state):
                if characteristic.uuid == weakSelf.iopTestPhase3ThroughputGATT {
                    if state == true {
                        weakSelf.iopTestPhase3ThroughputCharacteristic = characteristic
                        weakSelf.throughputTimer = Timer.scheduledTimer(timeInterval: weakSelf.timeIntervalFromTimeout, target: self, selector: #selector(weakSelf.disableNotifyThroughput), userInfo: nil, repeats: false)
                    } else {
                        let throughputSpped = Double(weakSelf.countCharacteristicThroughput / 5)
                        debugPrint("Throughput speed: \(throughputSpped) kbps")
                        IOPLog().iopLogSwiftFunction(message: "Throughput speed: \(throughputSpped) kbps")
                        
                        let acceptableThroughput = weakSelf.calculateThroughput()
                        if acceptableThroughput == 0 {
                            weakSelf.invalidateObservableTokens()
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
                IOPLog().iopLogSwiftFunction(message: "Unknown failure from peripheral delegate.")
            }
        })
        disposeBag.add(token: peripheralDelegateSubscription)
        observableTokens.append(peripheralDelegateSubscription)
     
        subscribeToCentralManager()
        
        peripheralDelegate.discoverServices(services: [iopTestPhase3Service])
    }
    
    @objc func disableNotifyThroughput() {
        self.throughputTimer?.invalidate()
        self.throughputTimer = nil
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
                "peripheralDelegate" : self.peripheralDelegate]
    }
    
    func stopTesting() {
        throughputTimer?.invalidate()
        invalidateObservableTokens()
    }
}
