//
//  SILMotionDeviceSelectionViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 20/10/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import SVProgressHUD

protocol SILThunderboardDeviceSelectionViewControllerDelegate {
    func deviceSelectionViewControllerDidFinishThunderboardDeviceConfiguration(connection: DemoConnection, deviceConnector: DeviceConnection,
                                                                               appType: SILAppType)
    func deviceSelectionViewControllerDidConnectWithBlinkyDevice(device: Device, deviceConnector: DeviceConnection, isThunderboard: Bool)
    func didDismissDeviceSelectionViewController()
}

class SILThunderboardDeviceSelectionViewController: SILAbstractDeviceSelectionViewController, UICollectionViewDataSource, DeviceSelectionInteractionOutput {
    
    private var reloadDataTimer: Timer?
    
    var delegate: SILThunderboardDeviceSelectionViewControllerDelegate?
    private var interaction: DeviceSelectionInteraction?
    private var appType: SILAppType?
    
    init(interaction: DeviceSelectionInteraction, appType: SILAppType) {
        self.interaction = interaction
        self.appType = appType
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.interaction?.startScanning()
        self.interaction?.interactionOutput = self
        self.registerForDisconnecting()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.interaction?.stopScanning()
        self.unregisterForDisconnecting()
    }
    
    @IBAction override func didPressCancelButton(_ sender: Any) {
        delegate?.didDismissDeviceSelectionViewController()
    }
    
    private func registerForDisconnecting() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceDisconnectNotification),
                                               name: .SILThunderboardDeviceDisconnect,
                                               object: nil)
    }
    
    private func unregisterForDisconnecting() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleDeviceDisconnectNotification() {
        debugPrint("Did disconnect peripheral")
        SVProgressHUD.showError(withStatus: "Device disconnect while configuring")
        delegate?.didDismissDeviceSelectionViewController()
    }
    
    override var preferredContentSize: CGSize {
        get {
            if UI_USER_INTERFACE_IDIOM() == .pad {
                return CGSize(width: 540, height: 606)
            } else {
                return CGSize(width: 296, height: 447)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let numDevices = self.interaction?.numberOfDevices() else {
            return 0
        }
        
        return numDevices
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SILDeviceSelectionCollectionViewCellIdentifier, for: indexPath) as! SILDeviceSelectionCollectionViewCell
        
        let device = self.interaction?.deviceAtIndex(indexPath.row)
        cell.configureCell(forThunderboardDevice: device!)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        self.interaction?.connectToDevice(indexPath.row)
        SVProgressHUD.show(withStatus: "Connecting...")
    }
    
    func bleEnabled(_ enabled: Bool) {
        if !enabled {
            hideBluetoothDisabledWarning()
        }
    }
    
    func bleScanningListUpdated() {
        self.deviceCollectionView.reloadData()
    }
    
    func bleDeviceUpdated(_ device: DiscoveredDeviceDisplay, index: Int) {
        if let cell = deviceCollectionView?.cellForItem(at: IndexPath(row: index, section: 0)) as? SILDeviceSelectionCollectionViewCell {
            cell.configureCell(forThunderboardDevice: device)
        }
    }
    
    func interactionShowConnectionTimedOut(_ deviceName: String) {
        SVProgressHUD.showError(withStatus: "Connection timed out.")
    }
    
    func interactionDidFinishDeviceConfiguration(_ connection: DemoConnection, deviceConnector: DeviceConnection) {
        delegate?.deviceSelectionViewControllerDidFinishThunderboardDeviceConfiguration(connection: connection, deviceConnector: deviceConnector, appType: appType!)
    }
    
    func interactionDidConnectWithBlinkyDevice(_ device: Device, deviceConnector: DeviceConnection, isThunderboard: Bool) {
        delegate?.deviceSelectionViewControllerDidConnectWithBlinkyDevice(device: device, deviceConnector: deviceConnector,
                                                                          isThunderboard: isThunderboard)
    }
    
    func interactionShowConnectionFailed() {
        SVProgressHUD.showError(withStatus: "Failed to connect...")
    }
    
    func hideBluetoothDisabledWarning() {
        var alertType: SILBluetoothDisabledAlert!
        switch appType! {
        case .typeBlinky:
            alertType = .blinky
        case .typeMotion:
            alertType = .motion
        case .typeEnvironment:
            alertType = .environment
        default:
            return
        }
        let bluetoothDisabledAlert = SILBluetoothDisabledAlertObjc(bluetoothDisabledAlert: alertType)
        
        self.alertWithOKButton(title: bluetoothDisabledAlert.getTitle(), message: bluetoothDisabledAlert.getMessage()) { _ in
            self.delegate?.didDismissDeviceSelectionViewController()
        }
    }
}
