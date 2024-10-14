//
//  SILWifiCommissioningViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 21/09/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import SVProgressHUD

typealias SecurityType = SILWifiCommissioningSecurityType
typealias WriteCommandType = SILWifiCommissioningWriteCommandType
typealias ReadCommandType = SILWifiCommissioningReadCommandType
typealias NotifyState = SILWifiCommissioningNotifyState
    
struct SILWifiCommissioningAccessPoint {
    let name: String
    let securityType: SecurityType
    var connected: Bool = false
    var macAddress: String? = nil
    var ipAddres: String? = nil
}

enum SILWifiCommissioningState: Equatable {
    case discoveringServicesAndCharacteristicsStarted
    case firmwareVersionRead(version: String)
    case checkingStatusStarted
    case checkingStatusFinished(_ isConnected: Bool)
    case scanning
    case connectingStarted
    case connectionFailed
    case connected
    case disconnectingStarted
    case disconnectingFinished
    case unexpectedlyDisconnected
    case bluetoothDisabled
    case failure(reason: String)
    case unknown
}

protocol SILWifiCommissioningViewModelDelegate {
    func showDisconnectNeededPopup()
    func showDisconnectPopup()
    func showPasswordPopup(_ ap: SILWifiCommissioningAccessPoint)
}

class SILWifiCommissioningViewModel {
    
    var wifiCommissioningState: SILObservable<SILWifiCommissioningState> = SILObservable(initialValue: .unknown)
    var accessPointsCellModels: SILObservable<[SILWifiCommissioningAPCellViewModel]> = SILObservable(initialValue: [])
    var delegate: SILWifiCommissioningViewModelDelegate?
    
    private var centralManager: SILCentralManager
    private var connectedPeripheral: CBPeripheral
    private let peripheralDelegate: SILPeripheralDelegate!
    
    private var tokenBag = SILObservableTokenBag()
    
    private var selectedAccessPointPassword: String?
    private var readCharacteristicTimer: SILTimeoutTimer!
    
    private var wifiCommissioningService: CBService!
    private var writeCharacteristic: CBCharacteristic!
    private var readCharacteristic: CBCharacteristic!
    private var notifyCharacteristic: CBCharacteristic!
    
    private var writeCommandState: WriteCommandType = .unknown
    private var notifyState: NotifyState = .unknown
    
    private var accessPoints = [SILWifiCommissioningAccessPoint]()
    private var givenAccessPointsNumber: Int?
    
    private var selectedAccessPoint: SILWifiCommissioningAccessPoint?
    
    init(centralManager: SILCentralManager, connectedPeripheral: CBPeripheral) {
        self.centralManager = centralManager
        self.connectedPeripheral = connectedPeripheral
        self.peripheralDelegate = SILPeripheralDelegate(peripheral: connectedPeripheral)
        self.readCharacteristicTimer = SILTimeoutTimer(action: { self.peripheralDelegate.readCharacteristic(characteristic: self.readCharacteristic) },
                                                       timeoutExceedAction: { self.wifiCommissioningState.value = .failure(reason: "Timeout expired!") },
                                                       interval: 1,
                                                       timeout: 20)
    }
    
    private func registerCentralManagerNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDisconnectNotification(notification:)),
                                               name: .SILCentralManagerDidDisconnectPeripheral,
                                               object: self.centralManager)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleBluetoothDisabledNotification(notification:)),
                                               name: .SILCentralManagerBluetoothDisabled,
                                               object: self.centralManager)
    }
    
    @objc private func handleDisconnectNotification(notification: Notification) {
        self.wifiCommissioningState.value = .failure(reason: "Device unexpectedly disconnected.")
    }
    
    @objc private func handleBluetoothDisabledNotification(notification: Notification) {
        self.wifiCommissioningState.value = .bluetoothDisabled
    }
    
    // MARK: Public methods
    
    public func viewWillAppear() {
        registerCentralManagerNotifications()
        discoverWifiCommissioningServices()
    }
    
    public func viewWillDisappear() {
        NotificationCenter.default.removeObserver(self)
        centralManager.disconnect(from: self.connectedPeripheral)
        tokenBag.invalidateTokens()
    }
    
    public func viewDidLoad() {
        peripheralDelegate.newStatus().observe { status in
            switch status {
            case .successForServices(let services):
                self.setWifiCommissioningService(services)
                self.discoverWifiCommissioningCharacteristics()
                
            case .successForCharacteristics(let characteristics):
                self.setWifiCommissioningCharacteristics(characteristics)
                self.subscribeToNotifyCharacteristic()
                self.readFirmwareVersion()
                
            case .successWrite(let characteristic):
                self.handleWriteCharacteristicValue(characteristic)
            
            case .successGetValue(let value, let characteristic):
                if let value = value {
                    switch characteristic.uuid {
                    case self.readCharacteristic.uuid:
                        self.handleReadCharacteristicValue(value)
                    case self.notifyCharacteristic.uuid:
                        self.handleNotifyCharacteristicValue(value)
                    default:
                        break
                    }
                }
                
            case .failure(let error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                
            default:
                break
            }
        }.putIn(bag: tokenBag)
    }
    
    public func newState() -> SILObservable<SILWifiCommissioningState> {
        self.wifiCommissioningState = SILObservable(initialValue: .unknown)
        
        return wifiCommissioningState
    }
    
    public func discoverWifiCommissioningServices() {
        self.wifiCommissioningState.value = .discoveringServicesAndCharacteristicsStarted
        let services = [SILWifiCommissioningPeripheralGATTDatabase.WifiCommissioningService.cbUUID]
        self.peripheralDelegate.discoverServices(services: services)
    }
    
    func scan() {
        if wifiCommissioningState.value != .connected {
            self.accessPoints = []
            self.wifiCommissioningState.value = .scanning
            self.notifyState = .scanning
            writeCommandState(.scan)
        }
    }
    
    func joinAP(_ ap: SILWifiCommissioningAccessPoint, password: String?) {
        self.selectedAccessPointPassword = password
        self.wifiCommissioningState.value = .connectingStarted
        writeCommandState(.join(ap.name))
    }

    func disconnectCurrentAp() {
        self.wifiCommissioningState.value = .disconnectingStarted
        writeCommandState(.disconnect)
    }
    
    // MARK: Discovering methods
    
    private func discoverWifiCommissioningCharacteristics() {
        let characteristics = [
            SILWifiCommissioningPeripheralGATTDatabase.WifiCommissioningService.WriteCharacteristic.cbUUID,
            SILWifiCommissioningPeripheralGATTDatabase.WifiCommissioningService.ReadCharacteristic.cbUUID,
            SILWifiCommissioningPeripheralGATTDatabase.WifiCommissioningService.NotifyCharacteristic.cbUUID,
        ]
        self.peripheralDelegate.discoverCharacteristics(characteristics: characteristics, for: wifiCommissioningService)
    }
    
    private func setWifiCommissioningService(_ services: [CBService]) {
        if let wifiCommissioningService = services.first(where: { $0.uuid == SILWifiCommissioningPeripheralGATTDatabase.WifiCommissioningService.cbUUID }) {
            self.wifiCommissioningService = wifiCommissioningService
        } else {
            self.wifiCommissioningState.value = .failure(reason: "WiFi commissioning service not found!")
        }
    }
    
    private func setWifiCommissioningCharacteristics(_ characteristics: [CBCharacteristic]) {
        let readCharacteristicUuid = SILWifiCommissioningPeripheralGATTDatabase.WifiCommissioningService.ReadCharacteristic.cbUUID
        if let readCharacteristic = characteristics.first(where: { $0.uuid == readCharacteristicUuid }) {
            self.readCharacteristic = readCharacteristic
        } else {
            self.wifiCommissioningState.value = .failure(reason: "WiFi commissioning read characteristic not found!")
        }
        
        let writeCharacteristicUuid = SILWifiCommissioningPeripheralGATTDatabase.WifiCommissioningService.WriteCharacteristic.cbUUID
        if let writeCharacteristic = characteristics.first(where: { $0.uuid == writeCharacteristicUuid }) {
            self.writeCharacteristic = writeCharacteristic
        } else {
            self.wifiCommissioningState.value = .failure(reason: "WiFi commissioning write characteristic not found!")
        }
        
        let notifyCharacteristicUuid = SILWifiCommissioningPeripheralGATTDatabase.WifiCommissioningService.NotifyCharacteristic.cbUUID
        if let notifyCharacteristic = characteristics.first(where: { $0.uuid == notifyCharacteristicUuid }) {
            self.notifyCharacteristic = notifyCharacteristic
        } else {
            self.wifiCommissioningState.value = .failure(reason: "WiFi commissioning notify characteristic not found!")
        }
    }
    
    // MARK: Bluetooth communication methods
    
    private func subscribeToNotifyCharacteristic() {
        self.peripheralDelegate.notifyCharacteristic(characteristic: notifyCharacteristic)
    }

    // Handle Read Characteristic Value
    private func handleReadCharacteristicValue(_ value: Data) {
        let stringValue = String(data: value, encoding: .utf8)
        let bytes = value.bytes
        let firstByte = Int(bytes[0])
        guard let command = ReadCommandType(rawValue: firstByte)
        else {
            debugPrint("Wrong command type!")
            return
        }
        
        let secondByte = Int(bytes[1])
        switch command {
        case .readFirmware:
            let firmwareVersionLength = secondByte
            guard firmwareVersionLength > 0 else {
                self.wifiCommissioningState.value = .failure(reason: "Wrong firmware on device!")
                return
            }
            let firmwareVersion = stringValue![2..<2 + firmwareVersionLength]
            debugPrint("Firmware version", firmwareVersion)
            //self.wifiCommissioningState.value = .firmwareVersionRead(version: firmwareVersion)
            
            // Adding code for Firmware version
            var firmareVersionString = ""
            for (index, val) in bytes[2..<11].enumerated() {
                if index < 2 {
                    let str = String(format:"%02X", val)
                    firmareVersionString =  firmareVersionString + str
                } else {
                    if index != 7 {
                        firmareVersionString = firmareVersionString + ".\(val)"
                    }
                }
            }
            print("firmareVersionString \(firmareVersionString)")
            self.wifiCommissioningState.value = .firmwareVersionRead(version: firmareVersionString)
            self.checkConnectionStatus()
            
        case .scan:
            self.givenAccessPointsNumber = secondByte
            self.writeCommandState = .scan
            debugPrint("Given access points number:", secondByte)

        case .connectionStatus:
            guard self.writeCommandState == .connectionStatus else {
                return
            }
            if let connectingAccessPoint = self.selectedAccessPoint {
                self.writeSecurityType(securityType: connectingAccessPoint.securityType)
            } else {
                let apNameLength = secondByte
                if apNameLength > 0 {
                    let apName = stringValue![2..<2 + apNameLength]
                    debugPrint("Connected AP name:", apName, value)
                    self.wifiCommissioningState.value = .checkingStatusFinished(true)
                } else {
                    debugPrint("No connected AP")
                    self.wifiCommissioningState.value = .checkingStatusFinished(false)
                }
            }
        
        case .join:
            guard wifiCommissioningState.value == .connectingStarted else {
                return
            }
            if secondByte == 1 {
                let macAddressArray = bytes[3...8].map { String(format:"%02X", Int($0)) }
                let macAddress = macAddressArray.joined(separator: ":")
                
                let ipAddressArray = bytes[10...13].map { "\(Int($0))" }
                let ipAddress = ipAddressArray.joined(separator: ".")
                
                guard let index = accessPoints.firstIndex(where: { $0.name == self.selectedAccessPoint?.name}) else {
                    return
                }
                var accessPoint = accessPoints[index]
                accessPoint.ipAddres = ipAddress
                accessPoint.macAddress = macAddress
                accessPoint.connected = true
                accessPoints[index] = accessPoint
                print("ip", ipAddress, macAddress, value)
                // Storing data
                UserDefaults.standard.set("\(ipAddress)", forKey: "access_point_IPA")

                self.selectedAccessPoint = accessPoint
                self.updateAccessPoints(accessPoint)
                self.wifiCommissioningState.value = .connected
                self.notifyState = .connected
                
            } else {
                debugPrint("Connection with access point failed!")
                self.selectedAccessPoint = nil
                self.wifiCommissioningState.value = .connectionFailed
            }
            self.readCharacteristicTimer.stop()
            
        case .disconnect:
            guard wifiCommissioningState.value == .disconnectingStarted else {
                return
            }
            self.readCharacteristicTimer.stop()
            self.selectedAccessPoint = nil
            self.wifiCommissioningState.value = .disconnectingFinished
            
        default:
            break
        }
    }
    
    private func handleNotifyCharacteristicValue(_ value: Data) {
        let bytes = value.bytes
        let firstByte = Int(bytes[0])
        switch self.notifyState {
        case .scanning:
            let securityType = SecurityType(rawValue: firstByte) ?? .unknown
            let stringValue = String(data: value, encoding: .utf8)!
            let accessPointName = parseAccessPointName(stringValue)
            let accessPoint = SILWifiCommissioningAccessPoint(name: accessPointName, securityType: securityType)
            debugPrint("accessPoint", accessPoint)
            self.updateAccessPoints(accessPoint)
            
        case .connected:
            debugPrint("Notify from selected Access Point", bytes)
            if firstByte == NotifyState.connected.rawValue {
                self.wifiCommissioningState.value = .unexpectedlyDisconnected
            }
        default:
            break
        }
    }
    
    private func handleWriteCharacteristicValue(_ characteristic: CBCharacteristic) {
        if characteristic.uuid == self.writeCharacteristic.uuid {
            switch self.writeCommandState {
            case .readFirmware:
                debugPrint("Successfully write read firmware command")
                self.peripheralDelegate.readCharacteristic(characteristic: self.readCharacteristic)
                
            case .scan:
                debugPrint("Successfully write scan command.")
                self.peripheralDelegate.readCharacteristic(characteristic: self.readCharacteristic)
                
            case .connectionStatus:
                debugPrint("Successfully write connection status command.")
                self.peripheralDelegate.readCharacteristic(characteristic: self.readCharacteristic)
            
            case .join(let name):
                debugPrint("Successfully write join command")
                let accessPoint = self.accessPoints.first(where: { $0.name == name })!
                self.selectedAccessPoint = accessPoint
                self.writeCommandState(.connectionStatus)
                
            case .security(let securityType):
                debugPrint("Successfully write security command")
                if securityType == .open {
                    self.selectedAccessPoint?.connected = true
                    self.readCharacteristicTimer.start()
                } else {
                    self.writePassword()
                }
            
            case .password(password: _):
                debugPrint("Successfully write password")
                self.readCharacteristicTimer.start()

            case .disconnect:
                debugPrint("Successfully write disconnect command")
                self.selectedAccessPoint = nil
                self.readCharacteristicTimer.start()
            default:
                break
            }
        }
    }
    
    private func parseAccessPointName(_ value: String) -> String {
        guard value.count > 2 else {
            return ""
        }
        
        let res = String(value.dropFirst(2)).filter { !$0.isWhitespace || $0 == " " }
        return res.replacingOccurrences(of: "\0", with: "", options: .literal, range: nil)
    }
    
    // MARK: Wi-Fi Commmissioning actions
    
    private func readFirmwareVersion() {
        writeCommandState(.readFirmware)
    }
    
    private func selectAP(_ ap: SILWifiCommissioningAccessPoint) {
        if ap.securityType != .open {
            self.delegate?.showPasswordPopup(ap)
        } else {
            self.joinAP(ap, password: nil)
        }
    }
    
    private func writeSecurityType(securityType: SILWifiCommissioningSecurityType) {
        writeCommandState(.security(securityType))
    }
    
    private func checkConnectionStatus() {
        self.wifiCommissioningState.value = .checkingStatusStarted
        writeCommandState(.connectionStatus)
    }
    
    private func writePassword() {
        if let password = self.selectedAccessPointPassword {
            writeCommandState(.password(password))
        }
    }
    
    private func writeCommandState(_ command: WriteCommandType) {
        self.writeCommandState = command
        if let command = writeCommandState.command {
            self.peripheralDelegate.writeToCharacteristic(data: command, characteristic: writeCharacteristic, writeType: .withResponse)
        }
    }
    
    // MARK: CellModel helpers
    
    private func updateAccessPoints(_ accessPoint: SILWifiCommissioningAccessPoint) {
        if let index = accessPoints.firstIndex(where: { $0.name == accessPoint.name}) {
            accessPoints[index] = accessPoint
        } else {
            accessPoints.append(accessPoint)
        }
        self.accessPointsCellModels.value = createCellModels()
    }
    
    private func createCellModels() -> [SILWifiCommissioningAPCellViewModel] {
        return accessPoints.map { ap in
            if !ap.connected {
                let selectAction: () -> () = selectedAccessPoint != nil ? { self.delegate?.showDisconnectNeededPopup() } : { self.selectAP(ap) }
                return SILWifiCommissioningAPCellViewModel(accessPoint: ap, selectAction: selectAction)
            } else {
                return SILWifiCommissioningConnectedAPCellViewModel(accessPoint: ap, selectAction: { self.delegate?.showDisconnectPopup() })
            }
        }
    }
}
