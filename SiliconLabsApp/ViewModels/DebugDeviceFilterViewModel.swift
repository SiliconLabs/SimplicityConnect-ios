//
//  DebugDeviceFilterViewModel.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 8/3/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import Foundation

final class DebugDeviceFilterViewModel {

    // MARK: - Properties

    enum FilterType: Int {
        case name
        case rssi

        static var allTypes = [name, rssi]
    }

    enum Filter: Hashable {
        case name(containing: String)
        case rssi(greaterThan: Int)

        // Ensures that the filter Set will never have more than 1 type of filter in the set.
        func hash(into hasher: inout Hasher) {
            hasher.combine(FilterType.allTypes.filter({ self ~= $0 }).first?.hashValue ?? 0)
        }

        static func ==(lhs: DebugDeviceFilterViewModel.Filter, rhs: DebugDeviceFilterViewModel.Filter) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }

        func associatedValue() -> Any {
            switch self {
            case .name(let value):
                return value
            case .rssi(let value):
                return value
            }
        }

        static func ~=(filter: Filter, type: FilterType) -> Bool {
            switch filter {
            case .name where type == .name: fallthrough
            case .rssi where type == .rssi: return true
            default: return false
            }
        }
    }

    private(set) var filters: Set<Filter> = []

    var numberOfFiltersAvailable: Int {
        return 2
    }

    var nameQuery: String? {
        return value(for: .name)
    }

    var rssi: Int? {
        return value(for: .rssi)
    }

    // MARK: - Actions

    func resetFilter() {
        filters.removeAll()
    }

    func applyFilter(_ filter: Filter) {
        filters.update(with: filter)
    }

    func removeFilter(of type: FilterType) {
        if let filter = filters.filter({ $0 ~= type }).first {
            filters.remove(filter)
        }
    }

    func value<T>(for filterType: FilterType, type: T.Type = T.self) -> T? {
        return filters.filter({ $0 ~= filterType }).first?.associatedValue() as? T
    }
}
