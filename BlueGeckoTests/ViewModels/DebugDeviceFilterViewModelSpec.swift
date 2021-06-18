//
//  DebugDeviceFilterViewModelSpec.swift
//  SiliconLabsAppTests
//
//  Created by Grzegorz Janosz on 24/02/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import BlueGecko

class DebugDeviceFilterViewModelSpec: QuickSpec {
    
    override func spec() {
        describe("filter") {
            var model: DebugDeviceFilterViewModel!
            beforeEach {
                model = DebugDeviceFilterViewModel()
            }
            
            it("should has the same name after applaying") {
                let nameQuery = "Max"
                model.applyFilter(.name(containing: nameQuery))
                expect(model.nameQuery).to(equal(nameQuery))
            }
            
            it("should has the same rssi after applaying") {
                let rssi = -50
                model.applyFilter(.rssi(greaterThan: rssi))
                expect(model.rssi).to(equal(rssi))
            }
            
            it("should has the same name and rssi as filter type") {
                expect(DebugDeviceFilterViewModel.Filter.name(containing: "") ~= DebugDeviceFilterViewModel.FilterType.name).to(beTrue())
                expect(DebugDeviceFilterViewModel.Filter.rssi(greaterThan: 0) ~= DebugDeviceFilterViewModel.FilterType.rssi).to(beTrue())
            }
            
            it("should has one filter after applying one") {
                model.applyFilter(DebugDeviceFilterViewModel.Filter.name(containing: "Litteral"))
                expect(model.filters.count).to(equal(1))
            }
            
            it("should has zero filters after reset") {
                model.applyFilter(DebugDeviceFilterViewModel.Filter.name(containing: "Litteral"));
                model.resetFilter()
                expect(model.filters.count).to(equal(0))
            }
            
            it("should has one filter less after remove") {
                model.applyFilter(DebugDeviceFilterViewModel.Filter.name(containing: "bluetooth"));
                model.applyFilter(DebugDeviceFilterViewModel.Filter.rssi(greaterThan: 0));
                let filtersCount = model.filters.count
                model.removeFilter(of: .name)
                expect(model.filters.count).to(equal(filtersCount - 1))
            }
        }
    }
}
