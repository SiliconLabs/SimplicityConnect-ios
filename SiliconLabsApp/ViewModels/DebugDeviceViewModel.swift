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
    func bluetoothIsDisabled()
    
    func scanningDidEnd()
}

@objc(SILDebugDeviceViewModel)
@objcMembers
final class DebugDeviceViewModel: NSObject {

    // MARK: - Properties

    weak var delegate: DebugDeviceViewModelDelegate? = nil

    let centralManager: SILCentralManager
    private var discoveredPeripherals: [SILDiscoveredPeripheral] = []
    private var allDiscoveredPeripheralsViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    private(set) var discoveredPeripheralsViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    private var replacementDiscoveredPeripheralViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    var connectedPeripheral: CBPeripheral? = nil
    private(set) var isConnecting: [CBPeripheral : Bool] = [:]
    private var shouldStartReplacementMode = false
    var isContentAvailable: Bool {
        return discoveredPeripheralsViewModels.count > 0
    }
    var observing = false

    var currentMinRSSI: NSNumber? = nil {
        didSet {
            removeAndSortDiscoveredDevicesIfNeed(filtering: true)
        }
    }
    
    var searchByDeviceName: String? = nil {
        didSet {
            removeAndSortDiscoveredDevicesIfNeed(filtering: true)
        }
    }
        
    var beaconTypes: [SILBrowserBeaconType]? = nil {
        didSet {
            removeAndSortDiscoveredDevicesIfNeed(filtering: true)
        }
    }

    var isFavourite: Bool = false {
        didSet {
            removeAndSortDiscoveredDevicesIfNeed(filtering: true)
        }
    }

    var isConnectable: Bool = false {
        didSet {
            removeAndSortDiscoveredDevicesIfNeed(filtering: true)
        }
    }
    
    var sortOption: SILSortOption = .none {
        didSet {
            removeAndSortDiscoveredDevicesIfNeed(filtering: true)
        }
    }

    var peripheralDisconnectedMessage: String? {
        guard let peripheral = connectedPeripheral else { return nil }
        let peripheralName = peripheral.name ?? DefaultDeviceName
        return "Disconnected from \(peripheralName)"
    }
    
    // MARK: - Lifecycle

    override init() {
        self.centralManager = SILBrowserConnectionsViewModel.sharedInstance()!.centralManager!
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

    // MARK: - Scanning

    func startScanning() {
        centralManager.addScan(forPeripheralsObserver: self, selector: #selector(didReceiveScanForPeripheralChange))
        preparePeripheralsForCalculatingAdvertisingIntervals()
    }

    func stopScanning() {
        shouldStartReplacementMode = allDiscoveredPeripheralsViewModels.count > 0
        centralManager.removeScan(forPeripheralsObserver: self)
        discoveredPeripherals = []
    }

    @objc private func didReceiveScanForPeripheralChange() {
        discoveredPeripherals = centralManager.discoveredPeripherals()
    }

    func refreshDiscoveredPeripheralViewModels() {
        let peripheralViewModels = discoverForCurrentArrayPeripheralDevices()
        
        if shouldStartReplacementMode {
           performActionsForStopScanningWasTapped(peripheralViewModels)
        } else {
            addNewDevicesIfNeed(peripheralViewModels)
            removeAndSortDiscoveredDevicesIfNeed()
        }
    }
    
    // MARK: - Private implementation

    private func preparePeripheralsForCalculatingAdvertisingIntervals() {
        for peripheral in discoveredPeripherals {
            peripheral.resetLastTimestampValue()
        }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectPeripheral(notification:)), name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectPeripheral(notification:)), name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFailToConnectPeripheral(notification:)), name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bluetoothIsDisabled(notification:)), name: .SILCentralManagerBluetoothDisabled, object: nil)
    }

    private func unregisterNotifications() {
        centralManager.removeScan(forPeripheralsObserver: self)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerBluetoothDisabled, object: nil)
    }
    
    // MARK: - Stop Scanning Was Tapped Case
    // There is huge possibility that Core Bluetooth is building peripherals arrays from scratch because of scanning was stopped on too long (more than 5 seconds)
    
    private func performActionsForStopScanningWasTapped(_ peripheralViewModels: [SILDiscoveredPeripheralDisplayDataViewModel]) {
        if replacementDiscoveredPeripheralViewModels.isEmpty {
            fillReplacementDiscoveredPeripheralViewModel(peripheralViewModels)
        } else {
            if isEqualToReplacementPeripheralsViewModel(peripheralViewModels) {
                replaceDevicesIfNeed(replacementDiscoveredPeripheralViewModels)
                removeAndSortDiscoveredDevicesIfNeed()
                replacementDiscoveredPeripheralViewModels = []
            } else {
                fillReplacementDiscoveredPeripheralViewModel(peripheralViewModels)
            }
        }
    }
    
    private func fillReplacementDiscoveredPeripheralViewModel(_ peripheralViewModels: [SILDiscoveredPeripheralDisplayDataViewModel]) {
        replacementDiscoveredPeripheralViewModels = peripheralViewModels
    }
    
    private func isEqualToReplacementPeripheralsViewModel(_ discoveredPeripherals: [SILDiscoveredPeripheralDisplayDataViewModel]) -> Bool {
        for peripheral in discoveredPeripherals {
            if !arrayContainDevice(peripheral, in: replacementDiscoveredPeripheralViewModels) {
                return false
            }
        }
        
        return true
    }
      
    private func replaceDevicesIfNeed(_ replaceViewModels: [SILDiscoveredPeripheralDisplayDataViewModel]) {
        for (index, peripheral) in allDiscoveredPeripheralsViewModels.enumerated() {
            if arrayContainDevice(peripheral, in: allDiscoveredPeripheralsViewModels) {
                if let firstIndex = firstIndexOfReplacement(device: peripheral) {
                    let replacement = replaceViewModels[firstIndex]
                    if (allDiscoveredPeripheralsViewModels[index].discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite) {
                        replacement.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite = true
                    }
                    allDiscoveredPeripheralsViewModels[index] = replacement
                }
            }
        }
    }
    
    private func firstIndexOfReplacement(device: SILDiscoveredPeripheralDisplayDataViewModel) -> Int? {
        let firstIndex = replacementDiscoveredPeripheralViewModels.firstIndex(where: {  $0.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey == device.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey
        })
        
        return firstIndex
    }
    
    // MARK: - Usual case
    // (scanning is running currently)
    
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
            if !arrayContainDevice(peripheralDevice, in: allDiscoveredPeripheralsViewModels) {
                if (SILFavoritePeripheral.isFavorite(peripheralDevice)) {
                    peripheralDevice.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite = true
                    allDiscoveredPeripheralsViewModels.insert(peripheralDevice, at: 0)
                } else {
                    allDiscoveredPeripheralsViewModels.append(peripheralDevice)
                }
            }
        }
    }
    
    private func removeAndSortDiscoveredDevicesIfNeed(filtering: Bool = false) {
        setupDevicesForFilterAndSorting()
        filterDevices()
        sortDevices()
        if shouldStartReplacementMode && !filtering {
            shouldStartReplacementMode = false
        }
        postReloadBrowserTable()
    }

    // MARK: - Filtering
    
    private func filterDevices() {
        filterByCurrentMinRSSI()
        filterBySearchDeviceName()
        filterByBeaconTypes()
        filterByIsFavourite()
        filterByIsConnectable()
    }
    
    private func setupDevicesForFilterAndSorting() {
        discoveredPeripheralsViewModels = allDiscoveredPeripheralsViewModels
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
    
    // MARK: - Sorting
    
    private func sortDevices() {
        switch self.sortOption {
        case .ascendingRSSI:
            sortRSSI(ascending: true)
        case .descendingRSSI:
            sortRSSI(ascending: false)
        case .AZ:
            sortName(aToZ: true)
        case .ZA:
            sortName(aToZ: false)
        case .none:
            return
        }
        moveFavoritesUp()
    }
    
    private func sortRSSI(ascending: Bool) {
        discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.sorted(by: { (first, second) in
            let firstRSSI = first.discoveredPeripheralDisplayData.discoveredPeripheral.rssiValue()?.intValue ?? 0
            let secondRSSI = second.discoveredPeripheralDisplayData.discoveredPeripheral.rssiValue()?.intValue ?? 0
            if ascending {
                return firstRSSI < secondRSSI
            } else {
                return firstRSSI > secondRSSI
            }
        })
    }
    
    private func sortName(aToZ: Bool) {
        discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.sorted(by: { (first, second) in
            let firstName = first.discoveredPeripheralDisplayData.discoveredPeripheral.advertisedLocalName ?? DefaultDeviceName
            let secondName = second.discoveredPeripheralDisplayData.discoveredPeripheral.advertisedLocalName ?? DefaultDeviceName
            if aToZ {
                return firstName < secondName
            } else {
                return firstName > secondName
            }
        })
    }
    
    func moveFavoritesUp() {
        if SILFavoritePeripheral.areFavoritePeripherals() {
            var peripheralsWithFavoritesAsFirst:[SILDiscoveredPeripheralDisplayDataViewModel] = []
            var index = 0
            for discoveredPeripheral in discoveredPeripheralsViewModels {
                if (SILFavoritePeripheral.isFavorite(discoveredPeripheral)) {
                    peripheralsWithFavoritesAsFirst.insert(discoveredPeripheral, at: index)
                    index += 1
                } else {
                    peripheralsWithFavoritesAsFirst.append(discoveredPeripheral)
                }
            }
            discoveredPeripheralsViewModels = peripheralsWithFavoritesAsFirst
        }
    }
        
    // MARK: - Post Notifications
    
    private func postReloadBrowserTable() {
        NotificationCenter.default.post(name: Notification.Name(SILNotificationReloadBrowserTable), object: nil)
    }
    
    // MARK: - Notifcation Methods

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
    
    @objc private func bluetoothIsDisabled(notification: Notification) {
        delegate?.bluetoothIsDisabled()
    }
    
    // MARK: - Utils
    
    private func arrayContainDevice(_ device: SILDiscoveredPeripheralDisplayDataViewModel, in collection: [SILDiscoveredPeripheralDisplayDataViewModel]) -> Bool {
        let containDevice = collection.contains(where: {  $0.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey == device.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey
        })
        
        return containDevice
    }
      
}
