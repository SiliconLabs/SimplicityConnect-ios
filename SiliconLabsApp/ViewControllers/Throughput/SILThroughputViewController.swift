//
//  SILThroughputViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 23.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import SVProgressHUD

class SILThroughputViewController: UIViewController, UIGestureRecognizerDelegate, CBCentralManagerDelegate {
    @IBOutlet weak var speedGaugeView: SILThroughputGaugeView!
    
    @IBOutlet weak var notificationsTestButton: UIButton!
    @IBOutlet weak var indicationsTestButton: UIButton!
    private let modeSelectedImage = UIImage(named: "checkBoxActive")
    private let unselectedModeImage = UIImage(named: "checkBoxInactive")
    private let disabledSelectedImage = UIImage(named: "gray_checkbox")
    
    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var phyLabel: SILConnectionParameterLabel!
    @IBOutlet weak var intervalLabel: SILConnectionParameterLabel!
    @IBOutlet weak var latencyLabel: SILConnectionParameterLabel!
    @IBOutlet weak var supervisionTimeoutLabel: SILConnectionParameterLabel!
    @IBOutlet weak var pduLabel: SILConnectionParameterLabel!
    @IBOutlet weak var mtuLabel: SILConnectionParameterLabel!

    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var startStopTestButton: SILPrimaryButton!
    
    private var viewModel: SILThroughputViewModel!
    
    var peripheralManager: SILThroughputPeripheralManager!
    var centralManager: SILCentralManager!
    var connectedPeripheral: CBPeripheral!
    var manager: CBCentralManager!

    private var disposeBag = SILObservableTokenBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.buttonsView.addShadow()
        self.addShadowForOptionsView()
        self.setImagesForSelectionModeButtons()
        
        self.showProgressView()
        
        viewModel = SILThroughputViewModel(peripheralManager: peripheralManager, centralManager: centralManager, connectedPeripheral: connectedPeripheral)
        viewModel.viewDidLoad()
        
        setLeftAlignedTitle("Throughput")
        manager = CBCentralManager()
        manager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        subscribeToConnectionParameters()
        subscribeToViewControllerUpdateEvents()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.unregisterAndStopTests()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.tabBarController?.showTabBarAndUpdateFrames()
    }
    
    private func addShadowForOptionsView() {
        optionsView.layer.cornerRadius = CornerRadiusStandardValue
        optionsView.layer.shadowColor = UIColor.black.cgColor
        optionsView.layer.shadowOpacity = 0.3
        optionsView.layer.shadowOffset = CGSize.zero
        optionsView.layer.shadowRadius = 2
    }
    
    private func setImagesForSelectionModeButtons() {
        notificationsTestButton.setImage(modeSelectedImage, for: .selected)
        notificationsTestButton.setImage(unselectedModeImage, for: .normal)
        notificationsTestButton.setImage(disabledSelectedImage, for: [.disabled, .selected])
        indicationsTestButton.setImage(modeSelectedImage, for: .selected)
        indicationsTestButton.setImage(unselectedModeImage, for: .normal)
        indicationsTestButton.setImage(disabledSelectedImage, for: [.disabled, .selected])
    }
    
    // MARK: - Subscriptions
    
    private func subscribeToConnectionParameters() {
        weak var weakSelf = self
        let phyStatus = viewModel.phyStatus.observe( { phy in
            guard let weakSelf = weakSelf else { return }
            weakSelf.phyLabel.text = "PHY: \(phy.rawValue)"
        })
        disposeBag.add(token: phyStatus)
        
        let connectionInterval = viewModel.connectionIntervalStatus.observe( { value in
            guard let weakSelf = weakSelf else { return }
            if value == -1.0 {
                weakSelf.intervalLabel.text = "Interval: N/A"
            } else {
                weakSelf.intervalLabel.text = "Interval: \(Double(value)) ms"
            }
        })
        disposeBag.add(token: connectionInterval)
        
        let slaveLatency = viewModel.slaveLatencyStatus.observe( { value in
            guard let weakSelf = weakSelf else { return }
            if value == -1.0 {
                weakSelf.latencyLabel.text = "Latency: N/A"
            } else {
                weakSelf.latencyLabel.text = "Latency: \(Double(value)) ms"
            }
        })
        disposeBag.add(token: slaveLatency)
        
        let supervisionTimeout = viewModel.supervisionTimeoutStatus.observe( { value in
            guard let weakSelf = weakSelf else { return }
            if value == -1.0 {
                weakSelf.supervisionTimeoutLabel.text = "Supervision Timeout: N/A"
            } else {
                weakSelf.supervisionTimeoutLabel.text = "Supervision Timeout: \(Double(value)) ms"
            }
        })
        disposeBag.add(token: supervisionTimeout)
        
        let pdu = viewModel.pduStatus.observe( { value in
            guard let weakSelf = weakSelf else { return }
            if value == -1 {
                weakSelf.pduLabel.text = "PDU: N/A"
            } else {
                weakSelf.pduLabel.text = "PDU: \(value) bytes"
            }
        })
        disposeBag.add(token: pdu)
        
        let mtu = viewModel.mtuStatus.observe( { value in
            guard let weakSelf = weakSelf else { return }
            if value == -1 {
                weakSelf.mtuLabel.text = "MTU: N/A"
            } else {
                weakSelf.mtuLabel.text = "MTU: \(value) bytes"
            }
        })
        disposeBag.add(token: mtu)
        
        let peripheralConnectionStatus = viewModel.peripheralConnectionStatus.observe( { value in
            guard let weakSelf = weakSelf else { return }
            if !value {
                weakSelf.viewModel.unregisterAndStopTests()
                SVProgressHUD.dismiss()
                weakSelf.navigationController?.popToRootViewController(animated: true)
            }
        })
        disposeBag.add(token: peripheralConnectionStatus)
    }
    
    private func subscribeToViewControllerUpdateEvents() {
        weak var weakSelf = self
        let bluetoothState = viewModel.bluetoothState.observe( { value in
            guard let weakSelf = weakSelf else { return }
            if !value {
                SVProgressHUD.dismiss()
                weakSelf.showBluetoothDisabledAlert()
            }
        })
        disposeBag.add(token: bluetoothState)
        
        let testState = viewModel.testState.observe({ state in
            guard let weakSelf = weakSelf else { return }
            guard state != .none else { return }
            
            weakSelf.hideProgressView()
            
            switch state {
            case .invalidCommunicationWithEFR:
                DispatchQueue.main.async {
                    weakSelf.showCharacteristicArentNotyfingErrorDialog()
                }
                
            case .noSubscriber:
                weakSelf.showNoSubscriberErrorDialog()
                
            default:
                break
            }
        })
        disposeBag.add(token: testState)
         
        let throughputResult = viewModel.testResult.observe({ result in
            guard let weakSelf = weakSelf else { return }
            weakSelf.speedGaugeView.updateView(throughputResult: result)
        })
        disposeBag.add(token: throughputResult)
        
        let testButtonState = viewModel.testButtonState.observe( { value in
            guard let weakSelf = weakSelf else { return }
            switch value {
            case .EFRToPhoneTest:
                debugPrint("EFR TO PHONE!")
                weakSelf.indicationsTestButton.isEnabled = false
                weakSelf.notificationsTestButton.isEnabled = false
                weakSelf.startStopTestButton.isEnabled = false
                weakSelf.startStopTestButton.backgroundColor = .lightGray
                weakSelf.startStopTestButton.setTitle("Start", for: .normal)
                
            case .phoneToEFRTest:
                debugPrint("PHONE TO EFR!")
                weakSelf.indicationsTestButton.isEnabled = false
                weakSelf.notificationsTestButton.isEnabled = false
                weakSelf.startStopTestButton.isEnabled = true
                weakSelf.startStopTestButton.backgroundColor = UIColor.sil_siliconLabsRed()
                weakSelf.startStopTestButton.setTitle("Stop", for: .normal)
                
            case .readyForTesting:
                debugPrint("READY FOR TESTING!")
                weakSelf.indicationsTestButton.isEnabled = true
                weakSelf.notificationsTestButton.isEnabled = true
                weakSelf.startStopTestButton.isEnabled = true
                weakSelf.startStopTestButton.backgroundColor = UIColor.sil_regularBlue()
                weakSelf.startStopTestButton.setTitle("Start", for: .normal)
            }
        })
        disposeBag.add(token: testButtonState)
        
        let phoneTestModeSelection = viewModel.phoneTestModeSelected.observe( { selectedMode in
            guard let weakSelf = weakSelf else { return }
            switch selectedMode {
            case .indicationsSelected:
                debugPrint("INDICATIONS SELECTED")
                weakSelf.indicationsTestButton.isSelected = true
                weakSelf.notificationsTestButton.isSelected = false
                
            case .notificationsSelected:
                debugPrint("NOTIFICATIONS SELECTED")
                weakSelf.indicationsTestButton.isSelected = false
                weakSelf.notificationsTestButton.isSelected = true
            }
        })
        disposeBag.add(token: phoneTestModeSelection)
    }
    
    // MARK: - User Actions
    
    @IBAction func notificationsButtonWasTapped(_ sender: UIButton) {
        debugPrint("NOTIFICATIONS BUTTON WAS TAPPED")
        viewModel.changePhoneTestModeSelection(newSelection: .notificationsSelected)
    }
    
    @IBAction func indicationsButtonWasTapped(_ sender: UIButton) {
        debugPrint("INDICATIONS BUTTON WAS TAPPED")
        viewModel.changePhoneTestModeSelection(newSelection: .indicationsSelected)
    }
    @IBAction func didBackButtonTapped(_ sender: UIButton) {
        backToHomeScreenActions()
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    private func backToHomeScreenActions() {
        viewModel.unregisterAndStopTests()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func startStopButtonWasTapped(_ sender: UIButton) {
        viewModel.changeTestState()
    }
    
    private func showBluetoothDisabledAlert() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.throughput
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message, completion: { _ in
            self.viewModel.unregisterAndStopTests()
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    private func showProgressView() {
        SVProgressHUD.show(withStatus: "Reading device state…")
    }
    
    private func hideProgressView() {
        SVProgressHUD.dismiss()
    }
    
    private func showNoSubscriberErrorDialog() {
        self.alertWithOKButton(title: "Error: Failed to find Throughput service. This demo may not work correctly.",
                               message: "This demo requires Bluetooth - SoC Throughput sample app running on the kit. Please ensure it has been correctly flashed.")
    }
    
    private func showCharacteristicArentNotyfingErrorDialog() {
        self.alertWithOKButton(title: "Error: Failed to find Throughput service",
                               message: "This demo requires Bluetooth - SoC Throughput sample app running on the kit. Please ensure it has been correctly flashed",
                               completion: { alertAction in
                                                self.backToHomeScreenActions()
        })
    }
    
    // MARK: - centralManagerDidUpdateState delegate 
    @objc func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            break
        case .poweredOff:
            self.showBluetoothDisabledAlert()
            break
        case .resetting:
            break
        case .unauthorized:
            break
        case .unsupported:
            break
        case .unknown:
            break
        default:
            break
        }
    }
}
