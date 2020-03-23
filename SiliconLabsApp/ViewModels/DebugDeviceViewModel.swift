//
//  DebugDeviceViewModel.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 7/20/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc(SILDebugDeviceViewModelDelegate)
protocol DebugDeviceViewModelDelegate: class {
    @objc(didConnectToPeripheral:)
    func didConnect(to peripheral: CBPeripheral?)
    @objc(didDisconnectFromPeripheral:)
    func didDisconnect(from peripheral: CBPeripheral?)
    @objc(didFailToConnectToPeripheral:)
    func didFailToConnect(to peripheral: CBPeripheral?)

    func scanningDidEnd()
}

@objc(SILDebugDeviceViewModel)
@objcMembers
final class DebugDeviceViewModel: NSObject {

    // MARK: - Properties

    weak var delegate: DebugDeviceViewModelDelegate? = nil

    let centralManager = SILCentralManager(serviceUUIDs: [])
    private var discoveredPeripherals: [SILDiscoveredPeripheral] = []
    private(set) var allDiscoveredPeripheralsViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    private(set) var discoveredPeripheralsViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    var connectedPeripheral: CBPeripheral? = nil
    private(set) var isConnecting: [CBPeripheral : Bool] = [:]
    var isContentAvailable: Bool {
        return discoveredPeripherals.count > 0
    }
    var observing = false

    var currentMinRSSI: NSNumber? = nil {
        didSet {
            removeDiscoveredDevicesIfNeed()
        }
    }
    
    var searchByDeviceName: String? = nil {
        didSet {
            removeDiscoveredDevicesIfNeed()
        }
    }
    
    var searchByAdvertisingData: String? = nil {
        didSet {
            removeDiscoveredDevicesIfNeed()
        }
    }
    
    var beaconTypes: [SILBrowserBeaconType]? = nil {
        didSet {
            removeDiscoveredDevicesIfNeed()
        }
    }

    var isFavourite: Bool = false {
        didSet {
            removeDiscoveredDevicesIfNeed()
        }
    }

    var isConnectable: Bool = false {
        didSet {
            removeDiscoveredDevicesIfNeed()
        }
    }
    
    var peripheralDisconnectedMessage: String? {
        guard let peripheral = connectedPeripheral else { return nil }
        let peripheralName = peripheral.name ?? "Unknown"
        return "Disconnected from \(peripheralName)"
    }

    var isFilterApplied: Bool {
        if searchByDeviceName != nil || currentMinRSSI != nil {
            return true
        }
        return false
    }

    var filterDescription: String? {
        var descriptors = [String]()
        if let searchByDeviceName = searchByDeviceName {
            descriptors.append(searchByDeviceName)
        }

        if let currentMinRSSI = currentMinRSSI {
            descriptors.append("\(currentMinRSSI) RSSI")
        }
        
        return descriptors.joined(separator: ", ")
    }

    // MARK: - Lifecycle

    override init() {
        super.init()

        registerNotifications()
    }

    deinit {
        unregisterNotifications()
    }

    // MARK: - Actions

    func clearIsConnectingDirectory() {
        isConnecting = [:]
    }
    
    func removeAllDiscoveredPeripherals() {
        centralManager.removeAllDiscoveredPeripherals()
        discoveredPeripherals = []
        discoveredPeripheralsViewModels = []
        allDiscoveredPeripheralsViewModels = []
    }

    func peripheralViewModel(at row: Int) -> SILDiscoveredPeripheralDisplayDataViewModel? {
        guard row < discoveredPeripheralsViewModels.count else { return nil }
        return discoveredPeripheralsViewModels[row]
    }

    func connect(to peripheralViewModel: SILDiscoveredPeripheralDisplayDataViewModel) -> Bool {
        if let discoveredPeripheral = peripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral,
            discoveredPeripheral.isConnectable,
            centralManager.canConnect(to: discoveredPeripheral) {
            centralManager.connect(to: discoveredPeripheral)
            isConnecting.updateValue(true, forKey: discoveredPeripheral.peripheral!)
        } else {
            isConnecting.updateValue(false, forKey: peripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral!)
        }
        return isConnecting[peripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral!]!
    }

    func containPeripheral(_ peripheral: CBPeripheral) -> Bool {
        return isConnecting.contains(where: { (key, value) -> Bool in
            if value {
                return key.identifier.uuidString == peripheral.identifier.uuidString
            }
            return false
        })
    }
    
    func resetFilter() {
        set(query: nil, minRSSI: nil)
    }

    @objc(setSearchQuery:minRSSI:)
    func set(query: String?, minRSSI: NSNumber?) {
        self.searchByDeviceName = query
        self.currentMinRSSI = minRSSI
    }

    // MARK: Scanning

    func startScanning() {
        centralManager.addScan(forPeripheralsObserver: self, selector: #selector(didReceiveScanForPeripheralChange))
    }

    func stopScanning() {
        centralManager.removeScan(forPeripheralsObserver: self)
        discoveredPeripherals = centralManager.discoveredPeripherals()
    }

    @objc private func didReceiveScanForPeripheralChange() {
        discoveredPeripherals = centralManager.discoveredPeripherals()
    }

    // MARK: Private implementation

    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectPeripheral(notification:)), name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectPeripheral(notification:)), name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFailToConnectPeripheral(notification:)), name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
    }

    private func unregisterNotifications() {
        centralManager.removeScan(forPeripheralsObserver: self)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
    }

    func refreshDiscoveredPeripheralViewModels() {
        let peripheralViewModels = discoverForCurrentArrayPeripheralDevices()
        
        addNewDevicesIfNeed(peripheralViewModels)
        
        removeDiscoveredDevicesIfNeed()
    }
    
    private func discoverForCurrentArrayPeripheralDevices() -> [SILDiscoveredPeripheralDisplayDataViewModel] {
        var peripheralViewModels = [SILDiscoveredPeripheralDisplayDataViewModel]()
        
        for peripheral in discoveredPeripherals {
            guard centralManager.canConnect(to: peripheral) else { continue }

            let discoveredPeripheralDisplayData = SILDiscoveredPeripheralDisplayData(discoveredPeripheral: peripheral)
            guard let peripheralViewModel = SILDiscoveredPeripheralDisplayDataViewModel(discoveredPeripheralDisplayData: discoveredPeripheralDisplayData) else { continue }
            
            peripheralViewModels = peripheralViewModels.filter({ $0.discoveredPeripheralDisplayData.discoveredPeripheral.rssiMeasurementTable.lastRSSIMeasurement() != nil })
            
            peripheralViewModels.append(peripheralViewModel)
        }
        
        return peripheralViewModels
    }
    
    private func addNewDevicesIfNeed(_ peripheralViewModels: [SILDiscoveredPeripheralDisplayDataViewModel]) {
        for peripheralDevice in peripheralViewModels {
            if !arrayContainDevice(device: peripheralDevice) {
                if (SILFavoritePeripheral.isFavorite(peripheralDevice)) {
                    peripheralDevice.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite = true
                    allDiscoveredPeripheralsViewModels.insert(peripheralDevice, at: 0)
                } else {
                    allDiscoveredPeripheralsViewModels.append(peripheralDevice)
                }
            }
        }
    }
    
    private func removeDiscoveredDevicesIfNeed() {
        setupDeviceForFilter()
        filterByCurrentMinRSSI()
        filterBySearchDeviceName()
        filterBySearchAdvertisingData()
        filterByBeaconTypes()
        filterByIsFavourite()
        filterByIsConnectable()
        postReloadBrowserTable()
    }
    
    private func setupDeviceForFilter() {
        discoveredPeripheralsViewModels = allDiscoveredPeripheralsViewModels.sorted {
            $0.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite &&
            !$1.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite
        }
    }
    
    private func filterByCurrentMinRSSI() {
        if let currentMinRSSI = currentMinRSSI {
            let rssiPredicate = NSPredicate(format: "discoveredPeripheralDisplayData.discoveredPeripheral.RSSIMeasurementTable.lastRSSIMeasurement.intValue > \(currentMinRSSI)")
            discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter { rssiPredicate.evaluate(with: $0) }
        }
    }
    
    private func filterBySearchDeviceName() {
        if let searchByDeviceName = searchByDeviceName {
            let namePredicate = NSPredicate(format: "discoveredPeripheralDisplayData.discoveredPeripheral.advertisedLocalName CONTAINS[cd] %@", searchByDeviceName)
            discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter { namePredicate.evaluate(with: $0) }
        }
    }
    
    private func filterBySearchAdvertisingData() {

    }
    
    private func filterByBeaconTypes() {
        var filterIsActive = false
        if let beaconTypes = beaconTypes {
            for beacon in beaconTypes {
                if beacon.isSelected == true {
                    filterIsActive = true
                }
            }
            
            if filterIsActive == false {
                return
            }
            
            for beacon in beaconTypes {
                if beacon.isSelected == false {
                    filterByBeaconNameNotEqual(beaconName: beacon.beaconName)
                }
            }
        }
    }
    
    private func filterByBeaconNameNotEqual(beaconName: String) {
        let beaconPredicate = NSPredicate(format: "NOT (discoveredPeripheralDisplayData.discoveredPeripheral.beacon.name CONTAINS[cd] %@)", beaconName)
        discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter { beaconPredicate.evaluate(with: $0) }
    }
    
    private func filterByIsFavourite() {
        if (isFavourite) {
            let favouritePredicate = NSPredicate(format: "discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite == %i", isFavourite ? 1 : 0);
            discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter{
                favouritePredicate.evaluate(with: $0) }
        }
    }
    
    private func filterByIsConnectable() {
        if (isConnectable) {
            let connectablePredicate = NSPredicate(format: "discoveredPeripheralDisplayData.discoveredPeripheral.isConnectable == %i", isConnectable ? 1 : 0);
            discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter{
                connectablePredicate.evaluate(with: $0) }
        }
    }
    
    private func arrayContainDevice(device: SILDiscoveredPeripheralDisplayDataViewModel) -> Bool {
        let deviceUUID = device.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral.identifier
        for discoveredDevice in allDiscoveredPeripheralsViewModels {
            if discoveredDevice.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral.identifier == deviceUUID {
                return true
            }
        }
        
        return false
    }
    
    private func postReloadBrowserTable() {
        NotificationCenter.default.post(name: Notification.Name(SILNotificationReloadBrowserTable), object: nil)
    }

    // MARK: Notifcation Methods

    @objc private func didConnectPeripheral(notification: Notification) {
        guard observing else { return }
        centralManager.removeScan(forPeripheralsObserver: self)
        connectedPeripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral
        isConnecting.updateValue(false, forKey: connectedPeripheral!)
        delegate?.didConnect(to: connectedPeripheral)
    }

    @objc private func didDisconnectPeripheral(notification: Notification) {
        guard observing else { return }
        let peripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral
        if let peripheral = peripheral {
            isConnecting.updateValue(false, forKey: peripheral)
        }
        delegate?.didDisconnect(from: peripheral)
    }

    @objc private func didFailToConnectPeripheral(notification: Notification) {
        guard observing else { return }
        let peripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral
        if let peripheral = peripheral {
            isConnecting.updateValue(false, forKey: peripheral)
        }
        delegate?.didFailToConnect(to: peripheral)
    }
}
