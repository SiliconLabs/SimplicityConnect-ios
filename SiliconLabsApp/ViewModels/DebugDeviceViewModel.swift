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

    private struct Constants {
        static let scanInterval: TimeInterval = 15
    }

    weak var delegate: DebugDeviceViewModelDelegate? = nil

    let centralManager = SILCentralManager(serviceUUIDs: [])
    private var discoveredPeripherals: [SILDiscoveredPeripheral] = []
    private(set) var discoveredPeripheralsViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    var connectedPeripheral: CBPeripheral? = nil
    private(set) var isConnecting: Bool = false
    var isContentAvailable: Bool {
        return !isConnecting && discoveredPeripherals.count > 0
    }
    var observing = false

    private var scanTimer: Timer? = nil

    var currentMinRSSI: NSNumber? = nil {
        didSet {
            refreshDiscoveredPeripheralViewModels()
        }
    }
    var searchQuery: String? = nil {
        didSet {
            refreshDiscoveredPeripheralViewModels()
        }
    }

    var peripheralDisconnectedMessage: String? {
        guard let peripheral = connectedPeripheral else { return nil }
        let peripheralName = peripheral.name ?? "Unknown"
        return "Disconnected from \(peripheralName)"
    }

    var isFilterApplied: Bool {
        if searchQuery != nil || currentMinRSSI != nil {
            return true
        }
        return false
    }

    var filterDescription: String? {
        var descriptors = [String]()
        if let searchQuery = searchQuery {
            descriptors.append(searchQuery)
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

    func removeAllDiscoveredPeripherals() {
        centralManager.removeAllDiscoveredPeripherals()
        discoveredPeripherals = []
        discoveredPeripheralsViewModels = []
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
            isConnecting = true
        } else {
            isConnecting = false
        }
        return isConnecting
    }

    func resetFilter() {
        set(query: nil, minRSSI: nil)
    }

    @objc(setSearchQuery:minRSSI:)
    func set(query: String?, minRSSI: NSNumber?) {
        self.searchQuery = query
        self.currentMinRSSI = minRSSI
    }

    // MARK: Scanning

    func startScanning() {
        centralManager.addScan(forPeripheralsObserver: self, selector: #selector(didReceiveScanForPeripheralChange))
        scanTimer = Timer.scheduledTimer(timeInterval: Constants.scanInterval,
                                         target: self,
                                         selector: #selector(scanIntervalTimerFired),
                                         userInfo: nil,
                                         repeats: false)
    }

    @objc private func scanIntervalTimerFired() {
        stopScanning()
        delegate?.scanningDidEnd()
    }

    func stopScanning() {
        centralManager.removeScan(forPeripheralsObserver: self)
        discoveredPeripherals = centralManager.discoveredPeripherals()
        scanTimer?.invalidate()
        scanTimer = nil
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
        var peripheralViewModels = [SILDiscoveredPeripheralDisplayDataViewModel]()
        
        for peripheral in discoveredPeripherals {
            guard centralManager.canConnect(to: peripheral) else { continue }

            let discoveredPeripheralDisplayData = SILDiscoveredPeripheralDisplayData(discoveredPeripheral: peripheral)
            guard let peripheralViewModel = SILDiscoveredPeripheralDisplayDataViewModel(discoveredPeripheralDisplayData: discoveredPeripheralDisplayData) else { continue }

            peripheralViewModels.append(peripheralViewModel)
        }

        if let currentMinRSSI = currentMinRSSI {
            let rssiPredicate = NSPredicate(format: "discoveredPeripheralDisplayData.discoveredPeripheral.RSSIMeasurementTable.lastRSSIMeasurement.intValue > \(currentMinRSSI)")
            peripheralViewModels = peripheralViewModels.filter { rssiPredicate.evaluate(with: $0) }
        }

        if let searchQuery = searchQuery {
            let namePredicate = NSPredicate(format: "discoveredPeripheralDisplayData.discoveredPeripheral.advertisedLocalName CONTAINS[cd] %@", searchQuery)
            peripheralViewModels = peripheralViewModels.filter { namePredicate.evaluate(with: $0) }
        }

        peripheralViewModels = peripheralViewModels
            .filter({ $0.discoveredPeripheralDisplayData.discoveredPeripheral.rssiMeasurementTable.lastRSSIMeasurement() != nil })
            .sorted(by: {
                $0.discoveredPeripheralDisplayData.discoveredPeripheral.rssiMeasurementTable.lastRSSIMeasurement().intValue >
                $1.discoveredPeripheralDisplayData.discoveredPeripheral.rssiMeasurementTable.lastRSSIMeasurement().intValue
            })
        discoveredPeripheralsViewModels = peripheralViewModels
    }

    // MARK: Notifcation Methods

    @objc private func didConnectPeripheral(notification: Notification) {
        guard observing else { return }
        centralManager.removeScan(forPeripheralsObserver: self)
        connectedPeripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral
        isConnecting = false
        delegate?.didConnect(to: connectedPeripheral)
    }

    @objc private func didDisconnectPeripheral(notification: Notification) {
        guard observing else { return }
        isConnecting = false
        let peripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral
        delegate?.didDisconnect(from: peripheral)
    }

    @objc private func didFailToConnectPeripheral(notification: Notification) {
        guard observing else { return }
        isConnecting = false
        let peripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral
        delegate?.didFailToConnect(to: peripheral)
    }
}
