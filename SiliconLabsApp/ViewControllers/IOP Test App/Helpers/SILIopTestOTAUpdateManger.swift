//
//  SILIopTestOTAUpdateManger.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 16/11/20.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import SVProgressHUD

enum SILIOPTestOTAStatus {
    case success
    case failure(reason: String)
    case unknown
}

class SILIopTestOTAUpdateManger: NSObject,  SILOTAFirmwareUpdateManagerDelegate {
    private enum OTAProgress {
        case reconnected
        case initiated
        case started
        case finished
        case unknown
    }
    
    var otaFirmwareUpdateManager: SILOTAFirmwareUpdateManager?
    var silCentralManager: SILCentralManager?
    weak var peripheral: CBPeripheral?
    var otaMode: SILOTAMode?
    var firmwareUpdateVM =  SILOTAFirmwareUpdateViewModel()
    var popoverViewController: SILPopoverViewController?
    var progressViewController: SILOTAProgressViewController?
    var progressViewModel: SILOTAProgressViewModel?
    
    private var otaProgress: OTAProgress = .unknown
    private var boardID: String = ""
    private var firmwareVersion: String = ""
    
    var otaTestStatus: SILObservable<SILIOPTestOTAStatus> = SILObservable(initialValue: .unknown)
    private var fileToUpdate: URL?
    private var failureReson: String!
    private var finishOTAError: Error?
    
    init(with peripheral: CBPeripheral, centralManager: SILCentralManager, otaMode: SILOTAMode) {
        super.init()
        self.setupOTAFirmWareModel()
        self.silCentralManager = centralManager
        self.peripheral = peripheral
        self.otaMode = otaMode
        self.otaFirmwareUpdateManager = SILOTAFirmwareUpdateManager(peripheral: peripheral, centralManager: centralManager)
        self.otaFirmwareUpdateManager?.delegate = self;
        self.registerNotifications()
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectPeripheral(notification:)), name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectPeripheral(notification:)), name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFailToConnectPeripheral(notification:)), name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bluetoothDisabled), name: .SILCentralManagerBluetoothDisabled, object: nil)
    }
    
    private func unregisterNotifications() {
        silCentralManager!.removeScan(forPeripheralsObserver: self)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerBluetoothDisabled, object: nil)
    }
    
    @objc private func didConnectPeripheral(notification: Notification) {
        debugPrint("didConnectPeripheral**********OTA")
        if self.otaProgress == .unknown {
            self.otaProgress = .reconnected
        } else if self.otaProgress == .initiated || self.otaProgress == .reconnected {
            self.otaProgress = .started
        } else {
            self.unregisterNotifications()
            self.otaTestStatus.value = .failure(reason: "Not allowed connection to peripheral.")
        }
    }
    
    @objc private func didDisconnectPeripheral(notification: Notification) {
        debugPrint("didDisconnectPeripheral**********OTA")
        if self.otaProgress == .reconnected {
            self.otaProgress = .initiated
        } else {
            self.dismissPopoverWithCompletion(completion: nil)
            self.unregisterNotifications()
            self.failureReson =  "Not allowed disconnection from peripheral."
            self.waitForChangeTopController()
        }
    }
    
    @objc private func didFailToConnectPeripheral(notification: Notification) {
        debugPrint("didFailToConnectPeripheral**********OTA")
        self.unregisterNotifications()
        self.otaTestStatus.value = .failure(reason: "Fail to connect to peripheral.")
    }
    
    @objc private func bluetoothDisabled() {
        debugPrint("bluetoothDisabled**********OTA")
        self.unregisterNotifications()
        self.dismissPopoverWithCompletion(completion: nil)
        self.otaTestStatus.value = .failure(reason: "Bluetooth disabled.")
    }
    
    func setupOTAFirmWareModel() {
        let updateMOdel = SILOTAFirmwareUpdate()
        firmwareUpdateVM = SILOTAFirmwareUpdateViewModel(otaFirmwareUpdate: updateMOdel)
        firmwareUpdateVM.delegate = self
    }
    
    func startTest(for board: String, firmwareVersion: String) {
        self.boardID = board
        self.firmwareVersion = firmwareVersion
        
        self.otaFirmwareUpdateManager?.reconnectToOTADevice()
        
        _ = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { timer in
            timer.invalidate()
            self.findOTAFileForBoard()
        })
    }
    
    private func findOTAFileForBoard() {
        let bundle = Bundle.main
        let pathToFirmware = "iop_ota_files/\(self.boardID)/\(self.firmwareVersion)"
        let urls = bundle.paths(forResourcesOfType: "gbl", inDirectory: pathToFirmware)
            
        for url in urls {
            let fileName = NSString(string: url).deletingPathExtension
            switch self.otaMode {
            case .reliability:
                if fileName.hasSuffix("update") {
                    self.fileToUpdate = URL(fileURLWithPath: url)
                }
            case .speed:
                if !fileName.hasSuffix("update") {
                    self.fileToUpdate = URL(fileURLWithPath: url)
                }
                
            default:
                break
            }
        }
            
        guard let fileToUpdate = self.fileToUpdate else {
            self.unregisterNotifications()
            self.otaTestStatus.value = .failure(reason: "File to update not found.")
            return
        }
        
        if fileToUpdate.pathExtension.isValidEBLorGBLExtension() {
            self.firmwareUpdateVM.appFileURL = fileToUpdate
            if let peripheral = self.peripheral, peripheral.state == .connected {
                DispatchQueue.main.async {
                    self.updateOTAFirmware()
                }
            } else {
                self.unregisterNotifications()
                self.otaTestStatus.value = .failure(reason: "Peripheral disconnected when choosing a file.")
            }
        } else {
            self.unregisterNotifications()
            self.otaTestStatus.value = .failure(reason: "Chosen file isn't EBL or GBL file")
        }
    }
    
    func waitForChangeTopController() {
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.publishFailure), userInfo: nil, repeats: false)
    }
    
    @objc private func publishFailure() {
        self.otaTestStatus.value = .failure(reason: failureReson)
    }

    func updateOTAFirmware() {
        self.otaFirmwareUpdateManager?.cycleDevice(withInitiationByteSequence: true, progress: { (status) in
        }, completion: { (peripheral, error) in
            DispatchQueue.main.async {
                if error == nil {
                    self.peripheral = peripheral
                    self.otaSetupViewControllerDidInitiateFirmwareUpdate(firmwareUpdate: self.firmwareUpdateVM.otaFirmwareUpdate)
                } else {
                    self.unregisterNotifications()
                    self.otaTestStatus.value = .failure(reason: "Error during a file update.")
                }
            }
        })
    }
    
    func otaSetupViewControllerDidInitiateFirmwareUpdate(firmwareUpdate: SILOTAFirmwareUpdate) {
        let isFullUpdate = firmwareUpdate.updateMethod == .full
        let firmwareFile = isFullUpdate ? firmwareUpdate.stackFile : firmwareUpdate.appFile
        let numberOfFilesToUpload = isFullUpdate ? 2 : 1
        self.showOTAProgressForFirmwareFile(file: firmwareFile!, totalNumber: numberOfFilesToUpload) {
            self.otaFirmwareUpdateManager?.uploadFile(firmwareFile, progress: { (bytes, fraction) in
                self.handleFileUploadProgress(progress: fraction, uploadedBytes: bytes)
            }, completion: { (peripheral, error) in
                print("Completed Flash")
                self.handleAppFileUploadCompletionForPeripheral(peripheral: peripheral, error: error)
                self.unregisterNotifications()
                self.finishOTAError = error
                self.dismissPopoverWithCompletion(completion: {
                    if self.finishOTAError == nil {
                        self.otaTestStatus.value = .success
                    } else {
                        self.otaTestStatus.value = .failure(reason: "Error during a file update.")
                    }
                })
            })
        }
    }

    func characteristicWriteType() -> CBCharacteristicWriteType {
        return self.otaMode == SILOTAMode.reliability ?  .withResponse : .withoutResponse
    }
    
    func firmwareUpdateManagerDidUnexpectedlyDisconnect(fromPeripheral firmwareUpdateManager: SILOTAFirmwareUpdateManager!, withError error: Error!) {
    }
        
    func presentOTAProgress(completion: (() -> Void)?) {
        self.progressViewModel = SILOTAProgressViewModel(peripheral: peripheral, with: silCentralManager)
        self.progressViewController = SILOTAProgressViewController(viewModel: self.progressViewModel)
        self.popoverViewController = SILPopoverViewController(nibName: nil, bundle: nil, contentViewController: self.progressViewController)
        guard let topVC = UIViewController.topViewController() else { return }
        if topVC.isKind(of: UIAlertController.self) {
            topVC.dismiss(animated: true) {
                guard let newTopVC = UIViewController.topViewController() else { return }
                newTopVC.present(self.popoverViewController!, animated: true, completion: completion)
            }
        } else {
            topVC.present(self.popoverViewController!, animated: true, completion: completion)
        }
    }
    
    func showOTAProgressForFirmwareFile(file: SILOTAFirmwareFile, totalNumber: Int, completion: (() -> Void)?) {
        self.presentOTAProgress {
            self.progressViewModel?.totalNumberOfFiles = totalNumber
            self.progressViewModel?.file = file
            self.progressViewModel?.uploadingFile = true
            if let block = completion {
                block()
            }
        }
    }
    
    func dismissPopoverWithCompletion(completion: (() -> Void)?) {
        self.popoverViewController?.dismiss(animated: true, completion: completion)
    }
    
    func handleFileUploadProgress(progress: Double, uploadedBytes bytes: Int) {
        self.progressViewModel?.progressFraction = CGFloat(progress)
        self.progressViewModel?.progressBytes = bytes
    }
    
    func handleAppFileUploadCompletionForPeripheral(peripheral: CBPeripheral?, error: Error?) {
        self.progressViewModel?.uploadingFile = false
        if error == nil {
            self.progressViewModel?.finished = true
        }
    }
}

extension SILIopTestOTAUpdateManger: SILOTAFirmwareUpdateViewModelDelegate {
    func firmwareViewModelDidUpdate(_ firmwareViewModel: SILOTAFirmwareUpdateViewModel!) {
    }
}
