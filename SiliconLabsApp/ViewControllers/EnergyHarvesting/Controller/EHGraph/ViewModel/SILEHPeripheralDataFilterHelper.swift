//
//  EHPeripheralDataFilterHelper.swift
//  BlueGecko
//
//  Created by Mantosh Kumar on 02/10/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation

typealias EHPeripheralData = SILEHGraphDiscoveredPeripheralData
typealias EHFilterClosure = (EHPeripheralData) -> Bool

struct EHPeripheralDataFilterHelper {
    
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
            return !name.isEmpty ? { $0.name.lowercased().contains(name.lowercased()) } : noneFilter
        case let .rssiMinimum(minRSSI):
            return { $0.lastRSSIMeasurement > minRSSI }
        case let .beaconTypes(beaconTypes):
            let selectedBeaconTypes = beaconTypes.filter { $0.isSelected }
            var selectedBeaconTypesFilters: [FilterClosure] = selectedBeaconTypes.isEmpty ? [noneFilter] : []
            for beaconType in selectedBeaconTypes {
                selectedBeaconTypesFilters.append({ peripheralData in
                    peripheralData.peripheral.beacon.name.contains(beaconType.beaconName)
                })
            }
            return orFilters(selectedBeaconTypesFilters)
        case let .isFavourite(isFavourite):
            return isFavourite ? { SILFavoritePeripheral.isFavorite($0.peripheral) } : noneFilter
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
