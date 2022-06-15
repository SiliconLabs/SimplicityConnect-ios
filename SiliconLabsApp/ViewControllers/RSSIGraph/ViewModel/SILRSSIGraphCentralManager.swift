//
//  SILRSSIGraphCentralManager.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 01/03/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreBluetooth
import CoreLocation

fileprivate struct Constants {
    static let kIBeaconUUIDString = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
    static let kIBeaconIdentifier = "com.silabs.retailbeacon"
}

class SILRSSIGraphCentralManager: NSObject {
        
    private let centralManager = CBCentralManager()
    private let locationManager = CLLocationManager()
    
    private var regions = [CLBeaconRegion]()
    
    lazy var discoveredPeripherals: Observable<[SILDiscoveredPeripheral]> =
        discoveredPeripheralsMapping.asObservable()
        .map { Array($0.values) }
        .do(onSubscribe: { [weak self] in
            guard let sSelf = self else { return }
            sSelf.startScanning()
            sSelf.hasSubscribers = true
        }, onDispose: { [weak self] in
            guard let sSelf = self else { return }
            sSelf.hasSubscribers = false
            sSelf.stopScanning()
        })
        .share()
            
    lazy var newestDiscoveredPeripherals: Observable<[SILDiscoveredPeripheral]> =
            discoveredPeripherals
            .map { $0.filter { $0.rssiMeasurementTable.hasRSSIMeasurement(inPastTimeInterval: 5.0) } }
            
    var newDiscoveredPeripheral: PublishRelay<SILDiscoveredPeripheral> = PublishRelay()
    
    lazy var state: Observable<CBManagerState> = centralManager.rx.state.asObservable()
    
    private let discoveredPeripheralsMapping = BehaviorRelay<[String: SILDiscoveredPeripheral]>(value: [:])
    
    private var isScanning = false
    private var hasSubscribers = false
    
    private let disposeBag = DisposeBag()
    private var scanningDisposeBag = DisposeBag()

    override init() {
        super.init()

        setupBluetoothSubsciptions()
        setupBeaconMonitoring()
    }
    
    deinit {
        self.stopScanning()
        debugPrint("RSSIGraphCentralManager deinit")
    }
    
    private func setupBluetoothSubsciptions() {
        centralManager.rx.didDiscover
            .bind(with: self) { (_self, discoverData) in
                let (peripheral, advertisementData, RSSI) = discoverData
                if !_self.isProbablyIBeacon(advertisementData: advertisementData) {
                    _self.insertOrUpdateDiscoveredPeripheral(peripheral,
                                                            advertisementData: advertisementData,
                                                            rssi: RSSI,
                                                            andDiscoveringTimestamp: _self.getTimestampWithAdvertisementData(advertisementData))
                }
            }
            .disposed(by: disposeBag)
        centralManager.rx.state
            .bind(with: self) { (_self, state) in
                if state == .poweredOn && _self.hasSubscribers {
                    _self.startScanning()
                }
                if state == .poweredOff {
                    _self.stopScanning()
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func startScanning() {
        if centralManager.state == .poweredOn && !self.isScanning {
            self.removeAllDiscoveredPeripherals()
            self.isScanning = true
            debugPrint("SILRSSICentralManager: scan has run")
            self.centralManager.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
            self.startRanging()
        }
    }
    
    private func stopScanning() {
        if isScanning {
            self.scanningDisposeBag = DisposeBag()
            if centralManager.state == .poweredOn {
                centralManager.stopScan()
            }
            self.stopRanging()
            debugPrint("SILRSSICentralManager: scan has stopped")

            isScanning = false
        }
    }
    
    private func getTimestampWithAdvertisementData(_ advertisementData: [String : Any]) -> Double {
        if let stringValue = advertisementData["kCBAdvDataTimestamp"] as? String,
            let timestamp = Double(stringValue) {
            return timestamp
        }
        return Date().timeIntervalSinceReferenceDate
    }

    func discoveredPeripheral(for peripheral: CBPeripheral) -> SILDiscoveredPeripheral? {
        let peripheralIdentifier = SILDiscoveredPeripheralIdentifierProvider.provideKeyForCBPeripheral(peripheral)
        return self.discoveredPeripheralsMapping.value[peripheralIdentifier]
    }
    
    private func isProbablyIBeacon(advertisementData: [String: Any]) -> Bool {
        if let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool, isConnectable {
            return false
        }
        
        let nonIBeaconKeys = Set([
            CBAdvertisementDataManufacturerDataKey,
            CBAdvertisementDataLocalNameKey,
            CBAdvertisementDataServiceDataKey,
            CBAdvertisementDataServiceUUIDsKey,
            CBAdvertisementDataOverflowServiceUUIDsKey,
            CBAdvertisementDataTxPowerLevelKey,
            CBAdvertisementDataSolicitedServiceUUIDsKey
        ])
        
        return nonIBeaconKeys.intersection(Set(advertisementData.keys)).isEmpty
    }

    private func insertOrUpdateDiscoveredPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber, andDiscoveringTimestamp timestamp: Double) {
        let key = SILDiscoveredPeripheralIdentifierProvider.provideKeyForCBPeripheral(peripheral)
        if let discoveredPeripheral = self.discoveredPeripheralsMapping.value.first(where: { $0.key == key }) {
            discoveredPeripheral.value.update(withAdvertisementData: advertisementData, rssi: RSSI, andDiscoveringTimestamp: timestamp)
        } else {
            let discoveredPeripheral = SILDiscoveredPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI, andDiscoveringTimestamp: timestamp)
            self.discoveredPeripheralsMapping.addElement(key: key, value: discoveredPeripheral)
            self.newDiscoveredPeripheral.accept(discoveredPeripheral)
        }
    }
    
    func remove(discoveredPeripheral: SILDiscoveredPeripheral) {
        self.discoveredPeripheralsMapping.removeElement(key: discoveredPeripheral.identityKey)
    }
    
    func removeAllDiscoveredPeripherals() {
        self.discoveredPeripheralsMapping.accept([:])
    }
}

extension SILRSSIGraphCentralManager {
    private func setupBeaconMonitoring() {
        locationManager.requestAlwaysAuthorization()
        let iBeaconUUID = UUID(uuidString: Constants.kIBeaconUUIDString)!
        let beaconRegion = CLBeaconRegion(proximityUUID: iBeaconUUID, identifier: Constants.kIBeaconIdentifier)

        regions.append(beaconRegion)
        setupBeaconSubscriptions()
    }
    
    private func setupBeaconSubscriptions() {
        locationManager.rx.didEnterRegion
            .subscribe(onNext: { [unowned self] (region) in
                for beaconRegion in self.regions {
                    if beaconRegion == region {
                        self.locationManager.startRangingBeacons(in: beaconRegion)
                    }
                }
            })
            .disposed(by: disposeBag)
        locationManager.rx.didExitRegion
            .subscribe(onNext: { [unowned self] (region) in
                for beaconRegion in self.regions {
                    if beaconRegion == region {
                        self.locationManager.stopRangingBeacons(in: beaconRegion)
                    }
                }
            })
            .disposed(by: disposeBag)
        locationManager.rx.didRangeBeaconsInRegion
            .subscribe(onNext: { [unowned self] (beacons, region) in
                for foundBeacon in beacons {
                    if foundBeacon.rssi != 0 {
                        self.insertOrUpdateDiscoveredIBeacon(foundBeacon)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func startRanging() {
        for beaconRegion in regions {
            locationManager.startRangingBeacons(in: beaconRegion)
        }
    }

    private func stopRanging() {
        for beaconRegion in regions {
            locationManager.stopRangingBeacons(in: beaconRegion)
        }
    }
    
    private func insertOrUpdateDiscoveredIBeacon(_ iBeacon: CLBeacon) {
        let iBeaconIdentifier = SILDiscoveredPeripheralIdentifierProvider.provideKeyForCLBeacon(iBeacon)
        let timestamp = getTimestamptForIBeacons(iBeacon)
        
        if let discoveredPeripheral = self.discoveredPeripheralsMapping.value.first(where: { $0.key == iBeaconIdentifier }) {
            discoveredPeripheral.value.update(withIBeacon: iBeacon, andDiscoveringTimestamp: timestamp)
        } else {
            let discoveredPeripheral = SILDiscoveredPeripheral(iBeacon: iBeacon, andDiscoveringTimestamp: timestamp)
            
            self.discoveredPeripheralsMapping.addElement(key: iBeaconIdentifier, value: discoveredPeripheral)
            self.newDiscoveredPeripheral.accept(discoveredPeripheral)
        }
    }
    
    private func getTimestamptForIBeacons(_ iBeacon: CLBeacon) -> Double {
        if #available(iOS 13.0, *) {
            return iBeacon.timestamp.timeIntervalSinceReferenceDate
        } else {
            return Date().timeIntervalSinceReferenceDate
        }
    }
}
