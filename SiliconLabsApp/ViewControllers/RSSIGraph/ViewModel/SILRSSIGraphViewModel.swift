//
//  SILRSSIGraphViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 01/03/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

struct SILRSSIGraphDiscoveredPeripheralData {
    var color: UIColor
    let peripheral: SILDiscoveredPeripheral
    var isSelected: Bool
    let uuid: String
    let name: String
    
    var lastRSSIMeasurement: Int {
        return peripheral.rssiMeasurementTable.lastRSSIMeasurement()?.intValue ?? 0
    }
}

class SILRSSGraphViewModel {
    
    private var filterHelper = PeripheralDataFilterHelper()
    
    lazy var filter: BehaviorRelay<FilterClosure> = BehaviorRelay(value: filterHelper.getFilterOfType(.none))
    
    lazy var selected: PublishRelay<[PeripheralData]> = PublishRelay()
    
    lazy var refresh = PublishRelay<Void>()
    
    private lazy var _peripherals = BehaviorRelay<[PeripheralData]>(value: [])
    
    lazy var peripherals = Observable.combineLatest(_peripherals, selected.startWith([]), filter)
        .map { (peripherals, selectedPeripherals, filter) -> [PeripheralData] in
            // filter
            var peripherals = peripherals.filter { filter($0) }

            // map selected
            if let selected = selectedPeripherals.first {
                peripherals = peripherals.map { PeripheralData(color: $0.uuid == selected.uuid ? $0.color : RSSIConstants.graphLineDisabled,
                                                               peripheral: $0.peripheral,
                                                               isSelected: $0.uuid == selected.uuid, uuid: $0.uuid, name: $0.name)
                }
            }
            
            return peripherals
        }

    private lazy var newPeripherals: Observable<PeripheralData> = centralManager
        .newDiscoveredPeripheral
        .map {
            PeripheralData(color: RSSIConstants.randomColor(), peripheral: $0, isSelected: false, uuid: $0.identityKey,
                           name: $0.advertisedLocalName ?? DefaultDeviceName)
        }
        .asObservable()
    
    lazy var exportEnable: Observable<Bool> = Observable.combineLatest(isScanning, _peripherals)
        .map { !($0 || $1.isEmpty)}
    
    var isScanning = BehaviorRelay<Bool>(value: false)
    
    lazy var blutoothDisabled: Observable<Bool> = centralManager.state
        .skip(1)
        .map { $0 != .poweredOn }
    
    private let centralManager: SILRSSIGraphCentralManager
    private let fileWriter = SILFileWriter(exportDirName: "SILRSSIGraphExport")
    
    private var disposeBag = DisposeBag()
    private var scanningDisposeBag = DisposeBag()
        
    deinit {
        debugPrint("SILRSSGraphViewModel deinit")
    }
    
    init() {
        self.centralManager = SILRSSIGraphCentralManager()
        
        isScanning.asObservable()
            .bind(with: self) { _self, isScanning in
                if isScanning {
                    _self.startScanning()
                } else {
                    _self.stopScanning()
                }
            }
            .disposed(by: disposeBag)
        
        selected.map { _ in () }
            .bind(to: refresh)
            .disposed(by: disposeBag)
        
        fileWriter.clearExportDir()
    }
    
    func applyFilter(_ filterViewModel: SILBrowserFilterViewModel) {
        var filters: [FilterClosure] = [{ _ in true }]
        if filterViewModel.isFilterActive() {
            let deviceName = filterViewModel.searchByDeviceName
            let minRSSI = filterViewModel.dBmValue
            let beaconTypes = filterViewModel.beaconTypes as! [SILBrowserBeaconType]
            let isFavourite = filterViewModel.isFavouriteFilterSet
            let isConnectable = filterViewModel.isConnectableFilterSet

            filters.append(contentsOf: [
                filterHelper.getFilterOfType(.deviceName(deviceName)),
                filterHelper.getFilterOfType(.rssiMinimum(minRSSI)),
                filterHelper.getFilterOfType(.beaconTypes(beaconTypes)),
                filterHelper.getFilterOfType(.isFavourite(isFavourite)),
                filterHelper.getFilterOfType(.isConnectable(isConnectable))
            ])
        }
        self.filter.accept(filterHelper.andFilters(filters))
    }
    
    private func startScanning() {
        _peripherals.accept([])
        
        centralManager
            .discoveredPeripherals
            .flatMap {
                Observable
                    .from( $0.map { peripheral in peripheral.rssiMeasurementTable.rssiMeasurements.asObservable() })
                    .merge()
                    .map { _ in Void() }
            }
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(to: refresh)
            .disposed(by: scanningDisposeBag)
        
        newPeripherals.asObservable()
            .filter { newPeripheral in !self._peripherals.value.contains(where: { $0.uuid == newPeripheral.uuid }) }
            .scan([PeripheralData]()) { $0 + [$1] }
            .bind(to: _peripherals)
            .disposed(by: scanningDisposeBag)
        
        peripherals.subscribe(onNext: { debugPrint($0.count) }).disposed(by: disposeBag)
    }
    
    private func stopScanning() {
        self.scanningDisposeBag = DisposeBag()
    }
    
    func sortByRSSI() {
        _peripherals.accept(_peripherals.value.sorted(by: { $0.lastRSSIMeasurement > $1.lastRSSIMeasurement }))
    }
    
    func export(onFinish: @escaping ([URL]) -> ()) {
        var fileUrls = [URL]()
        
        let csvString = createCSVString()
        let filePath = fileWriter.getFilePath(withName: getFileName(), fileExtension: "csv")
        
        if fileWriter.createEmptyFile(atPath: filePath) {
            if fileWriter.openFile(filePath: filePath) {
                _ = fileWriter.append(text: csvString)
                fileWriter.closeFile()
                fileUrls.append(fileWriter.getFileUrl(filePath: filePath))
            }
        }
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
            timer.invalidate()
            
            onFinish(fileUrls)
        })
    }
    
    private func getFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH:mm"
        return "export_rssi_\(dateFormatter.string(from: Date()))"
    }
    
    private func createCSVString() -> String {
        let discoveredPeripherals = _peripherals.value.map { $0.peripheral }
        var csvString = "peripheral name,peripheral uuid,timestamp,value\n"
        
        for peripheral in discoveredPeripherals {
            for measurement in peripheral.rssiMeasurementTable.rssiMeasurements.value {
                csvString.append(contentsOf: "\(peripheral.advertisedLocalName ?? DefaultDeviceName),\(peripheral.uuid),\(measurement.date),\(measurement.rssi)\n")
            }
        }
        return csvString
    }
}
