//
//  SILAdvertiserDetailsWireframe.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertiserDetailsWireframe: SILBaseWireframe, WYPopoverControllerDelegate {
    private let storyboard = UIStoryboard(name: "SILAppAdvertiserDetails", bundle: nil)
    private let advertisingServiceRepository = SILAdvertisingServiceRepository()
    private var popover: WYPopoverController?
    
    init(repository: SILAdvertisingSetRepository, service: SILAdvertiserService, settings: SILAdvertiserSettings, advertiser: SILAdvertisingSetEntity) {        
        let vc = storyboard.instantiateViewController(withIdentifier: "AdvertiserDetails") as! SILAdvertiserDetailsViewController
        
        super.init(viewController: vc)
        
        vc.viewModel = SILAdvertiserDetailsViewModel(wireframe: self, repository: repository, serviceRepository: advertisingServiceRepository, service: service, settings: settings, advertiser: advertiser)
    }
    
    func popPage() {
        navigationController?.popViewController(animated: true)
    }
    
    func presentAdd16BitServiceDialog(onSave: @escaping (String) -> Void) {
        let vc = SILAdvertiserAdd16BitServiceDialogViewController()
        vc.viewModel = SILAdvertiserAdd16BitServiceDialogViewModel(wireframe: self, repository: advertisingServiceRepository, onSave: onSave)
        vc.viewModel.viewDelegate = vc
        
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: vc, presenting: viewController, delegate: self, animated: true)
    }
    
    func presentAdd128BitServiceDialog(onSave: @escaping (String) -> Void) {
        let vc = SILAdvertiserAdd128BitServiceDialogViewController()
        vc.viewModel = SILAdvertiserAdd128BitServiceDialogViewModel(wireframe: self, onSave: onSave)
        vc.viewModel.viewDelegate = vc
        
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: vc, presenting: viewController, delegate: self, animated: true)
    }
    
    func presentRemoveServiceListWarningDialog(onOk: @escaping (Bool) -> Void) {
        let vc = SILRemoveServiceListWarningDialogViewController()
        vc.viewModel = SILRemoveServiceListWarningDialogViewModel(wireframe: self, onOk: onOk)
        
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: vc, presenting: viewController, delegate: self, animated: true)
    }
    
    func presentInvalidTimeToastAlert() {
        presentToastAlert(message: "Invalid Time Limit", toastType: .advertiserTimeLimitError, shouldHasSizeOfText: true, completion: {})
    }
    
    func dismissPopover() {
        popover?.dismissPopover(animated: true)
    }
    
    // MARK: WYPopoverControllerDelegate
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        popover = nil
    }
}
