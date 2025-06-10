//
//  SILWifiCommissioningViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 16/09/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import SVProgressHUD

protocol SILWifiCommissioningViewControllerDelegate {
    func onceDeviceIsConnect(isConnectedDevice: Bool, demoType: String)
}

class SILWifiCommissioningViewController: UIViewController, SILWifiCommissioningPasswordPopupDelegate, SILWifiCommissioningViewModelDelegate, SILWifiCommissioningDisconnectPopupDelegate, WYPopoverControllerDelegate {
    
    @IBOutlet weak var onStartDisconnectView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var firmwareVersionLabel: UILabel!
    @IBOutlet weak var firmwareVersionBar: UIView!
    private let refreshControl = UIRefreshControl()
    
    var centralManager: SILCentralManager!
    var connectedPeripheral: CBPeripheral!
    
    private var popover: WYPopoverController?
    private var viewModel: SILWifiCommissioningViewModel!
    private var cellModels = [SILWifiCommissioningAPCellViewModel]()
    
    private var disposeBag = SILObservableTokenBag()
    var demoScreenName: String = ""
    var delegateWifiCommissioning:SILWifiCommissioningViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SILWifiCommissioningViewModel(centralManager: centralManager, connectedPeripheral: connectedPeripheral)
        viewModel.delegate = self
        viewModel.viewDidLoad()
        setupTableRefreshControl()
        setLeftAlignedTitle("Wifi Commissioning")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupShadows()
        subscribeToViewModel()
        viewModel.viewWillAppear()
        self.navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.viewWillDisappear()
        disposeBag.invalidateTokens()
        self.navigationController?.tabBarController?.showTabBarAndUpdateFrames()
    }
    
    // MARK: Setup methods
    
    private func setupShadows() {
        self.firmwareVersionBar.superview?.bringSubviewToFront(firmwareVersionBar)
        self.firmwareVersionBar.addShadow()
    }
    
    private func setupTableRefreshControl() {
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    private func subscribeToViewModel() {
        viewModel.newState().observe { state in
            switch state {
            case .bluetoothDisabled:
                self.showBluetoothDisabledWarning()
                
            case .failure(let reason):
                SVProgressHUD.showError(withStatus: reason)
                self.navigationController?.popViewController(animated: true)
                
            case .discoveringServicesAndCharacteristicsStarted:
                SVProgressHUD.show(withStatus: "Connecting to device...")
                
            case .firmwareVersionRead(let version):
                self.firmwareVersionLabel.text = version
                
            case .checkingStatusFinished(let isConnected):
                SVProgressHUD.dismiss()
                if !isConnected {
                    self.viewModel.scan()
                } else {
                    //self.showOnStartDisconnectView()
                    if self.demoScreenName == "typeWifiSensor" {
                        self.navigationController?.popViewController(animated: false)
                        self.delegateWifiCommissioning?.onceDeviceIsConnect(isConnectedDevice: true, demoType: self.demoScreenName)
                        //self.connectedPeripheral.readCharacteristic(characteristic: self.readCharacteristic)

                    }else if self.demoScreenName == "typeAWSIoT" {
                        self.navigationController?.popViewController(animated: false)
                        self.delegateWifiCommissioning?.onceDeviceIsConnect(isConnectedDevice: true, demoType: self.demoScreenName)
                    }else {
                        self.showOnStartDisconnectView()
                    }
                    
                }
            case .disconnectingStarted:
                SVProgressHUD.show(withStatus: "Disconnecting from access point...")
                
            case .disconnectingFinished:
                SVProgressHUD.dismiss()
                self.showToast(message: "Access Point disconnected successfuly", toastType: .info, completion: {})
                self.viewModel.scan()
                
            case .unexpectedlyDisconnected:
                self.showToast(message: "Access Point disconnected enexpectedly", toastType: .info, completion: {})
                self.viewModel.scan()
                
            case .scanning:
                SVProgressHUD.show(withStatus: "Scanning for access points...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    SVProgressHUD.dismiss()
                }
                
            case .connectingStarted:
                SVProgressHUD.show(withStatus: "Connecting to access point...")
                
            case .connected:
                SVProgressHUD.dismiss()
                self.showToast(message: "Access Point connected successfuly", toastType: .info, completion: {})
                if self.demoScreenName == "typeWifiSensor" {
                    //self.moveToSILWifiSensorsDemoView()
                    self.navigationController?.popViewController(animated: false)
                    self.delegateWifiCommissioning?.onceDeviceIsConnect(isConnectedDevice: true, demoType: self.demoScreenName)
                    //self.connectedPeripheral.readCharacteristic(characteristic: self.readCharacteristic)
                }else if self.demoScreenName == "typeAWSIoT" {
                    self.navigationController?.popViewController(animated: false)
                    self.delegateWifiCommissioning?.onceDeviceIsConnect(isConnectedDevice: true, demoType: self.demoScreenName)
                }
                
            case .connectionFailed:
                SVProgressHUD.dismiss()
                self.showToast(message: "Access Point connection failed", toastType: .disconnectionError, completion: {})
                
            default:
                break
            }
        }.putIn(bag: disposeBag)
        
        viewModel.accessPointsCellModels.observe { cellModels in
            self.cellModels = cellModels
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }.putIn(bag: disposeBag)
    }
    
    // MARK: Button actions
    
    @IBAction func disconnectOnStart(_ sender: UIButton) {
        self.showDisconnectPopup()
    }
    
    @objc func refresh(_ sender: AnyObject) {
        if self.viewModel.wifiCommissioningState.value != .connected {
            self.viewModel.scan()
        } else {
            self.refreshControl.endRefreshing()
        }
    }
    
    // MARK: Show popups methods
    
    private func displayPasswordPopup(accessPoint: SILWifiCommissioningAccessPoint) {
        let passwordPopup = SILWifiCommissioningPasswordPopup()
        passwordPopup.accessPoint = accessPoint
        passwordPopup.delegate = self
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: passwordPopup,
                                                                                 presenting: self,
                                                                                 delegate: self,
                                                                                 animated: true)
    }
    
    private func showDisconnectPopup(description: String) {
        let disconnectPopup = SILWifiCommissioningDisconnectPopup()
        disconnectPopup.descriptionText = description
        disconnectPopup.delegate = self
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: disconnectPopup,
                                                                                 presenting: self,
                                                                                 delegate: self,
                                                                                 animated: true)
    }
    
    private func showBluetoothDisabledWarning() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.wifiCommissioning
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message) { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func showOnStartDisconnectView() {
        self.onStartDisconnectView.isHidden = false
    }
    
    private func hideOnStartDisconnectView() {
        self.onStartDisconnectView.isHidden = true
    }
    
    // MARK: SILWifiCommissioningDisconnectPopupDelegate
    
    func didTappedYesButton() {
        self.popover?.dismissPopover(animated: true)
        self.hideOnStartDisconnectView()
        self.viewModel.disconnectCurrentAp()
    }
    
    func didTappedNoButton() {
        self.popover?.dismissPopover(animated: true)
    }
    
    // MARK: SILWifiCommissioningViewModelDelegate
    
    func showDisconnectNeededPopup() {
        let description = "You have to disconnect with current access point to connect with another one.\nDo you want to do this?"
        showDisconnectPopup(description: description)
    }
    
    func showDisconnectPopup() {
        let description = "Do you want to disconnect the access point?"
        showDisconnectPopup(description: description)
    }
    
    func showPasswordPopup(_ ap: SILWifiCommissioningAccessPoint) {
        self.displayPasswordPopup(accessPoint: ap)
    }
    
    // MARK: SILWifiCommissioningPasswordPopupDelegate
    
    func didTappedOKButton(accessPoint: SILWifiCommissioningAccessPoint, password: String) {
        popover?.dismissPopover(animated: true) {
            self.viewModel.joinAP(accessPoint, password: password)
        }
    }
    
    func didTappedCancelButton() {
        popover?.dismissPopover(animated: true)
    }
}

extension SILWifiCommissioningViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return cellModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellViewModel = cellModels[indexPath.section]
        
        let cellView = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as! SILCellView
        cellView.setViewModel(cellViewModel)
        let cell = cellView as! UITableViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCellModel = cellModels[indexPath.section]
        selectedCellModel.select()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        DispatchQueue.main.async {
            cell.layer.zPosition = CGFloat(tableView.numberOfRows(inSection: indexPath.section) - indexPath.row)
            tableView.setNeedsLayout()
            tableView.layoutIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let _ = cellModels[indexPath.section] as? SILWifiCommissioningConnectedAPCellViewModel {
            return 120.0
        }
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 10.0)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForFooterInSection: section, withHeight: 10.0)
    }
}
