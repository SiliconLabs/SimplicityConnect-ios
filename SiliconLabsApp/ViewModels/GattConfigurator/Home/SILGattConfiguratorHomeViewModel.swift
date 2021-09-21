//
//  SILGattConfiguratorHomeViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 04/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import AEXML

protocol SILGattConfiguratorHomeViewDelegate: class {
    func updateConfigurations(configurations: [SILGattConfiguratorCellViewModel], checkBoxCells: [SILGattConfiguratorCheckBoxCellViewModel])
    func popViewController()
 }

class SILGattConfiguratorHomeViewModel {
    private let wireframe: SILGattConfiguratorHomeWireframeType
    private unowned let view: SILGattConfiguratorHomeViewDelegate
    private let repository: SILGattConfigurationRepositoryType
    private let service: SILGattConfiguratorServiceType
    private let settings: SILGattConfiguratorSettingsType
    private let gattAssignedRepository: SILGattAssignedNumbersRepository
    
    private var configurationsSubscription: (() -> Void)?
    
    var gattConfigurations: [SILGattConfigurationEntity] = []
    var gattConfigurationsToExport: [SILGattConfigurationEntity] = []
    var cellViewModels: [SILGattConfiguratorCellViewModel] = []
    var checkBoxCellViewModels: [SILGattConfiguratorCheckBoxCellViewModel] = []
    
    let isExportButtonEnable: SILObservable<Bool> = SILObservable(initialValue: false)
    let isExportModeOn: SILObservable<Bool> = SILObservable(initialValue: false)
    let isMenuEnabled: SILObservable<Bool> = SILObservable(initialValue: true)
    
    let fileWriter = SILGattConfiguratorFileWriter()
    
    private var isExportModeTurnOn: Bool = false {
        didSet {
            isExportModeOn.value = isExportModeTurnOn
            isMenuEnabled.value = !isExportModeOn.value
            if !isExportModeTurnOn {
                gattConfigurationsToExport = []
                isExportButtonEnable.value = false
            }
            rebuildCellViewModels()
        }
    }
    
    private let observableTokenBag = SILObservableTokenBag()
    
    init(wireframe: SILGattConfiguratorHomeWireframeType, view: SILGattConfiguratorHomeViewDelegate, service: SILGattConfiguratorServiceType,
         settings: SILGattConfiguratorSettingsType, repository: SILGattConfigurationRepositoryType,
         gattAssignedRepository: SILGattAssignedNumbersRepository) {
        self.wireframe = wireframe
        self.view = view
        self.repository = repository
        self.service = service
        self.settings = settings
        self.gattAssignedRepository = gattAssignedRepository
    }
    
    deinit {
        configurationsSubscription?()
    }
    
    func viewDidLoad() {
        weak var weakSelf = self;
        
        configurationsSubscription = repository.observeConfigurations { configurations in
            weakSelf?.update(configurations: configurations)
        }
        
        service.blutoothEnabled.observe(sendInitial: false) { [weak self] state in
            if state == false {
                self?.wireframe.showBluetoothDisabledDialog()
            }
        }.putIn(bag: observableTokenBag)
        
        fileWriter.clearExportDir()
    }
    
    func openMenu(sourceView: UIView) {
        wireframe.presentContextMenu(sourceView: sourceView, options: [
            ContextMenuOption(title: "Create new") { [weak self] in
                print("Selected create new")
                self?.isMenuEnabled.value = false
                self?.createGattConfiguration()
                self?.isMenuEnabled.value = true
            },
            ContextMenuOption(title: "Import", callback: {
                print("Selected import")
                self.wireframe.showDocumentPickerView()
            }),
            ContextMenuOption(enabled: gattConfigurations.count > 0, title: "Export",  callback: {
                print("Selected export")
                self.isExportModeTurnOn = true
            })
        ])
    }
    
    func onBack() {
        self.view.popViewController()
    }
    
    private func getFilePathForGattConfiguration(createdFilesDict: inout [String: Int], name: String) -> String {
        let name = name.replacingOccurrences(of: " ", with: "_").lowercased()
        
        if let index = createdFilesDict[name] {
            createdFilesDict.updateValue(index + 1, forKey: name)
            let nameWithSuffix = name.appending("_\(index + 1)")
            return fileWriter.getFilePath(withName: nameWithSuffix)
        } else {
            createdFilesDict[name] = 1
            return fileWriter.getFilePath(withName: name)
        }
    }
    
    func export(onFinish: @escaping ([URL]) -> ()) {
        var fileUrls = [URL]()
        var createdFileNames = [String:Int]()
        
        for gattConfiguration in gattConfigurationsToExport.sorted(by: { $0.createdAt < $1.createdAt }) {
            let configurationExportFilePath = getFilePathForGattConfiguration(createdFilesDict: &createdFileNames, name: gattConfiguration.name)
            if fileWriter.createEmptyFile(atPath: configurationExportFilePath) {
                let xmlDocument = AEXMLDocument(root: gattConfiguration.export(), options: AEXMLOptions())
                if fileWriter.openFile(filePath: configurationExportFilePath) {
                    _ = fileWriter.append(text: xmlDocument.xml)
                    fileWriter.closeFile()
                    fileUrls.append(fileWriter.getFileUrl(filePath: configurationExportFilePath))
                }
            }
        }
        
        // delay for improve UI
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
            timer.invalidate()
            
            onFinish(fileUrls)
            debugPrint("exported", self.gattConfigurationsToExport.count ,"servers")
        })
    }
    
    func importXml(url: URL,
                    onStarted: @escaping () -> (),
                    onFinish: @escaping ([URL: SILGattXmlParserError]) -> ()) {
        onStarted()
        isMenuEnabled.value = false
        
        var configurationToAdd: SILGattConfigurationEntity?
        var importError = [URL: SILGattXmlParserError]()
        let parser = SILGattXmlParser(gattAssignedRepository: self.gattAssignedRepository)
        
        debugPrint(String(describing: url))
        let result = parser.parse(file: url)
        switch result {
        case let .success(entity):
            configurationToAdd = entity
            
        case let .failure(error):
            importError[url] = error
        }
        
        // delay for improve UI 
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
            timer.invalidate()
            
            if let configuration = configurationToAdd {
                self.repository.add(configuration: configuration)
            }
            
            self.isMenuEnabled.value = true
            onFinish(importError)
        })
    }
    
    func turnOffExportMode() {
        self.isExportModeTurnOn = false
    }

    func createGattConfiguration() {
        var configuration = SILGattConfigurationEntity()
        configuration.name = "New GATT Server"
        configuration.additionalXmlAttributes = [SILGattXMLAttribute(name: "out", value: "gatt_db.c"),
                                                 SILGattXMLAttribute(name: "header", value: "gatt_db.h"),
                                                 SILGattXMLAttribute(name: "prefix", value: "gattdb_"),
                                                 SILGattXMLAttribute(name: "generic_attribute_service", value: "true")]
        repository.add(configuration: configuration)
    }
    
    private func update(configurations: [SILGattConfigurationEntity]) {
        gattConfigurations = configurations
        rebuildCellViewModels()
    }
    
    private func rebuildCellViewModels() {
        let newViewModels = createNewViewModels(from: gattConfigurations)
        updateToExpandedStateIfNeeded(newViewModels)
        self.cellViewModels = newViewModels
        self.checkBoxCellViewModels = createNewCheckBoxCellViewModels(from: gattConfigurations)
        self.view.updateConfigurations(configurations: newViewModels, checkBoxCells: checkBoxCellViewModels)
    }
    
    private func createNewViewModels(from configurations: [SILGattConfigurationEntity]) -> [SILGattConfiguratorCellViewModel] {
        return gattConfigurations.map { configuration in
            return SILGattConfiguratorCellViewModel(wireframe: wireframe as! SILGattConfiguratorHomeWireframe, service: service as! SILGattConfiguratorService, repository: repository as! SILGattConfigurationRepository, settings: settings, configuration: configuration)
        }
    }
    
    private func createNewCheckBoxCellViewModels(from configurations: [SILGattConfigurationEntity]) -> [SILGattConfiguratorCheckBoxCellViewModel] {
        return gattConfigurations.map {
            return SILGattConfiguratorCheckBoxCellViewModel(configuration: $0, isCheckBoxHidden: !isExportModeTurnOn) { (configuration, shouldAdd) in
                self.addOrRemoveGattConfigurationToExport(configuration: configuration, shouldAdd: shouldAdd)
            }
        }
    }
    
    private func addOrRemoveGattConfigurationToExport(configuration: SILGattConfigurationEntity, shouldAdd: Bool) {
        if shouldAdd, !gattConfigurationsToExport.contains(where: { $0.uuid == configuration.uuid}) {
            gattConfigurationsToExport.append(configuration)
        }
        if !shouldAdd, let index = gattConfigurationsToExport.firstIndex(where: { $0.uuid == configuration.uuid}) {
            gattConfigurationsToExport.remove(at: index)
        }
        isExportButtonEnable.value = gattConfigurationsToExport.count > 0
        debugPrint("to export", gattConfigurationsToExport.count)
    }
    
    private func updateToExpandedStateIfNeeded(_ newViewModels: [SILGattConfiguratorCellViewModel]) {
        let filteredViewModels = self.cellViewModels.filter{ oldCell in newViewModels.contains(where: { $0.configuration.uuid == oldCell.configuration.uuid })}
        for newCell in newViewModels {
            if let oldCell = filteredViewModels.first(where: { $0.configuration.uuid == newCell.configuration.uuid }), oldCell.isExpanded {
                newCell.changeExpand()
            }
        }
    }
}
