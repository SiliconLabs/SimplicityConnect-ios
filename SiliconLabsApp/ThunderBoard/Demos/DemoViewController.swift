//
//  DemoViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 01/12/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

class DemoViewController: UIViewController, UIGestureRecognizerDelegate {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = StyleColor.lightGray
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForBluetoothDisabledNotification()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterNotifications()
    }
    
    private func registerForBluetoothDisabledNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleBluetoothDisabledNotification),
                                               name: .SILThunderboardBluetoothDisabled,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceDisconnectNotification),
                                               name: .SILThunderboardDeviceDisconnect,
                                               object: nil)
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleBluetoothDisabledNotification() {
        debugPrint("Did bluetooth disabled.")
            
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.environment
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message) { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func handleDeviceDisconnectNotification() {
        debugPrint("Did disconnect peripheral")
            
        SVProgressHUD.showError(withStatus: "Device disconnect unexpectedly")
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
