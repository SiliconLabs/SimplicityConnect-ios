//
//  SILRangeTestModeSelectionViewController.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 17.05.2018.
//  Copyright © 2018 SiliconLabs. All rights reserved.
//

import UIKit

@objc
enum SILRangeTestMode : Int {
    case RX = 1
    case TX = 2
}

@objc
protocol SILRangeTestModeSelectionViewControllerDelegate {
    func didRangeTestModeSelected(forApp app: SILApp?,
                                  peripheral: SILRangeTestPeripheral?,
                                  andBoardInfo boardInfo: SILRangeTestBoardInfo?,
                                  selectedMode mode: SILRangeTestMode)
    func didDismissRangeTestModeSelectionViewController()
}

@objc
@objcMembers
class SILRangeTestModeSelectionViewController: UIViewController {

    var app: SILApp?
    var delegate: SILRangeTestModeSelectionViewControllerDelegate?
    var peripheral: SILRangeTestPeripheral?
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet private var roundedImageViews: [UIImageView]!
    @IBOutlet private weak var deviceNameLabel: UILabel!
    @IBOutlet weak var modelNumberLabel: UILabel!
    @IBOutlet weak var txPowerLabel: UILabel!
    
    private var deviceName: String? = nil
    private var modelNumber: String? = nil
    private var txPower: Double? = nil
    private var radioMode: Int? = nil
    private var isRunning: Bool? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.parse(modelNumber: nil)
        self.parse(txPower: nil)
        
        self.parse(deviceName: peripheral?.deviceName())
        peripheral?.modelNumber {
            self.modelNumber = $0
            self.peripheralValueReceived()
        }
        peripheral?.txPower { (value, min, max) in
            self.txPower = value
            self.peripheralValueReceived()
        }
        peripheral?.radioMode {
            self.radioMode = $0
            self.peripheralValueReceived()
        }
        peripheral?.isRunning {
            self.isRunning = $0
            self.peripheralValueReceived()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        peripheral?.clearCallbacks()
        
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for roundedImageView in roundedImageViews {
            roundedImageView.layer.cornerRadius = roundedImageView.frame.width/2
        }
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
    
    private func parse(deviceName: String?) {
        self.deviceName = deviceName
        
        if let deviceNameValue = deviceName {
            self.deviceNameLabel.text = deviceNameValue
        } else {
            self.deviceNameLabel.text = "<unknown device name>"
        }
    }
    
    private func parse(modelNumber: String?) {
        if let modelNumberValue = modelNumber {
            let regex = try! NSRegularExpression(pattern: "\\[.*?\\]")
            let range = NSMakeRange(0, modelNumberValue.count)
            let modelNumber = regex.stringByReplacingMatches(in: modelNumberValue, options: [], range: range, withTemplate: "")
            self.modelNumberLabel.text = modelNumber.uppercased()
        } else {
            self.modelNumberLabel.text = "<unknown model number>"
        }
    }
    
    private func parse(txPower: Double?) {
        if let txPowerValue = txPower {
            self.txPowerLabel.text = String(format: "%+gdBm", txPowerValue)
        } else {
            self.txPowerLabel.text = "-dBm"
        }
    }
    
    private func peripheralValueReceived() {
        if (tryShowAppAutomatically()) {
            return
        }
        
        if let _ = self.isRunning,
            let _ = self.radioMode,
            let modelNumber = self.modelNumber,
            let txPower = self.txPower {
            parse(modelNumber: modelNumber)
            parse(txPower: txPower)
            
            loadingView?.removeFromSuperview()
            mainView.alpha = 1
        }
    }
    
    private func tryShowAppAutomatically() -> Bool {
        guard let isRunning = self.isRunning, isRunning == true, let radioMode = self.radioMode else {
            return false
        }
        
        let selectedRangeMode = SILRangeTestMode(rawValue: radioMode)!
        let boardInfo = SILRangeTestBoardInfo(deviceName: deviceName, modelNumber: modelNumber)
        
        delegate?.didRangeTestModeSelected(forApp: app,
                                           peripheral: peripheral,
                                           andBoardInfo: boardInfo,
                                           selectedMode: selectedRangeMode)
        
        return true
    }
    
    @IBAction func didPressModeButton(_ button: UIButton) {
        let buttonTag = button.tag
        let selectedRangeMode = SILRangeTestMode(rawValue: buttonTag)!
        let boardInfo = SILRangeTestBoardInfo(deviceName: deviceName, modelNumber: modelNumber)
        
        delegate?.didRangeTestModeSelected(forApp: app,
                                           peripheral: peripheral,
                                           andBoardInfo: boardInfo,
                                           selectedMode: selectedRangeMode)
    }
    
    @IBAction func didPressExitButton(_ sender: UIButton) {
        peripheral?.disconnect()
        
        delegate?.didDismissRangeTestModeSelectionViewController()
    }
}

