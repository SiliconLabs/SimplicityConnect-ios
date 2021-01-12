//
//  SILFilterBarViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 14.12.2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILFilterBarViewModel {
    private var currentFilter: SILBrowserFilterViewModel?
    var state: SILObservable<Bool> = SILObservable(initialValue: false)
    var filterParamters: SILObservable<String> = SILObservable(initialValue: "")
    
    func handleTap() {
        self.state.value = !self.state.value
    }
    
    func updateCurrentFilter(filter: SILBrowserFilterViewModel?) {
        self.currentFilter = filter
        self.state.value = false
        self.filterParamters.value = prepareParametersDescription()
    }
        
    private func prepareParametersDescription() -> String {
        var description: [String] = []
        if let currentFilter = currentFilter {
            if !currentFilter.isFilterActive() {
                return ""
            }
            
            if currentFilter.searchByDeviceName != "" {
                description.append(currentFilter.searchByDeviceName)
            }
            
            description.append(" > \(currentFilter.dBmValue)dBm")
            
            let beaconTypes = currentFilter.beaconTypes as! [SILBrowserBeaconType]
            for beacon in beaconTypes {
                if beacon.isSelected {
                    description.append("\(String(describing: beacon.beaconName!))")
                }
            }

            if currentFilter.isFavouriteFilterSet {
                description.append("favourites")
            }

            if currentFilter.isConnectableFilterSet {
                description.append("connectable")
            }
        }
        
        return description.joined(separator: ", ")
    }
}
