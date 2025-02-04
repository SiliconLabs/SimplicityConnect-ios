//
//  BrowserViewModel.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 7/20/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth
import AudioToolbox

@objc(SILDebugDeviceViewModelDelegate)
protocol DebugDeviceViewModelDelegate: class {
    func presentDeviceView(peripheral: CBPeripheral, centralManager: SILCentralManager)
    func presentAlert(title: String, message: String)
}

let HapticFeedback: SystemSoundID = 1520

@objc(SILBrowserViewModel)
@objcMembers
final class BrowserViewModel: NSObject, SILBrowserFilterViewControllerDelegate {

    // MARK: - Properties

    weak var delegate: DebugDeviceViewModelDelegate? = nil

    let centralManager: SILCentralManager
    let connectionsViewModel: SILBrowserConnectionsViewModel = SILBrowserConnectionsViewModel.sharedInstance()
    private var discoveredPeripherals: [SILDiscoveredPeripheral] = []
    private var allDiscoveredPeripheralsViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    private(set) var discoveredPeripheralsViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    private var replacementDiscoveredPeripheralViewModels: [SILDiscoveredPeripheralDisplayDataViewModel] = []
    private var shouldStartReplacementMode = false
    var isContentAvailable: Bool {
        return discoveredPeripheralsViewModels.count > 0
    }
    var isActiveScrollingUp = false
    var observing = false
    private(set) var isScanning = false
    private var tableRefreshTimer : Timer?
    
    private var currentMinRSSI: NSNumber? = nil
    private var currentMaxRSSI: NSNumber? = nil

    private var searchByDeviceName: String? = nil
    private var beaconTypes: [SILBrowserBeaconType]? = nil
    private var isFavourite: Bool = false
    private var isConnectable: Bool = false
    
    // MARK: - Lifecycle

    override init() {
        self.centralManager = connectionsViewModel.centralManager!
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
        allDiscoveredPeripheralsViewModels = []
    }

    func peripheralViewModel(at row: Int) -> SILDiscoveredPeripheralDisplayDataViewModel? {
        guard row < discoveredPeripheralsViewModels.count else { return nil }
        return discoveredPeripheralsViewModels[row]
    }
    
    func connectOrDisconnect(_ peripheralViewModel: SILDiscoveredPeripheralDisplayDataViewModel) {
        if connectionsViewModel.isConnectedPeripheral(peripheralViewModel.discoveredPeripheral.peripheral) {
            connectionsViewModel.disconnectPeripheral(withIdentifier: peripheralViewModel.discoveredPeripheral.identityKey)
        } else {
            connect(to: peripheralViewModel)
        }
    }

    private func connect(to peripheralViewModel: SILDiscoveredPeripheralDisplayDataViewModel) {
        if let discoveredPeripheral = peripheralViewModel.discoveredPeripheral,
            discoveredPeripheral.isConnectable,
            centralManager.canConnect(to: discoveredPeripheral) {
            centralManager.connect(to: discoveredPeripheral)
            peripheralViewModel.isConnecting = true
        } else {
            peripheralViewModel.isConnecting = false
        }
    }

    func isPeripheralConnecting(_ peripheral: CBPeripheral) -> Bool {
        peripheralViewModel(peripheral: peripheral)?.isConnecting == true
    }
    
    func peripheralViewModel(peripheral: CBPeripheral) -> SILDiscoveredPeripheralDisplayDataViewModel? {
        discoveredPeripheralsViewModels.first { viewModel in
            viewModel.discoveredPeripheral.peripheral!.identifier.uuidString == peripheral.identifier.uuidString
        }
    }

    // Apply Filters delegate funciton 
    @objc func applyFilters(_ filterVM : SILBrowserFilterViewModel?) {
        self.searchByDeviceName = filterVM?.searchByDeviceName
        self.currentMinRSSI = filterVM?.dBmValue ?? -100 > -100 ? filterVM?.dBmValue.number : nil
        self.currentMaxRSSI = filterVM?.dBmMaxValue ?? -0 < -0 ? filterVM?.dBmMaxValue.number : nil
        
        if (self.currentMinRSSI != -100 && currentMaxRSSI == nil) {
            currentMaxRSSI = 0
        } else if (self.currentMinRSSI == nil && currentMaxRSSI != 0) {
            currentMinRSSI = -100
        }
        self.isFavourite = filterVM?.isFavouriteFilterSet ?? false
        self.isConnectable = filterVM?.isConnectableFilterSet ?? false
        self.beaconTypes = filterVM?.beaconTypes as? [SILBrowserBeaconType]
        
        self.refreshDiscoveredPeripheralViewModels()
        startScanning()
    }

    // MARK: - Scanning
    
    // Start/stop Scan funciton
    func scanningButtonTapped() {
        ScannerTabSettings.sharedInstance.scanningPausedByUser = isScanning
        if !isScanning {
            ScannerTabSettings.sharedInstance.scanningStartedTime = Date()
            startScanning()
        }else {
            stopScanning()
        }
    }

    func startScanning() {
        isScanning = true
        if SILAppDelegate.supportsHaptics {
            AudioServicesPlaySystemSound(SystemSoundID(HapticFeedback))
        }
        tableRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.refreshDiscoveredPeripheralViewModels()
        })
        centralManager.addScan(forPeripheralsObserver: self, selector: #selector(didReceiveScanForPeripheralChange))
        preparePeripheralsForCalculatingAdvertisingIntervals()
    }
    // scan flow
    func stopScanning() {
        isScanning = false
        tableRefreshTimer?.invalidate()
        tableRefreshTimer = nil
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
                    let old = allDiscoveredPeripheralsViewModels[index]
                    replacement.discoveredPeripheral.isFavourite = old.discoveredPeripheral.isFavourite
                    replacement.isExpanded = old.isExpanded
                    replacement.isConnecting = old.isConnecting
                    allDiscoveredPeripheralsViewModels[index] = replacement
                }
            }
        }
    }
    
    private func firstIndexOfReplacement(device: SILDiscoveredPeripheralDisplayDataViewModel) -> Int? {
        let firstIndex = replacementDiscoveredPeripheralViewModels.firstIndex(where: {  $0.discoveredPeripheral.identityKey == device.discoveredPeripheral.identityKey
        })
        
        return firstIndex
    }
    
    // MARK: - Usual case
    // (scanning is running currently)
    
    private func discoverForCurrentArrayPeripheralDevices() -> [SILDiscoveredPeripheralDisplayDataViewModel] {
        var peripheralViewModels = [SILDiscoveredPeripheralDisplayDataViewModel]()
        
        for peripheral in discoveredPeripherals {
            guard centralManager.canConnect(to: peripheral) else { continue }

            guard let peripheralViewModel = SILDiscoveredPeripheralDisplayDataViewModel(discoveredPeripheralDisplayData: peripheral) else { continue }
            
            peripheralViewModels = peripheralViewModels.filter({ $0.discoveredPeripheral.rssiMeasurementTable.lastRSSIMeasurement() != nil })
            
            peripheralViewModels.append(peripheralViewModel)
        }
        
        return peripheralViewModels
    }
    
    private func addNewDevicesIfNeed(_ peripheralViewModels: [SILDiscoveredPeripheralDisplayDataViewModel]) {
        for peripheralDevice in peripheralViewModels {
            if !arrayContainDevice(peripheralDevice, in: allDiscoveredPeripheralsViewModels) {
                if (SILFavoritePeripheral.isFavorite(peripheralDevice.discoveredPeripheral)) {
                    peripheralDevice.discoveredPeripheral.isFavourite = true
                    allDiscoveredPeripheralsViewModels.insert(peripheralDevice, at: 0)
                } else {
                    allDiscoveredPeripheralsViewModels.append(peripheralDevice)
                }
            }
        }
    }
    
    private func removeAndSortDiscoveredDevicesIfNeed(filtering: Bool = false) {
        let oldPeripherals = discoveredPeripheralsViewModels
        setupDevicesForFilterAndSorting()
        filterDevices()
        if shouldStartReplacementMode && !filtering {
            shouldStartReplacementMode = false
        }
        if oldPeripherals != discoveredPeripheralsViewModels {
            postReloadBrowserTable()
        } else {
            postRefreshBrowserTable()
        }
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
        guard let currentMinRSSI = currentMinRSSI, let currentMaxRSSI = currentMaxRSSI else {
            return
        }
        //print("selected currentMinRSSI vaule ===== \(currentMinRSSI)")
        //print("selected currentMaxRSSI vaule ===== \(currentMaxRSSI)")
        discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter { viewModel in
            if let lastRSSI = viewModel.discoveredPeripheral.rssiMeasurementTable.lastRSSIMeasurement() {
                return lastRSSI.compare(currentMinRSSI) == .orderedDescending &&
                       lastRSSI.compare(currentMaxRSSI) == .orderedAscending
            }
            return false
        }
        //print("Filtered Devices Count - \(discoveredPeripheralsViewModels.count)")
    }
    
    private func filterBySearchDeviceName() {
        guard let searchByDeviceName, !searchByDeviceName.isEmpty else { return }

        discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter {
            $0.discoveredPeripheral.advertisedLocalName?.localizedCaseInsensitiveContains(searchByDeviceName) ?? false
        }
    }
    
    private func filterByBeaconTypes() {
        guard let beaconTypes,
              beaconTypes.contains(where: { $0.isSelected }) else { return }
        let beaconNames = beaconTypes.filter { $0.isSelected }.compactMap { $0.beaconName }
        
        discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter { viewModel in
            beaconNames.contains(where: { beaconName in  viewModel.discoveredPeripheral.beacon.name.localizedCaseInsensitiveContains(beaconName)
            })
        }
    }
    
    private func filterByIsFavourite() {
        guard isFavourite == true else { return }
        discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter {
            $0.discoveredPeripheral.isFavourite
        }
    }
    
    private func filterByIsConnectable() {
        guard isConnectable == true else { return }
        discoveredPeripheralsViewModels = discoveredPeripheralsViewModels.filter {
            $0.discoveredPeripheral.isConnectable
        }
    }
    
    // MARK: - Sorting
    func sortRSSI(ascending: Bool) {
        allDiscoveredPeripheralsViewModels = allDiscoveredPeripheralsViewModels.sorted(by: { (first, second) in
            let firstRSSI = first.discoveredPeripheral.rssiValue()?.intValue ?? 0
            let secondRSSI = second.discoveredPeripheral.rssiValue()?.intValue ?? 0
            if ascending {
                return firstRSSI < secondRSSI
            } else {
                return firstRSSI > secondRSSI
            }
        })
        self.postReloadBrowserTable()
    }
        
    // MARK: - Post Notifications
    
    func postReloadBrowserTable() {
        NotificationCenter.default.post(name: Notification.Name(SILNotificationReloadBrowserTable), object: nil)
    }
    
    func postRefreshBrowserTable() {
        NotificationCenter.default.post(name: Notification.Name(SILNotificationRefreshBrowserTable), object: nil)
    }
    
    // MARK: - Notifcation Methods

    @objc private func didConnectPeripheral(notification: Notification) {
        guard observing else { return }
        centralManager.removeScan(forPeripheralsObserver: self)
        guard let connectedPeripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral else { return }
        
        updatePeripheralIsConnecting(connectedPeripheral)
        delegate?.presentDeviceView(peripheral: connectedPeripheral, centralManager: self.centralManager)
    }

    @objc private func didDisconnectPeripheral(notification: Notification) {
        guard observing else { return }
        let peripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral
        
        updatePeripheralIsConnecting(peripheral)
    }

    @objc private func didFailToConnectPeripheral(notification: Notification) {
        guard observing else { return }
        let peripheral = notification.userInfo?[SILCentralManagerPeripheralKey] as? CBPeripheral
        var peerRemovedPairingInformation = false
        if let error = notification.userInfo?[SILCentralManagerErrorKey] as? CBError {
            if #available(iOS 13.4, *) {
                peerRemovedPairingInformation = error.code == .peerRemovedPairingInformation
            } else {
                peerRemovedPairingInformation = false
            }
        }
        
        updatePeripheralIsConnecting(peripheral)
        if peerRemovedPairingInformation {
            delegate?.presentAlert(title: "Error", message: SILPeerRemovedPairingMessage)
        }
    }
    
    fileprivate func updatePeripheralIsConnecting(_ peripheral: CBPeripheral?) {
        if let peripheral = peripheral {
            peripheralViewModel(peripheral: peripheral)?.isConnecting = false
        }
    }
    
    @objc private func bluetoothIsDisabled(notification: Notification) {
        let alert = SILBluetoothDisabledAlert.browser
        delegate?.presentAlert(title: alert.title, message: alert.message)
    }
    
    // MARK: - Utils
    
    private func arrayContainDevice(_ device: SILDiscoveredPeripheralDisplayDataViewModel, in collection: [SILDiscoveredPeripheralDisplayDataViewModel]) -> Bool {
        let containDevice = collection.contains(where: {  $0.discoveredPeripheral.identityKey == device.discoveredPeripheral.identityKey
        })
        
        return containDevice
    }
      
}
