//
//  SILSmartLockViewController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 26/06/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD
import Foundation
import AWSCore
import AWSIoT

class SILSmartLockViewController: UIViewController, SILThunderboardConnectedDeviceBar, ConnectedDeviceDelegate , SILSmartLockAWSViewModelProtocol, SILSmartLockSubscribeViewModelProtocol, UINavigationBarDelegate {
    
    @IBOutlet weak var lockStatusLabel: UILabel!
    @IBOutlet weak var lockStatusImage: UIImageView!
    @IBOutlet weak var toggleSegmentView: UISegmentedControl!
    @IBOutlet weak var controllView: UIView!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var unLockButton: UIButton!
    @IBOutlet weak var awsCustomButton: UIButton!
    
    @IBOutlet weak var awsConfigureView: UIView!
    @IBOutlet weak var awsCustomCommandBgView: UIView!
    @IBOutlet weak var awsCustomCommandTextFieldView: UIView!
    @IBOutlet weak var awsCustomCommandTextField: UITextField!
    
    @IBOutlet weak var awsCertificateTFBGView: UIView!
    @IBOutlet weak var awsCertificateFileTextField: UITextField!
    
    @IBOutlet weak var awsCertificatePasswordTFBGView: UIView!
    @IBOutlet weak var awsCertificatePasswordTextField: UITextField!
    
    @IBOutlet weak var subContainerView: UIView!
    @IBOutlet weak var pubTextField: UITextField!
    
    @IBOutlet weak var pubContainerView: UIView!
    @IBOutlet weak var subTextField: UITextField!
    
    @IBOutlet weak var controlViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var awsEndPointBGTextView: UIView!
    @IBOutlet weak var awsEndPointTextView: UITextView!
    
    @IBOutlet weak var notConfiguredWarningView: UIView!
    
    @IBOutlet weak var passwordEyeButton: UIButton!
    var connectionType: SILSmartLockConnectionOption?
    var connectedPeripheral: CBPeripheral?
    
    private var smartLockViewModel: SILSmartLockViewModel?
    private var smartLockDisposeBag = SILObservableTokenBag()
    
    var SILSmartLockAWSViewModelObj: SILSmartLockAWSViewModel?
    var SILSmartLockSubscribeViewModelObj: SILSmartLockSubscribeViewModel?
    
    var smartLockConstants = SmartLockConstants()
    var connectedDeviceView: ConnectedDeviceBarView?
    var connectedDeviceBarHeight: CGFloat = 0.0
    var isAWSConnected = false
    var timer: Timer?
    
    var isValidTopic: Bool = false
    var onlineStatus: Bool = false
    var offlineAlertStatus: Bool = false
    var onlineAlertStatus: Bool = false
    var getPublishData: Bool = false
    var getSubscribeData: Bool = false
    
    var selectedCtrPath: String? = ""
    var selectedCtrPassword = ""
    var selectedEndPoint: String = ""
    var isPassSecureText: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add back button title
        setLeftAlignedTitle("Smart Lock")
        
        pubTextField.delegate = self
        subTextField.delegate = self
        awsConfigureView.isHidden = true
        awsCustomButton.isEnabled = false
        awsCustomCommandBgView.isHidden = true
        isPassSecureText = false
        setupInitialView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.networkStatusChanged(_:)), name: Notification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        Reachability().monitorReachabilityChanges()
        onlineStatus = false
        getPublishData = false
        
        let configImage = UIImage(named: "Group-3")
        let configButton = UIBarButtonItem(image: configImage, style: .plain, target: self, action: #selector(configButtonTapped))
        self.navigationItem.rightBarButtonItem = configButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if smartLockViewModel == nil, let peripheral = self.connectedPeripheral {
            smartLockViewModel = SILSmartLockViewModel(connectedPeripheral: peripheral, name: "")
            subscribeToViewModel()
            smartLockViewModel?.viewDidLoad()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBleView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.awsCertificateFileTextField.text = ""
        NotificationCenter.default.removeObserver(self)
        
        if self.isAWSConnected {
            unsubscribeTopic()
            self.SILSmartLockAWSViewModelObj?.handleDisconnect()
            self.isAWSConnected = false
        }
    }
    
    // MARK: Private func
    
    @objc private func configButtonTapped() {
        if !isAWSConnected{
            configureAwsView()
        } else {
            reConfigureToAWSalert()
        }
    }
    
    func reConfigureToAWSalert() {
        let alert = UIAlertController(title: "Alert!", message: SmartLockConstants.alreayConfigured, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.unsubscribeTopic()
            self.SILSmartLockAWSViewModelObj?.handleDisconnect()
            self.isAWSConnected = false
            
            self.configureAwsView()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func setupInitialView() {
        
        subContainerView.layer.borderColor = UIColor.lightGray.cgColor
        subContainerView.layer.borderWidth = 1
        
        pubContainerView.layer.borderColor = UIColor.lightGray.cgColor
        pubContainerView.layer.borderWidth = 1
        
        awsCertificateTFBGView.layer.borderColor = UIColor.lightGray.cgColor
        awsCertificateTFBGView.layer.borderWidth = 1
        
        awsCertificatePasswordTFBGView.layer.borderColor = UIColor.lightGray.cgColor
        awsCertificatePasswordTFBGView.layer.borderWidth = 1
        
        awsEndPointBGTextView.layer.borderColor = UIColor.lightGray.cgColor
        awsEndPointBGTextView.layer.borderWidth = 1
        
        awsCustomButton.isEnabled = false
        awsCustomCommandTextField.text = ""
        updateAwsCustomButtonAppearance()
        addDoneButtonOnKeyboard()
        self.controlViewConstraint.constant = 84
        
        notConfiguredWarningView.isHidden = true
    }
    
    private func setupBleView() {
        self.lockStatusLabel.text = SmartLockConstants.bleStatus;
        connectionType = .ble
        
        UIView.animate(withDuration: 0.3) {
            self.controlViewConstraint.constant = 84
            self.awsConfigureView.isHidden = true
            self.awsCustomCommandBgView.isHidden = true
            //self.view.layoutIfNeeded()
        }
        
        if (self.connectedPeripheral != nil && self.connectedPeripheral!.state == .connected) {
            SVProgressHUD.show(withStatus: "Setting up Smart Lock")
            self.smartLockViewModel?.queryCurrentStatus()
            print("Connected Peripheral == \(String(describing: self.connectedPeripheral))")
        } else if (self.connectedPeripheral == nil) {
            print(" Device is not avilable yet, please find the device")
            displayBluetoothDisabledAlert()
        }
    }
    
    private func setupAwsView() {
        self.lockStatusLabel.text = SmartLockConstants.awsStatus;
        connectionType = .wifi
        
        UIView.animate(withDuration: 0.3) {
            self.controlViewConstraint.constant = 180
            self.awsCustomCommandBgView.isHidden = false
        }
        awsCertificateFileTextField.text = ""
        
        if isAWSConnected {
            awsGetQueryStatus()
        }
    }
    
    private func configureAwsView() {
        self.lockStatusLabel.text = SmartLockConstants.awsStatus;
        connectionType = .wifi
        
        UIView.animate(withDuration: 0.3) {
            self.controlViewConstraint.constant = 180
            self.awsCustomCommandBgView.isHidden = false
            self.awsConfigureView.isHidden = false
        }
        
        if !isAWSConnected {
            SILSmartLockAWSViewModelObj = SILSmartLockAWSViewModel(SILSmartLockAWSViewModelDelegate: self)
            SILSmartLockSubscribeViewModelObj = SILSmartLockSubscribeViewModel(SILSmartLockSubscribeViewModelDelegate: self)
            showConnectView(isHidden: false)
            awsCertificateFileTextField.text = ""
        } else {
            showConnectView(isHidden: true)
        }
    }
    
    private func subscribeToViewModel() {
        let smartLockPeripheralStateSubscription = smartLockViewModel?.smartLockPeripheralState.observe({ state in
            switch state {
            case .unknown:
                SVProgressHUD.dismiss()
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
            }
        })
        smartLockDisposeBag.add(token: smartLockPeripheralStateSubscription!)
        
        let smartLockStateSubscription = smartLockViewModel?.smartLockOnOffState.observe({ smartLockState in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                switch smartLockState{
                case .lock:
                    self.setLockOverBLE()
                case .unlock:
                    self.setUnlockOverBLE()
                case .unknown:
                    print("Intial state is unknown")
                }
            }
        })
        smartLockDisposeBag.add(token: smartLockStateSubscription!)
    }
    
    @objc func displayBluetoothDisabledAlert() {
        debugPrint("Did disconnect peripheral")
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.smartLock
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message) { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func awsGetQueryStatus() {
        SVProgressHUD.show(withStatus: SmartLockConstants.loadingAwsCurrentStatus)
        if let pubTopic = pubTextField.text {
            SILSmartLockAWSViewModelObj?.getQueryStatus(pubTopic: pubTopic, onNetworkSlow: { [weak self] in
                // TODO: It is calling even it is connected. but after time out of 30s
                self?.dismissLoaderWithPopup()
            })
        }
    }
    
    private func sendCustomMessageToAWS() {
        guard let text = awsCustomCommandTextField.text, !text.isEmpty else {
            self.alertWithOKButton(title: "Alert!", message: SmartLockConstants.shouldNotEmpty, completion: { _ in })
            return
        }
        
        SVProgressHUD.show(withStatus: SmartLockConstants.loadingData)
        let customMessage = awsCustomCommandTextField.text ?? ""
        
        if let pubTopic = pubTextField.text {
            SILSmartLockAWSViewModelObj?.sendCustomMessage(pubTopic: pubTopic, message: customMessage, onNetworkSlow: { [weak self] in
                self?.dismissLoader() // not getting any subscribe value from aws
            })
        }
    }
    
    // MARK: IBActions
    
    @IBAction func toggleSegmentViewAction(_ sender: Any) {
        
        guard let segment = sender as? UISegmentedControl else { return }
        switch segment.selectedSegmentIndex {
        case 0:
            setupBleView()
            notConfiguredWarningView.isHidden = true
        case 1:
            notConfiguredWarningView.isHidden = isAWSConnected
            setupAwsView()
        default:
            return
        }
    }
    
    @IBAction func connectBtn(_ sender: UIButton) {
        
        guard awsCertificateFileTextField.isValid(with: awsCertificateFileTextField.text ?? ""),
              awsCertificatePasswordTextField.isValid(with: awsCertificatePasswordTextField.text ?? ""),
              pubTextField.isValid(with: pubTextField.text ?? ""),
              subTextField.isValid(with: subTextField.text ?? ""),
              awsEndPointTextView.isValid(with: awsEndPointTextView.text ?? "")
        else {
            self.alertWithOKButton(title: "Alert!", message: SmartLockConstants.allFieldsRequired, completion: { _ in })
            return
        }
        
        guard awsEndPointTextView.isValidAWSEndpoint(awsEndPointTextView.text ?? "") else {
            self.alertWithOKButton(title: "Alert!", message: SmartLockConstants.endPointValidationError, completion: { _ in })
            return
        }
        
        
        selectedCtrPassword = awsCertificatePasswordTextField.text ?? ""
        selectedEndPoint = awsEndPointTextView.text ?? ""
        
        isValidTopic = true
        
        if onlineStatus {
            self.getPublishData = false
            SVProgressHUD.show(withStatus: "Connecting...")
            
            print("Certificate path:= \(selectedCtrPath)")
            print("Certificate password:= \(selectedCtrPassword)")
            print("SelectedEndPoint:= \(selectedEndPoint)")
            
            SILSmartLockAWSViewModelObj?.connectViaCert(ctrPath: selectedCtrPath, password: selectedCtrPassword, awsEndpoint: selectedEndPoint)
            //dismissLoader()
        }else{
            DispatchQueue.main.async {
                self.showToast(message: SmartLockConstants.internetNotAvailable, toastType: .disconnectionError, shouldHasSizeOfText: false, position: .bottom) { }
            }
        }
    }
    
    @IBAction func cancelBtn(_ sender: UIButton) {
        showConnectView(isHidden: true)
    }
    
    @IBAction func lockButtonTapped(_ sender: Any) {
        
        switch connectionType {
        case .ble:
            smartLockViewModel?.changeOffSmartLockState()
        case .wifi:
            if !isAWSConnected {
                self.alertWithOKButton(title: "Alert!", message: SmartLockConstants.configureWarning, completion: { _ in })
            } else {
                SVProgressHUD.show(withStatus: SmartLockConstants.loadingData)
                if let pubTopic = pubTextField.text {
                    SILSmartLockAWSViewModelObj?.lockDevice(pubTopic: pubTopic, onNetworkSlow: { [weak self] in
                        self?.dismissLoaderWithPopup()
                    })
                }
            }
        default:
            break
        }
    }
    
    @IBAction func unlockButtonTapped(_ sender: Any) {
        switch connectionType {
        case .ble:
            smartLockViewModel?.changeOnSmartLockState()
        case .wifi:
            
            if !isAWSConnected {
                self.alertWithOKButton(title: "Alert!", message: SmartLockConstants.configureWarning, completion: { _ in })
            } else {
                SVProgressHUD.show(withStatus: SmartLockConstants.loadingData)
                if let pubTopic = pubTextField.text {
                    SILSmartLockAWSViewModelObj?.unlockDevice(pubTopic: pubTopic, onNetworkSlow: { [weak self] in
                        self?.dismissLoaderWithPopup()
                    })
                }
            }
            
        default:
            break
        }
    }
    
    @IBAction func awsCustomButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        if !isAWSConnected {
            awsCustomCommandTextField.text = ""
            self.alertWithOKButton(title: "Alert!", message: SmartLockConstants.configureWarning, completion: { _ in })
        } else {
            sendCustomMessageToAWS()
        }
    }
    
    @IBAction func secureTextBtn(_ sender: Any){
        
        if (isPassSecureText){
            awsCertificatePasswordTextField.isSecureTextEntry = true
            passwordEyeButton.clipsToBounds = true
            passwordEyeButton.contentMode = .scaleAspectFill
            passwordEyeButton.setBackgroundImage(UIImage(named: "eye_hide"), for: .normal)
            isPassSecureText = false
        } else {
            awsCertificatePasswordTextField.isSecureTextEntry = false
            passwordEyeButton.clipsToBounds = true
            passwordEyeButton.contentMode = .scaleAspectFill
            passwordEyeButton.setBackgroundImage(UIImage(named: "eye_view"), for: .normal)
            isPassSecureText = true
        }
    }
    
    private func setLockOverBLE() {
        
        switch connectionType {
        case .ble:
            self.lockStatusLabel.text = SmartLockConstants.blelockedStatus;
            self.lockStatusImage.image = UIImage(named: SmartLockConstants.lockImage)
        case .wifi:
            print("Aws flow")
        default:
            break
        }
    }
    
    private func setUnlockOverBLE() {
        
        switch connectionType {
        case .ble:
            self.lockStatusLabel.text = SmartLockConstants.bleUnlockedStatus;
            self.lockStatusImage.image = UIImage(named: SmartLockConstants.unlockImage)
        case .wifi:
            print("Aws flow")
        default:
            break
        }
    }
    
    private func dismissLoader() {
        SVProgressHUD.dismiss()
        DispatchQueue.main.async {
            self.showToast(message: SmartLockConstants.unkownErrorText, toastType: .disconnectionError, shouldHasSizeOfText: false, position: .bottom) { }
        }
    }
    
    private func dismissLoaderWithPopup() {
        SVProgressHUD.dismiss()
        DispatchQueue.main.async {
            self.showToast(message: SmartLockConstants.internetSlowText, toastType: .disconnectionError, shouldHasSizeOfText: false, position: .bottom) { }
            
            self.awsCertificateFileTextField.text = ""
            self.alertWithOKButton(title: "Alert!", message: SmartLockConstants.internetSlowText, completion: { _ in })
        }
    }
    
    private func setLockOff() {
        switch connectionType {
        case .ble:
            self.lockStatusLabel.text = SmartLockConstants.blelockedStatus;
            self.lockStatusImage.image = UIImage(named: SmartLockConstants.lockImage)
        case .wifi:
            if self.isAWSConnected {
                self.lockStatusLabel.text = SmartLockConstants.awslockedStatus;
                self.lockStatusImage.image = UIImage(named: SmartLockConstants.lockImage)
            }
        default:
            break
        }
    }
    
    private func setLockOn() {
        switch connectionType {
        case .ble:
            self.lockStatusLabel.text = SmartLockConstants.bleUnlockedStatus;
            self.lockStatusImage.image = UIImage(named: SmartLockConstants.unlockImage)
        case .wifi:
            if self.isAWSConnected {
                self.lockStatusLabel.text = SmartLockConstants.awsUnlockedStatus;
                self.lockStatusImage.image = UIImage(named: SmartLockConstants.unlockImage)
            }
        default:
            break
        }
    }
    
    private func unsubscribeTopic() {
        if let subTopicStr = subTextField.text {
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.unsubscribeTopic(subTopicStr)
        }
    }
    
    private func showConnectView(isHidden: Bool) {
        self.view.endEditing(true)
        UIView.transition(with: self.awsConfigureView, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: {
            self.awsConfigureView.isHidden = isHidden
        })
    }
    
    func updateAwsCustomButtonAppearance() {
        if awsCustomButton.isEnabled {
            awsCustomButton.backgroundColor =  UIColor.sil_regularBlue()
        } else {
            awsCustomButton.backgroundColor = UIColor.sil_silverChalice()
        }
    }
    
    // MARK: - SILSmartLockAWSViewModelProtocol
    func notifySmartLockConnectionStatus(isConeected: Bool, status: AWSIoTMQTTStatus, msg: String) {
        
        SVProgressHUD.dismiss()
        
        if isConeected {
            self.isAWSConnected = true
            notConfiguredWarningView.isHidden = true
            self.getPublishData = false
            
            DispatchQueue.main.async {
                self.showToast(message: SmartLockConstants.connectedToAWS, toastType: .internetInfo, shouldHasSizeOfText: false, position: .bottom) { }
            }
           
            if let subTopicStr = subTextField.text {
                SILSmartLockSubscribeViewModelObj?.subscribeOverTopic(topicId: subTopicStr)
                awsGetQueryStatus()
            }

            DispatchQueue.main.async {
                //self.subValueTextView.text = "\(stringValue)"
                self.awsConfigureView.isHidden =  true
            }
        }else {
            self.isAWSConnected = false
            notConfiguredWarningView.isHidden = false
            self.getPublishData = false
            
            self.awsCertificateFileTextField.text = ""
            unsubscribeTopic()
            self.SILSmartLockAWSViewModelObj?.handleDisconnect()
            DispatchQueue.main.async {
                self.showToast(message: msg, toastType: .disconnectionError, shouldHasSizeOfText: false, position: .bottom) { }
                if self.toggleSegmentView.selectedSegmentIndex == 1 {
                    self.showConnectView(isHidden: false)
                }
                self.isAWSConnected = false
            }
        }
    }
    
    // MARK: - SILSmartLockSubscribeViewModelProtocol
    func notifySmartLockSubscribeData(subscribeData: String?) {
        SILSmartLockAWSViewModelObj?.invalidateNetworkSlowTimer()
        SVProgressHUD.dismiss()
        DispatchQueue.main.async {
            self.notConfiguredWarningView.isHidden = true
        }
        
        print("subscribeData == \(String(describing: subscribeData))")
        
        if connectionType == .ble {
        } else if connectionType == .wifi {
            DispatchQueue.main.async {
                self.toggleSegmentView.selectedSegmentIndex = 1
            }
            if let subData = subscribeData {
                getSubscribeData = true
                if subData == SmartLockConstants.unlockFromMQTT || subData == SmartLockConstants.unlockFromMQTTUpper || subData == SmartLockConstants.unlockFromButton {
                    self.getPublishData = true
                    DispatchQueue.main.async {
                        if subData == SmartLockConstants.unlockFromMQTT {
                            self.showToast(message: SmartLockConstants.msgSubscribed, toastType: .info, shouldHasSizeOfText: false, position: .bottom) { }
                        } else {
                            self.showToast(message: SmartLockConstants.msgPublished, toastType: .info, shouldHasSizeOfText: false, position: .bottom) { }
                        }
                        self.setLockOn()
                    }
                } else if subData == SmartLockConstants.lockFromMQTT || subData == SmartLockConstants.lockFromMQTTUpper || subData == SmartLockConstants.lockFromButton {
                    self.getPublishData = true
                    DispatchQueue.main.async {
                        if subData == SmartLockConstants.lockFromMQTT {
                            self.showToast(message: SmartLockConstants.msgSubscribed, toastType: .info, shouldHasSizeOfText: false, position: .bottom) { }
                        } else {
                            self.showToast(message: SmartLockConstants.msgPublished, toastType: .info, shouldHasSizeOfText: false, position: .bottom) { }
                        }
                        self.setLockOff()
                    }
                } else {
                    //
                }
            }
        }
    }
    
    // MARK: - Network Reachability
    func monitorReachabilityChanges() {
        let host = "google.com"
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let reachability = SCNetworkReachabilityCreateWithName(nil, host)!
        
        SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
            let status = ReachabilityStatus(reachabilityFlags: flags)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: ReachabilityStatusChangedNotification),
                                            object: nil,
                                            userInfo: ["Status": status.description])
            
        }, &context)
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), RunLoop.Mode.common as CFString)
    }
    
    @objc func networkStatusChanged(_ notification: Notification) {
        if let notificationVal = notification.userInfo?["Status"] as? String {
            if notificationVal == "Offline"  {
                onlineStatus = false
                onlineAlertStatus = false
                if !offlineAlertStatus {
                    offlineAlertStatus = true
                    DispatchQueue.main.async {
                        self.showToast(message: SmartLockConstants.internetNotAvailable, toastType: .disconnectionError, shouldHasSizeOfText: false, position: .bottom) { }
                    }
                }
            } else {
                offlineAlertStatus = false
                onlineStatus = true
                if !onlineAlertStatus {
                    onlineAlertStatus = true
                    DispatchQueue.main.async {
                        self.showToast(message: SmartLockConstants.connectMsg, toastType: .internetInfo, shouldHasSizeOfText: false, position: .bottom) { }
                    }
                }
            }
        }
    }
}
