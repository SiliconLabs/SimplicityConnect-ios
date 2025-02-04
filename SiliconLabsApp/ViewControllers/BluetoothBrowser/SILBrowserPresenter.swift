//
//  SILBrowserPresenter.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 28/12/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

@objcMembers class SILBrowserPresenter : NSObject, DebugDeviceViewModelDelegate {
    weak var presentingController : UIViewController?
    
    init(presentingController : UIViewController) {
        self.presentingController = presentingController
    }
    
    func presentDeviceView(peripheral: CBPeripheral, centralManager: SILCentralManager) {
        let storyboard = UIStoryboard(name: SILAppBluetoothBrowserDetails, bundle: nil)
        let detailsController = storyboard.instantiateViewController(withIdentifier: "SILDetailsTabBarController") as! SILBrowserDetailsTabBarController
        
        detailsController.setupViewControllers(peripheral: peripheral, centralManager: centralManager)
        
        presentingController?.navigationController?.pushViewController(detailsController, animated: true)
    }
    
    func presentAlert(title: String, message: String) {
        presentingController?.alertWithOKButton(title: title, message: message)
    }
    
    func presentFilter(filterDelegate: SILBrowserFilterViewControllerDelegate) {
        let storyboard = UIStoryboard(name: SILAppBluetoothBrowserHome, bundle: nil)
        let filterVC = storyboard.instantiateViewController(withIdentifier: SILSceneFilter) as! SILBrowserFilterViewController
        
        filterVC.delegate = filterDelegate;
        filterVC.modalPresentationStyle = .fullScreen
        presentingController?.present(filterVC, animated: true)
    }
    
    func presentMappings() {
        presentingController?.performSegue(withIdentifier: "SILKeychainSegue", sender: self)
    }
    
}
