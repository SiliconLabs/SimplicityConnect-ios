//
//  SILGattConfiguratorServiceHelperSpec.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 01/04/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@testable import BlueGecko

import Foundation
import Quick
import Nimble
import RealmSwift

class SILGattConfiguratorServiceHelperSpec: QuickSpec {
    
    override func spec() {
        var repository: SILGattConfigurationRepository!
        
        beforeSuite {
            Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
            repository = SILGattConfigurationRepository()
        }
        
        beforeEach {
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }
        }
        
        context("SILGattConfiguratorServiceHelper") {
            describe("services") {
                it("should return the same number of services") {
                    let configurationEntity = SILGattConfigurationEntity()
                    let service1 = SILGattConfigurationServiceEntity()
                    service1.cbuuidString = CBUUID(string: "71da3fd1-7e10-41c1-b16f-4430b506cde7").uuidString
                    let service2 = SILGattConfigurationServiceEntity()
                    service2.cbuuidString = CBUUID(string: "71da3fd1-7e10-41c1-b16f-4430b506cde8").uuidString
                    let services = [service1, service2]
                    for service in services {
                        repository.add(service: service)
                        configurationEntity.services.append(service)
                    }
                    let helper = SILGattConfiguratorServiceHelper(configuration: configurationEntity)
                    let result = helper.services
                    expect(result.count).to(equal(services.count))
                }
                
                it("should set proper isPrimary for created services") {
                    let configurationEntity = SILGattConfigurationEntity()
                    let testService = SILGattConfigurationServiceEntity()
                    testService.cbuuidString = CBUUID(string: "71da3fd1-7e10-41c1-b16f-4430b506cde7").uuidString
                    testService.isPrimary = false
                    repository.add(service: testService)
                    configurationEntity.services.append(testService)
                    let helper = SILGattConfiguratorServiceHelper(configuration: configurationEntity)
                    let result = helper.services
                    expect(result[0].isPrimary).to(beFalse())
                }
            }
            describe("init") {
                it("should service have the same size in configuration") {
                    let configurationEntity = SILGattConfigurationEntity()
                    let service1 = SILGattConfigurationServiceEntity()
                    service1.cbuuidString = CBUUID(string: "71da3fd1-7e10-41c1-b16f-4430b506cde7").uuidString
                    let service2 = SILGattConfigurationServiceEntity()
                    service2.cbuuidString = CBUUID(string: "71da3fd1-7e10-41c1-b16f-4430b506cde8").uuidString
                    let services = [service1, service2]
                    for service in services {
                        repository.add(service: service)
                        configurationEntity.services.append(service)
                    }
                    let helper = SILGattConfiguratorServiceHelper(configuration: configurationEntity)
                    let result = helper.services
                    expect(result.count).to(equal(services.count))
                }
                
                it("should service have set proper isPrimary for created services") {
                    let configurationEntity = SILGattConfigurationEntity()
                    let testService = SILGattConfigurationServiceEntity()
                    testService.cbuuidString = CBUUID(string: "71da3fd1-7e10-41c1-b16f-4430b506cde7").uuidString
                    testService.isPrimary = false
                    repository.add(service: testService)
                    configurationEntity.services.append(testService)
                    let helper = SILGattConfiguratorServiceHelper(configuration: configurationEntity)
                    let result = helper.services
                    expect(result[0].isPrimary).to(beFalse())
                }
            }
        }
        
    }
}
