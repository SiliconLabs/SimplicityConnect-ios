//
//  DebugDeviceFilterViewModelTests.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 8/7/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import XCTest
@testable import SiliconLabsApp

class DebugDeviceFilterViewModelTests: XCTestCase {

    func testFilterName() {
        let model = DebugDeviceFilterViewModel()
        let nameQuery = "Max"
        model.applyFilter(.name(containing: nameQuery))
        XCTAssertEqual(model.nameQuery, nameQuery)
    }

    func testFilterRSSI() {
        let model = DebugDeviceFilterViewModel()
        let rssi = -50
        model.applyFilter(.rssi(greaterThan: rssi))
        XCTAssertEqual(model.rssi, rssi)
    }

    func testFilterEqualToFilterType() {
        XCTAssertTrue(DebugDeviceFilterViewModel.Filter.name(containing: "") ~= DebugDeviceFilterViewModel.FilterType.name)
        XCTAssertTrue(DebugDeviceFilterViewModel.Filter.rssi(greaterThan: 0) ~= DebugDeviceFilterViewModel.FilterType.rssi)
    }

    func testResetFilters() {
        let model = DebugDeviceFilterViewModel()
        model.applyFilter(DebugDeviceFilterViewModel.Filter.name(containing: "Litteral"));
        XCTAssertEqual(model.filters.count, 1)
        model.resetFilter()
        XCTAssertEqual(model.filters.count, 0)
    }

    func testRemoveFilter() {
        let model = DebugDeviceFilterViewModel()
        model.applyFilter(DebugDeviceFilterViewModel.Filter.name(containing: "bluetooth"));
        model.applyFilter(DebugDeviceFilterViewModel.Filter.rssi(greaterThan: 0));
        model.removeFilter(of: .name)
        XCTAssertEqual(model.filters.count, 1)
        XCTAssertTrue(model.filters.contains(DebugDeviceFilterViewModel.Filter.rssi(greaterThan: 0)))
        model.removeFilter(of: .rssi)
        XCTAssertEqual(model.filters.count, 0)
    }
}
