//
//  SILAppTypeBlinkyViewController.swift
//  BlueGecko
//
//  Created by Vasyl Haievyi on 31/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

class SILAppTypeBlinkyViewController: UIViewController, ConnectedDeviceDelegate, SILThunderboardConnectedDeviceBar {
    
    var connectedDeviceView: ConnectedDeviceBarView?
    var connectedDeviceBarHeight: CGFloat = 70.0
    
    @IBOutlet var lightBulbButton: UIButton!
    @IBOutlet var virtualButtonImage: UIImageView!
    
    public var deviceConnector: DeviceConnection?
    public var connectedPeripheral: CBPeripheral?
    public var deviceName: String!
    
    private var viewModel: SILBlinkyViewModel?
    
    private var disposeBag = SILObservableTokenBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLightBulbButton()
        viewModel = SILBlinkyViewModel(deviceConnector: self.deviceConnector!, connectedPeripheral: self.connectedPeripheral!, name: deviceName)
        subscribeToViewModel()
        viewModel?.viewDidLoad()
        setLeftAlignedTitle("Blinky")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel?.removeObserverAndDisconnect()
        UserDefaults.standard.removeObject(forKey: "initialBatteryLevel")
        self.disposeBag.invalidateTokens()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.tabBarController?.showTabBarAndUpdateFrames()
    }
    
    private func setupLightBulbButton() -> Void {
        lightBulbButton.setImage(UIImage(named: "lightOff"), for: .normal)
        lightBulbButton.setImage(UIImage(named: "lightOn"), for: .selected)
    }
    
    private func subscribeToViewModel() {
        let blinkyStateSubscription = viewModel?.BlinkyState.observe({ state in
            switch state {
            case .unknown:
                SVProgressHUD.show(withStatus: "Setting up Blinky")
            case .initiated:
                SVProgressHUD.dismiss()
            case .failure(let reason):
                if reason == "Bluetooth disabled" {
                    self.displayBluetoothDisabledAlert()
                } else {
                    SVProgressHUD.showError(withStatus: "Error: \(reason)")
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            default:
                return
            }
        })
        disposeBag.add(token: blinkyStateSubscription!)
        
        let lightStateSubscription = viewModel?.LightState.observe({ lightState in
            DispatchQueue.main.async {
                switch lightState{
                case .On:
                    self.setLightBulbOn()
                case .Off:
                    self.setLightBulbOff()
                }
            }
        })
        disposeBag.add(token: lightStateSubscription!)
        
        let reportButtonStateSubscription = viewModel?.ReportButtonState.observe({ buttonState in
            DispatchQueue.main.async {
                switch buttonState{
                case .Pressed:
                    self.setVirtualButtonOn()
                case .Released:
                    self.setVirtualButtonOff()
                }
            }
        })
        disposeBag.add(token: reportButtonStateSubscription!)
        
        let connectedDeviceDataSubscription = viewModel?.connectedDeviceDataState.observe { data in
            if let data = data {
                self.connectedDeviceUpdated(data.deviceName, RSSI: nil, power: data.powerSource, identifier: nil, firmwareVersion: data.firmwareVersion)
            }
        }
        disposeBag.add(token: connectedDeviceDataSubscription!)
    }
    
    @objc func displayBluetoothDisabledAlert() {
        debugPrint("Did disconnect peripheral")
            
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.blinky
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message) { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
        
    @IBAction func onLightBulbButtonTapped() -> Void {
        viewModel?.changeLightState()
    }
    
    @IBAction func backButtonTapped() -> Void {
        viewModel?.removeObserverAndDisconnect()
        UserDefaults.standard.removeObject(forKey: "initialBatteryLevel")
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setLightBulbOff() {
        lightBulbButton.isSelected = false;
    }
    
    private func setLightBulbOn() {
        lightBulbButton.isSelected = true;
    }
    
    private func setVirtualButtonOff() {
        virtualButtonImage.image = UIImage(named: "graphic - blinky - button -  off")
    }
    
    private func setVirtualButtonOn() {
        virtualButtonImage.image = UIImage(named: "graphic - blinky - button - on")
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isEqual(navigationController?.interactivePopGestureRecognizer) {
            viewModel?.removeObserverAndDisconnect()
            UserDefaults.standard.removeObject(forKey: "initialBatteryLevel")
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
            return true
        }
        return false
    }
}
