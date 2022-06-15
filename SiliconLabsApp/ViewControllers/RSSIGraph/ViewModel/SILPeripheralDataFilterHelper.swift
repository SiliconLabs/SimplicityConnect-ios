//
//  SILPeripheralDataFilterHelper.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 06/04/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

typealias PeripheralData = SILRSSIGraphDiscoveredPeripheralData
typealias FilterClosure = (PeripheralData) -> Bool

struct PeripheralDataFilterHelper {
    
    enum FilterType: Hashable {
        case deviceName(_ name: String)
        case rssiMinimum(_ minRSSI: Int)
        case beaconTypes(_ beaconTypes: [SILBrowserBeaconType])
        case isFavourite(_ isFavourite: Bool)
        case isConnectable(_ isConnectable: Bool)
        case none
    }
    
    let noneFilter: FilterClosure = { _ in return true }
    
    func getFilterOfType(_ type: FilterType) -> FilterClosure {
        switch type {
        case let .deviceName(name):
            return !name.isEmpty ? { $0.name.contains(name) } : noneFilter
        case let .rssiMinimum(minRSSI):
            return { $0.lastRSSIMeasurement > minRSSI }
        case let .beaconTypes(beaconTypes):
            let selectedBeaconTypes = beaconTypes.filter { $0.isSelected }
            var selectedBeaconTypesFilters: [FilterClosure] = [noneFilter]
            for beaconType in selectedBeaconTypes {
                selectedBeaconTypesFilters.append({ peripheralData in
                    peripheralData.peripheral.beacon.name.contains(beaconType.beaconName)
                })
            }
            return orFilters(selectedBeaconTypesFilters)
        case let .isFavourite(isFavourite):
            return isFavourite ? { $0.peripheral.isFavourite } : noneFilter
        case let .isConnectable(isConnectable):
            return isConnectable ? { $0.peripheral.isConnectable } : noneFilter
        case .none:
            return noneFilter
        }
    }
    
    func orFilters(_ closures: [FilterClosure]) -> FilterClosure {
        return { listElement in closures.reduce(false, { $0 || $1(listElement) }) }
    }
    
    func andFilters(_ closures: [FilterClosure]) -> FilterClosure {
        return { listElement in closures.reduce(true, { $0 && $1(listElement) }) }
    }
}
