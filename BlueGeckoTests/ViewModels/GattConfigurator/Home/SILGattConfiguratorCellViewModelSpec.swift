//
//  SILGattConfiguratorCellViewModelSpec.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 22/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import os
import Foundation
import Quick
import Nimble
import RealmSwift
@testable import BlueGecko

fileprivate class MockSILGattConfiguratorHomeWireframe : SILGattConfiguratorHomeWireframeType {
    
    var viewController: UIViewController
    var navigationController: UINavigationController?
    
    var configuration: SILGattConfigurationEntity?
    
    required init() {
        self.viewController = UIViewController()
    }
    
    required init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func showGattConfiguratorDetails(gattConfiguration: SILGattConfigurationEntity) {
        expect(self.configuration?.uuid == gattConfiguration.uuid).to(equal(true))
        expect(self.configuration?.name == gattConfiguration.name).to(equal(true))
        expect(self.configuration?.createdAt == gattConfiguration.createdAt).to(equal(true))
        expect(self.configuration?.services.count == gattConfiguration.services.count).to(equal(true))
    }
        
    func releaseViewController() { }
    
    func presentToastAlert(message: String, toastType: ToastType, shouldHasSizeOfText: Bool, completion: @escaping () -> ()) { }
    
    func presentContextMenu(sourceView: UIView, options: [ContextMenuOption]) { }
    
    func open(url: String) { }
    
    func showGattConfiguratorRemoveWarning(_ confirmAction: @escaping () -> ()) { }
    
    func dismissPopover() { }
}

fileprivate class MockSILGattConfiguratorService : SILGattConfiguratorServiceType {
    
    var runningGattConfiguration: SILObservable<SILGattConfigurationEntity?> = SILObservable(initialValue: nil)
    var blutoothEnabled: SILObservable<Bool> = SILObservable(initialValue: true)
    private var serviceActive = false
    
    
    func start(configuration: SILGattConfigurationEntity) {
        serviceActive = true
    }
    
    func stop() {
        serviceActive = false
    }
    
    func stopRunningGattConfiguration() {
        serviceActive = false
    }
    
    func isRunning(configuration: SILGattConfigurationEntity) -> Bool {
        return serviceActive
    }
}

fileprivate class MockSILGattConfiguratorRepository : SILGattConfigurationRepositoryType {
    func add(characteristic: SILGattConfigurationCharacteristicEntity) { }
    
    func update(characteristic: SILGattConfigurationCharacteristicEntity) { }
    
    func remove(characteristic: SILGattConfigurationCharacteristicEntity) { }
    
    var realm: Realm
    var addedConfigurations = 0
    private var configurations = [SILGattConfigurationEntity]()
    
    required init() {
        self.realm = try! Realm()
    }
    
    func getConfigurations() -> [SILGattConfigurationEntity] {
        return self.configurations }
    
    func getServices() -> [SILGattConfigurationServiceEntity] {
        return [SILGattConfigurationServiceEntity]()
    }
    
    func observeConfigurations(block: @escaping ([SILGattConfigurationEntity]) -> Void) -> () -> Void {
        let callback: () -> Void = { }
        return callback
    }
    
    func add(configuration: SILGattConfigurationEntity) {
        addedConfigurations = addedConfigurations + 1
        configurations.append(configuration)
    }
    
    func add(service: SILGattConfigurationServiceEntity) { }
    
    func update(configuration: SILGattConfigurationEntity) { }
    
    func update(service: SILGattConfigurationServiceEntity) { }
    
    func remove(configuration: SILGattConfigurationEntity) {
        expect(self.configurations.contains(configuration)).to(equal(true))
        if let index = configurations.firstIndex(of: configuration) {
            configurations.remove(at: index)
        }
        addedConfigurations = addedConfigurations - 1
    }
    
    func remove(service: SILGattConfigurationServiceEntity) { }
}

fileprivate class MockSILGattConfiguratorSettings: SILGattConfiguratorSettingsType {
    var gattConfiguratorRemoveSetting: Bool = false
    var gattConfiguratorNonSaveChangesExitWarning: Bool = false
}

class SILGattConfiguratorCellViewModelSpec: QuickSpec {
    fileprivate var repository: MockSILGattConfiguratorRepository!
    fileprivate var wireframe: MockSILGattConfiguratorHomeWireframe!
    fileprivate var service: MockSILGattConfiguratorService!
    fileprivate var settings: MockSILGattConfiguratorSettings!
    var configurationEntity: SILGattConfigurationEntity!
    var testObj: SILGattConfiguratorCellViewModel!
    
    let oslog = OSLog(subsystem: "\(Bundle.main.bundleIdentifier ?? "com.silabs.BlueGeckoDemoApp").unitTests", category: "SILGattConfiguratorCellViewModelTest")
    
    func log(_ message: String) {
        os_log("%@", log: self.oslog, type: .default, message)
    }
    
    override func spec() {
        beforeSuite {
            Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
        }
        
        beforeEach {
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }
            
            self.repository = MockSILGattConfiguratorRepository()
            self.wireframe = MockSILGattConfiguratorHomeWireframe()
            self.service = MockSILGattConfiguratorService()
            self.settings = MockSILGattConfiguratorSettings()
            self.configurationEntity = SILGattConfigurationEntity()
            self.configurationEntity.services.append(SILGattConfigurationServiceEntity())
            self.repository.add(configuration: self.configurationEntity)
            expect(self.repository.addedConfigurations).to(equal(1))
            self.testObj = SILGattConfiguratorCellViewModel(wireframe: self.wireframe,
                                                            service: self.service,
                                                            repository: self.repository,
                                                            settings: self.settings,
                                                            configuration: self.configurationEntity)
        }
        
        afterEach {
            self.repository = nil
            self.wireframe = nil
            self.service = nil
            self.configurationEntity = nil
            self.testObj = nil
        }
        
        describe("editConfiguration()") {
            it("should stop configations and show details screen") {
                self.wireframe.configuration = self.configurationEntity
                self.testObj.editConfiguration()
                expect(self.service.isRunning(configuration: self.configurationEntity)).to(equal(false))
            }
        }
        
        describe("toogleEnableSwitch(isOn:)") {
            it("should start service with parameter true") {
                self.testObj.toggleEnableSwitch(isOn: true)
                expect(self.service.isRunning(configuration: self.configurationEntity)).to(equal(true))
            }
            
            it("should stop service with parameter false") {
                self.testObj.toggleEnableSwitch(isOn: false)
                expect(self.service.isRunning(configuration: self.configurationEntity)).to(equal(false))
            }
        }

        describe("removeConfiguration()") {
            it("services was stoped and configuration removed") {
                self.testObj.removeConfiguration()
                expect(self.repository.addedConfigurations).to(equal(0))
            }
        }

        describe("copyConfiguration()") {
            it("configuration was copied and added to repository") {
                self.testObj.copyConfiguration()
                expect(self.repository.addedConfigurations).to(equal(2))
            }
        }
    }
}
