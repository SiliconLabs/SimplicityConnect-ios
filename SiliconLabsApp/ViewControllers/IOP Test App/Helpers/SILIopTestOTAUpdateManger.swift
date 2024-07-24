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

extension NSNotification.Name {
    static let SILIOPFileUrlChosen = Notification.Name("iopFileChosen")
    static let SILIOPShowFilePicker = Notification.Name("iopShowFilePicker")
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
    
    var otaTestStatus: SILObservable<SILIOPTestOTAStatus> = SILObservable(initialValue: .unknown)
    private var fileToUpdate: URL?
    private var failureReson: String!
    private var finishOTAError: Error?
    
    //IOP MANAGER...
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleGblFileNotification(notification:)), name: .SILIOPFileUrlChosen, object: nil)
    }
    
    private func unregisterNotifications() {
        silCentralManager!.removeScan(forPeripheralsObserver: self)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidDisconnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerDidFailToConnectPeripheral, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILCentralManagerBluetoothDisabled, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SILIOPFileUrlChosen, object: nil)
    }
    
    @objc private func didConnectPeripheral(notification: Notification) {
        debugPrint("didConnectPeripheral**********OTA")
        IOPLog().iopLogSwiftFunction(message: "didConnectPeripheral**********OTA")
        if self.otaProgress == .unknown {
            self.otaProgress = .reconnected
        } else if self.otaProgress == .initiated || self.otaProgress == .reconnected {
            self.otaProgress = .started
        } else {
            self.unregisterNotifications()
            self.otaTestStatus.value = .failure(reason: "Not allowed connection to peripheral.")
            IOPLog().iopLogSwiftFunction(message: "Not allowed connection to peripheral.")
        }
    }
    
    @objc private func didDisconnectPeripheral(notification: Notification) {
        debugPrint("didDisconnectPeripheral**********OTA")
        IOPLog().iopLogSwiftFunction(message: "didDisconnectPeripheral**********OTA")
        if self.otaProgress == .reconnected {
            self.otaProgress = .initiated
        } else if self.otaProgress == .finished {
            self.unregisterNotifications()
            self.dismissPopoverWithCompletion(completion: {
                self.otaTestStatus.value = .success
            })
        } else {
            self.dismissPopoverWithCompletion(completion: nil)
            self.unregisterNotifications()
            self.failureReson =  "Not allowed disconnection from peripheral."
            self.waitForChangeTopController()
            IOPLog().iopLogSwiftFunction(message: "Not allowed disconnection from peripheral.")
        }
    }
    
    @objc private func didFailToConnectPeripheral(notification: Notification) {
        debugPrint("didFailToConnectPeripheral**********OTA")
        IOPLog().iopLogSwiftFunction(message: "didFailToConnectPeripheral**********OTA")
        self.unregisterNotifications()
        self.otaTestStatus.value = .failure(reason: "Fail to connect to peripheral.")
        IOPLog().iopLogSwiftFunction(message: "Fail to connect to peripheral.")
    }
    
    @objc private func bluetoothDisabled() {
        debugPrint("bluetoothDisabled**********OTA")
        IOPLog().iopLogSwiftFunction(message: "bluetoothDisabled**********OTA")
        self.unregisterNotifications()
        self.dismissPopoverWithCompletion(completion: nil)
        self.otaTestStatus.value = .failure(reason: "Bluetooth disabled.")
        IOPLog().iopLogSwiftFunction(message: "Bluetooth disabled.")
    }
    
    func setupOTAFirmWareModel() {
        let updateMOdel = SILOTAFirmwareUpdate()
        firmwareUpdateVM = SILOTAFirmwareUpdateViewModel(otaFirmwareUpdate: updateMOdel)
        firmwareUpdateVM.delegate = self
    }
    
    func startTest(for board: String, firmwareVersion: SILIOPFirmwareVersion) {
        self.boardID = board
        
        self.otaFirmwareUpdateManager?.reconnectToOTADevice()
        
        _ = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { timer in
            timer.invalidate()
            self.findOTAFileForBoard(firmwareVersion)
        })
    }
    
    private func findOTAFileForBoard(_ firmwareVersion: SILIOPFirmwareVersion) {
        if firmwareVersion.isLesserThan3_3_0() {
            findLocalFile(version: firmwareVersion.version)
        } else {
            postShowFilePickerNotification()
        }
    }
    
    private func findLocalFile(version: String) {
        let bundle = Bundle.main
        let pathToFirmware = "iop_ota_files/\(self.boardID)/\(version)"
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
        prepareOtaUpdateFirmware()
    }
    
    private func prepareOtaUpdateFirmware() {
        guard let fileToUpdate = self.fileToUpdate else {
            self.unregisterNotifications()
            self.otaTestStatus.value = .failure(reason: "File to update not found.")
            IOPLog().iopLogSwiftFunction(message: "File to update not found.")
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
                IOPLog().iopLogSwiftFunction(message: "Peripheral disconnected when choosing a file.")
            }
        } else {
            self.unregisterNotifications()
            self.otaTestStatus.value = .failure(reason: "Chosen file isn't EBL or GBL file")
            IOPLog().iopLogSwiftFunction(message: "Chosen file isn't EBL or GBL file")
        }
    }
    
    @objc private func handleGblFileNotification(notification: NSNotification) {
        if let gblFileUrl = notification.userInfo?["gblFileUrl"] as? URL {
            self.fileToUpdate = gblFileUrl
            prepareOtaUpdateFirmware()
        } else {
            self.unregisterNotifications()
            self.otaTestStatus.value = .failure(reason: "No chosen file.")
            IOPLog().iopLogSwiftFunction(message: "No chosen file.")
        }
    }
    
    private func postShowFilePickerNotification() {
        NotificationCenter.default.post(Notification(name: .SILIOPShowFilePicker))
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
                    IOPLog().iopLogSwiftFunction(message: "Error during a file update.")
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
                IOPLog().iopLogSwiftFunction(message: "Completed Flash")
                self.handleAppFileUploadCompletionForPeripheral(peripheral: peripheral, error: error)
                self.finishOTAError = error
                if self.finishOTAError == nil {
                    self.otaProgress = .finished
                    self.silCentralManager?.disconnect(from: self.peripheral!)
                } else {
                    self.unregisterNotifications()
                    self.dismissPopoverWithCompletion(completion: {
                        self.otaTestStatus.value = .failure(reason: "Error during a file update.")
                        IOPLog().iopLogSwiftFunction(message: "Error during a file update.")
                    })
                }
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
