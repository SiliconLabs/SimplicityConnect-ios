//
//  GattConfiguratorView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 12/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct GattConfiguratorView: UIViewControllerRepresentable, PickerTabSubview {
    var gattConfiguratorViewController: SILGattConfiguratorHomeViewController
    
    init() {
        let storyboard = UIStoryboard(name: "SILAppGATTConfigurator", bundle: nil)
        gattConfiguratorViewController = (storyboard.instantiateInitialViewController() as! SILGattConfiguratorHomeViewController)
        let settings = { SILGattConfiguratorSettings() }()
        
        let repository = { SILGattConfigurationRepository.shared }()
        
        let service = { SILGattConfiguratorService.shared }()
        
        let gattAssignedRepository = { SILGattAssignedNumbersRepository() }()
        
        let wireframe = SILGattConfiguratorHomeWireframe(viewController: gattConfiguratorViewController)
        
        gattConfiguratorViewController.viewModel = SILGattConfiguratorHomeViewModel(wireframe: wireframe,
                                                                                    view: gattConfiguratorViewController,
                                                                                    service: service,
                                                                                    settings: settings,
                                                                                    repository: repository,
                                                                                    gattAssignedRepository: gattAssignedRepository)
    }
    
    func makeUIViewController(context: Context) -> SILGattConfiguratorHomeViewController {
        return gattConfiguratorViewController
    }
    
    func updateUIViewController(_ uiViewController:  SILGattConfiguratorHomeViewController, context: Context) {
        print("Update")
    }
    
    func setFloatingButton(settings: FloatingButtonSettings) {
        gattConfiguratorViewController.setupFloatingButton(settings)
        settings.setButtonText("Create New")
    }
    
    func floatingButtonAction() {
        print("Floating button in GattConfiguratorView")
        self.gattConfiguratorViewController.viewModel.createGattConfiguration()
    }
    
    var buttons : [NavBarButton] {
        [NavBarButton(id: "Import Button", image: Image("importIcon"), action: {
            print("Import button in GattConfiguratorView")
            self.gattConfiguratorViewController.viewModel.wireframe.showDocumentPickerView()
        }),
         NavBarButton(id: "Export Button", image: Image("exportIcon"), action: {
            print("Export button in GattConfiguratorView")
            self.gattConfiguratorViewController.viewModel.isExportModeTurnOn = true
        })]
    }
    
    var title: String = "GATT Configurator"
}
