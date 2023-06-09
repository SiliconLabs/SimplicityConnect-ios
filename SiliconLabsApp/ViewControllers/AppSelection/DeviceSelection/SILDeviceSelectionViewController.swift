//
//  SILDeviceSelectionViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 21/10/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import SVProgressHUD

@objc protocol SILDeviceSelectionViewControllerDelegate {
    func deviceSelectionViewController(_ viewController: SILDeviceSelectionViewController!,
                                       didSelect peripheral: SILDiscoveredPeripheral!)
    func didDismissDeviceSelectionViewController()
}

@objcMembers
class SILDeviceSelectionViewController: SILAbstractDeviceSelectionViewController, UICollectionViewDataSource {

    private var reloadDataTimer: Timer?
    private var isObserving = false
    private var shouldConnect = true
    
    var delegate: SILDeviceSelectionViewControllerDelegate?
    var viewModel: SILDeviceSelectionViewModel!
    var centralManager: SILCentralManager?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(deviceSelectionViewModel viewModel: SILDeviceSelectionViewModel, shouldConnect: Bool) {
        self.viewModel = viewModel
        self.shouldConnect = shouldConnect
        super.init()
    }

    init(deviceSelectionViewModel viewModel: SILDeviceSelectionViewModel) {
        self.viewModel = viewModel
        self.shouldConnect = true
        super.init()
    }
    
    @IBAction override func didPressCancelButton(_ sender: Any) {
        delegate?.didDismissDeviceSelectionViewController()
    }
    
    // MARK: - Setup Methods
    
    override func setupTextLabels() {
        self.selectDeviceLabel.text = viewModel.selectDeviceString()
    }
    
    override func setupTextView() {
        self.infoTextView.addHyperLinksToText(originalAttributedText: NSAttributedString(string: viewModel.selectDeviceInfoString()), hyperLinks: viewModel.selectDeviceHyperlinks() as! [String : String])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startTimers()
        registerForBluetoothControllerNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopTimers()
        unregisterForBluetoothControllerNotifications()
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.discoveredDevices.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SILDeviceSelectionCollectionViewCellIdentifier, for: indexPath) as! SILDeviceSelectionCollectionViewCell

        let discoveredPeripheral = viewModel.discoveredDevices[indexPath.row]

        cell.configureCell(for: discoveredPeripheral, andApplication: viewModel.app)

        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let selected = viewModel.discoveredDevices[indexPath.row]
        if shouldConnect {
            viewModel.connectingPeripheral = selected
            centralManager?.connect(to: viewModel.connectingPeripheral)
            SVProgressHUD.show(withStatus: "Connecting")
        } else {
            delegate?.deviceSelectionViewController(self, didSelect: selected)
        }
    }
    
    // MARK: - ReloadDataTimer
    
    private func startTimers() {
        reloadDataTimer?.invalidate()
        reloadDataTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(SILDeviceSelectionViewControllerReloadThreshold),
            target: self,
            selector: #selector(reloadDataIfNecessary),
            userInfo: nil,
            repeats: true)
    }
    
    private func stopTimers() {
        reloadDataTimer?.invalidate()
        reloadDataTimer = nil
    }

    @objc private func reloadDataIfNecessary() {
        if viewModel.hasDataChanged {
            viewModel.hasDataChanged = false

            viewModel.updateDiscoveredPeripherals(with: centralManager?.discoveredPeripherals())
            if viewModel.discoveredDevices.count > 0 {
                emptyDeviceListView.isHidden = true
                deviceListSpinner.layer.removeAllAnimations()
                deviceListSpinner.isHidden = true
            }
            
            deviceListLabel.text = "DEVICE LIST (\(viewModel.discoveredDevices.count))"
            deviceCollectionView.reloadData()
        }
    }
    
    // MARK: - Bluetooth Controller Notifications
    
    private func registerForBluetoothControllerNotifications() {
        if !isObserving {
            isObserving = true

            centralManager?.addScan(forPeripheralsObserver: self, selector: #selector(self.handleCentralManagerDidUpdateDiscoveredPeripheralsNotification))
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleCentralManagerDidConnectPeripheralNotification(_:)),
                name: .SILCentralManagerDidConnectPeripheral,
                object: centralManager)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleCentralManagerDidFail(toConnectPeripheralNotification:)),
                name: NSNotification.Name.SILCentralManagerDidFailToConnectPeripheral,
                object: centralManager)
            if viewModel.app.appType != .typeRangeTest {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.handleBluetoothDisabledNotification(_:)),
                    name: NSNotification.Name.SILCentralManagerBluetoothDisabled,
                    object: centralManager)
            }
        }
        
    }
            
    private func unregisterForBluetoothControllerNotifications() {
        if isObserving {
            isObserving = false

            centralManager?.removeScan(forPeripheralsObserver: self)
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.SILCentralManagerDidConnectPeripheral,
                object: centralManager)
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.SILCentralManagerDidFailToConnectPeripheral,
                object: centralManager)
            if viewModel.app.appType != .typeRangeTest {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSNotification.Name.SILCentralManagerBluetoothDisabled,
                    object: centralManager)
            }
        }
    }
            
    @objc private func handleCentralManagerDidUpdateDiscoveredPeripheralsNotification() {
        viewModel.hasDataChanged = true
    }
            
    @objc private func handleCentralManagerDidConnectPeripheralNotification(_ notification: Notification?) {
        if let _ = viewModel.connectingPeripheral {
            SVProgressHUD.dismiss()
            delegate?.deviceSelectionViewController(self, didSelect: viewModel.connectingPeripheral)
            viewModel.connectingPeripheral = nil
        }
    }

    @objc private func handleCentralManagerDidFail(toConnectPeripheralNotification notification: Notification?) {
        if let _ = viewModel.connectingPeripheral {
            SVProgressHUD.showError(withStatus: "Failed to connect...")
            viewModel.connectingPeripheral = nil
        }
    }
            
    @objc private func handleBluetoothDisabledNotification(_ notification: Notification?) {
        var bluetoothDisabledAlert: SILBluetoothDisabledAlertObjc!

        switch viewModel.app.appType {
        case .typeHealthThermometer:
            bluetoothDisabledAlert = SILBluetoothDisabledAlertObjc(bluetoothDisabledAlert: .healthThermometer)
        case .typeConnectedLighting:
            bluetoothDisabledAlert = SILBluetoothDisabledAlertObjc(bluetoothDisabledAlert: .connectedLighting)
        case .typeThroughput:
            bluetoothDisabledAlert = SILBluetoothDisabledAlertObjc(bluetoothDisabledAlert: .throughput)
        case .typeBlinky:
            bluetoothDisabledAlert = SILBluetoothDisabledAlertObjc(bluetoothDisabledAlert: .blinky)
        case .typeESLDemo:
            bluetoothDisabledAlert = SILBluetoothDisabledAlertObjc(bluetoothDisabledAlert: .eslDemo)
            
        default:
            return
        }
        
        self.alertWithOKButton(title: bluetoothDisabledAlert.getTitle(), message: bluetoothDisabledAlert.getMessage()) { _ in
            self.delegate?.didDismissDeviceSelectionViewController()
        }
    }
}
