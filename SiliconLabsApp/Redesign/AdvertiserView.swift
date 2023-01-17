//
//  AdvertiserView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 12/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct AdvertiserView: UIViewControllerRepresentable, PickerTabSubview {
    private var advertiserViewController: SILAdvertiserHomeViewController!
    
    init() {
        let storyboard = UIStoryboard(name: "SILAppAdvertiser", bundle: nil)
        advertiserViewController = (storyboard.instantiateInitialViewController() as! SILAdvertiserHomeViewController)
        let settings = { SILAdvertiserSettings.shared }()
        let service = { SILAdvertiserService.shared }()
        let repository = { SILAdvertisingSetRepository() }()
        let wireframe = SILAdvertiserHomeWireframe(viewController: advertiserViewController)
        advertiserViewController.viewModel = SILAdvertiserHomeViewModel(wireframe: wireframe,
                                                      view: advertiserViewController,
                                                      service: service,
                                                      repository: repository,
                                                      settings: settings)
    }
    
    func makeUIViewController(context: Context) -> SILAdvertiserHomeViewController {        
        return advertiserViewController
    }
    
    func updateUIViewController(_ uiViewController:  SILAdvertiserHomeViewController, context: Context) {
        
    }
    
    func setFloatingButton(settings: FloatingButtonSettings) {
        settings.setButtonText("Create New")
        settings.setPresented(true)
    }
    
    func floatingButtonAction() {
        print("Floating button in Advertiser")
        self.advertiserViewController.viewModel.createAdvertiser()
        
    }
    
    var buttons : [NavBarButton] {
        [NavBarButton(id: "Rename button", image: Image("deviceRenameIcon"), action: {
            print("Rename device")
            self.advertiserViewController.viewModel.setLocalName()
        }),
         NavBarButton(id: "Switch all off button", image: Image("disableAllIcon"), action: {
            print("Switching off Advertisers button")
            self.advertiserViewController.viewModel.switchAllOff()
        })]
    }
    
    var title: String = "Advertiser"
    
}

