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
        
    private let manager : SILCentralManager
    // START SCANNING
    lazy var discoveredPeripherals: Observable<[SILDiscoveredPeripheral]> =
    peripheralsFound.asObservable().throttle(.milliseconds(300), scheduler: MainScheduler.instance)
        .do(onSubscribe: { [weak self] in
            guard let sSelf = self else { return }
            sSelf.startScanning() // graph ss 
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
    
    lazy var state: Observable<CBManagerState> = manager.centralManager.rx.state.asObservable()
    
    private let peripheralsFound = BehaviorRelay<[SILDiscoveredPeripheral]>(value: [])
    
    private var isScanning = false
    private var hasSubscribers = false
    
    private let disposeBag = DisposeBag()
    private var scanningDisposeBag = DisposeBag()

    override init() {
        manager = SILBrowserConnectionsViewModel.sharedInstance().centralManager
        super.init()
        setupBluetoothSubsciptions()
    }
    
    deinit {
        self.stopScanning()
        debugPrint("RSSIGraphCentralManager deinit")
    }
    
    private func setupBluetoothSubsciptions() {
        manager.centralManager.rx.state.asObservable()
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
        peripheralsFound.accept([])
        manager.addScan(forPeripheralsObserver: self, selector: #selector(updatePeripherals))
    }
    
    @objc private func updatePeripherals() {
        let oldPeripherals = self.peripheralsFound.value
        let peripherals = manager.discoveredPeripherals()
        
        let newOnes = peripherals.filter{ p in
            let key = p.identityKey
            
            return !oldPeripherals.contains(where: { $0.identityKey == key })
        }
        
        newOnes.forEach {
            newDiscoveredPeripheral.accept($0)
        }
        
        self.peripheralsFound.accept(peripherals)
    }
    
    private func stopScanning() {
        self.scanningDisposeBag = DisposeBag()
        manager.removeScan(forPeripheralsObserver: self)
    }
}
