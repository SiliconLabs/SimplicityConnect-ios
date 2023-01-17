//
//  SILGattConfiguratorHomeViewModelTest.swift
//  BlueGeckoTests
//
//  Created by Kamil Czajka on 19.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import os
import Foundation
import Quick
import Nimble
import RealmSwift
@testable import BlueGecko

fileprivate class MockSILGattConfigutatorHomeWireframe: SILGattConfiguratorHomeWireframeType {
    var menuPresented = false
    var sourceView: UIView?
    
    private var options : [ContextMenuOption]?
    
    required init() { }
    
    var viewController: UIViewController = UIViewController()
    var navigationController: UINavigationController?
    
    func releaseViewController() { }
    
    func presentToastAlert(message: String, toastType: ToastType, shouldHasSizeOfText: Bool, completion: @escaping () -> ()) { }
    
    func showGattConfiguratorRemoveWarning(_ confirmAction: @escaping () -> ()) { }
    
    func dismissPopover() { }
    
    func presentContextMenu(sourceView: UIView, options: [ContextMenuOption]) {
        menuPresented = true
        expect(self.sourceView === sourceView).to(equal(true))
        expect(options.count).to(equal(3))
        expect(options[0].enabled).to(equal(true))
        expect(options[0].title).to(equal("Create new"))
        
        expect(options[1].enabled).to(equal(true))
        expect(options[1].title).to(equal("Import"))
        
        expect(options[2].enabled).to(equal(false))
        expect(options[2].title).to(equal("Export"))
        
        self.options = options
    }
    
    func open(url: String) { }
    
    required init(viewController: UIViewController) { }
    
    func showGattConfiguratorDetails(gattConfiguration: SILGattConfigurationEntity) { }
    
    func invokeMenuOption0() {
        self.options?[0].callback()
    }
    
    func invokeMenuOption1() {
        self.options?[1].callback()
    }
    
    func invokeMenuOption2() {
        self.options?[2].callback()
    }
    
    func showBluetoothDisabledDialog() { }
    
    func showDocumentPickerView() { }
}

fileprivate class MockSILGattConfiguratorHomeViewDelegate : SILGattConfiguratorHomeViewDelegate {
    func updateConfigurations(configurations: [SILGattConfiguratorCellViewModel], checkBoxCells: [SILGattConfiguratorCheckBoxCellViewModel]) { }
    
    func popViewController() { }
}

fileprivate class MockSILGattConfiguratorService : SILGattConfiguratorServiceType {
    
    var runningGattConfiguration: SILObservable<SILGattConfigurationEntity?> = SILObservable(initialValue: nil)
    var blutoothEnabled: SILObservable<Bool> = SILObservable(initialValue: true)
        
    func start(configuration: SILGattConfigurationEntity) { }
    
    func stop() { }
    
    func stopRunningGattConfiguration() { }
    
    func isRunning(configuration: SILGattConfigurationEntity) -> Bool {
        return false
    }
}

fileprivate class MockSILGattConfigurationRepository : SILGattConfigurationRepositoryType {
    func add(characteristic: SILGattConfigurationCharacteristicEntity) { }
    
    func update(characteristic: SILGattConfigurationCharacteristicEntity) { }
    
    func remove(characteristic: SILGattConfigurationCharacteristicEntity) { }
    
    var realm: Realm
    var configutationCount = 0
    
    required init() {
        self.realm = try! Realm()
    }
    
    func getConfigurations() -> [SILGattConfigurationEntity] {
        return [SILGattConfigurationEntity]()
    }
    
    func getServices() -> [SILGattConfigurationServiceEntity] {
        return [SILGattConfigurationServiceEntity]()
    }
    
    func observeConfigurations(block: @escaping ([SILGattConfigurationEntity]) -> Void) -> () -> Void {
        let callback: () -> Void = { }
        return callback
    }
    
    func add(configuration: SILGattConfigurationEntity) {
        configutationCount = configutationCount + 1
        expect(configuration.name).to(equal("New GATT Server"))
        expect(configuration.services.count).to(equal(0))
    }
    
    func add(service: SILGattConfigurationServiceEntity) { }
    
    func update(configuration: SILGattConfigurationEntity) { }
    
    func update(service: SILGattConfigurationServiceEntity) { }
    
    func remove(configuration: SILGattConfigurationEntity) { }
    
    func remove(service: SILGattConfigurationServiceEntity) { }
}

fileprivate class MockSILGattConfiguratorSettings: SILGattConfiguratorSettingsType {
    var gattConfiguratorRemoveSetting: Bool = false
    var gattConfiguratorNonSaveChangesExitWarning: Bool = false
}

class SILGattConfiguratorHomeViewModelTest : QuickSpec {
    fileprivate var wireframe: MockSILGattConfigutatorHomeWireframe!
    var view: SILGattConfiguratorHomeViewDelegate!
    fileprivate var service: MockSILGattConfiguratorService!
    fileprivate var repository: MockSILGattConfigurationRepository!
    fileprivate var settings: MockSILGattConfiguratorSettings!
    var gattAssignedRepository = SILGattAssignedNumbersRepository()
    
    var testObj: SILGattConfiguratorHomeViewModel!
    
    let oslog = OSLog(subsystem: "\(Bundle.main.bundleIdentifier ?? "com.silabs.BlueGeckoDemoApp").unitTests", category: "SILGattConfiguratorHomeViewModelTest")
    
    func log(_ message: String) {
        os_log("%@", log: self.oslog, type: .default, message)
    }
    
    override func spec() {
        beforeSuite {
            Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "MockDatabase"
        }
        
        beforeEach {
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }
            
            self.wireframe = MockSILGattConfigutatorHomeWireframe()
            self.view = MockSILGattConfiguratorHomeViewDelegate()
            self.service = MockSILGattConfiguratorService()
            self.repository = MockSILGattConfigurationRepository()
            self.settings = MockSILGattConfiguratorSettings()
            self.testObj = SILGattConfiguratorHomeViewModel(wireframe: self.wireframe,
                                                                             view: self.view,
                                                                             service: self.service,
                                                                             settings: self.settings,
                                                                             repository: self.repository,
                                                                             gattAssignedRepository: self.gattAssignedRepository)
        }
        
        afterEach {
            self.wireframe = nil
            self.view = nil
            self.service = nil
            self.repository = nil
            self.testObj = nil
        }
        
        describe("createGattConfiguration()") {
            it("should add to repository configutation with name New GATT Server") {
                self.testObj.createGattConfiguration()
                expect(self.repository.configutationCount).to(equal(1))
            }
            
            it("should create 10 repository with name New GATT Server") {
                for _ in 0..<10 {
                    self.testObj.createGattConfiguration()
                }
                expect(self.repository.configutationCount).to(equal(10))
            }
        }
        
    }
}
