//
//  SILIOPTesterViewController.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 06/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import Foundation
import UIKit

@objc
@objcMembers
class SILIOPTesterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var allSpace: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var firmwareNameLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var totalTestCases: UILabel!
    @IBOutlet weak var floatingButton: UIButton!
    
    
    private var viewModel: SILIOPTesterViewModel?
    var deviceNameToSearch: String?

    private var disposeBag = SILObservableTokenBag()
    
    private var currentTestState: SILIOPTesterViewModel.TestState?
    private var currentTestScenarioIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.disposeBag = SILObservableTokenBag()
        self.setupViewModel()
        self.setupFloatingButton()
        self.subscribeToUpdateUINotifications()
        self.floatingButton.layer.cornerRadius = 20
        infoView.addShadow()
        if let deviceNameToSearch = deviceNameToSearch {
            firmwareNameLabel.text = "Firmware Name: \(deviceNameToSearch)"
        }
        deviceNameLabel.text = "Device Name: \(viewModel?.deviceModelName ?? "Unknown")"
        self.setLeftAlignedTitle("Interoperability Test")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "shareWhite"),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(shareTestResult))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.registerNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterNotifications()
        viewModel?.stopTest()
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(showDocumentPickerView), name: .SILIOPShowFilePicker, object: nil)
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self, name: .SILIOPShowFilePicker, object: nil)
    }
    
    @IBAction func floatingButtonPressed() {
        if currentTestState! != .running {
            viewModel?.startTest()
        } else {
            showPopupAlert()
        }
    }
    
    func setupFloatingButton() {
        self.floatingButton.setTitle(self.buttonText(), for: .normal)
    }
    
    func buttonText() -> String {
        guard let currentTestState = currentTestState else {
            return "Run Test"
        }
        
        switch(currentTestState) {
        case .initiated, .ended:
            return "Run Test"
        case .running:
            return "Stop Test"
        }
    }
    
    func subscribeToUpdateUINotifications() {
        guard let viewModel = viewModel else { return }
        weak var weakSelf = self
        let updateTableViewSubscription = viewModel.updateTableViewWithCurrentTestScenarioIndex.observe( { index in
            guard let weakSelf = weakSelf else { return }
            if weakSelf.currentTestScenarioIndex != index {
                if index < 2 {
                    weakSelf.currentTestScenarioIndex = 0
                } else {
                    weakSelf.currentTestScenarioIndex = index
                }
                let indexPath = IndexPath(row: 0, section: weakSelf.currentTestScenarioIndex)
                if #available(iOS 13, *) {
                    weakSelf.tableView.layoutIfNeeded()
                }
                weakSelf.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
            weakSelf.tableView.reloadData()
        })
        disposeBag.add(token: updateTableViewSubscription)
        
        let testCasesInProgressSubscription = viewModel.testCasesInProgress.observe( { testCasesInProgress in
            guard let weakSelf = weakSelf else { return }
            weakSelf.totalTestCases.text = "Total: \(testCasesInProgress) Test Cases"
        })
        disposeBag.add(token: testCasesInProgressSubscription)
        
        let testStateStatusSubscription = viewModel.testStateStatus.observe( { status in
            guard let weakSelf = weakSelf else { return }
            weakSelf.currentTestState = status
            weakSelf.setupFloatingButton()
        })
        disposeBag.add(token: testStateStatusSubscription)
        
        let bluetoothStateSubscription = viewModel.bluetoothState.observe( { state in
            guard let weakSelf = weakSelf else { return }
            if state == false {
                weakSelf.showBluetoothDisabledAlert()
            }
        })
        disposeBag.add(token: bluetoothStateSubscription)
    }
    
    private func showPopupAlert() {
        guard self.currentTestState == .running else {
            return
        }
        
        let alert = UIAlertController(title: "Are you sure you want to stop the test?", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .default)
        let okAction = UIAlertAction(title: "Yes", style: .destructive) { (action) in
            self.viewModel?.endTesting()
        }

        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
 
    @objc func shareTestResult() {
        guard let viewModel = viewModel, currentTestState != .initiated else { return }
        let filesToShare = [viewModel.getReportFile() as Any] as [Any]
        let iopTestLogSubject = "IOP Test Log"
        
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        activityViewController.setValue(iopTestLogSubject, forKey: "Subject")
        activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func showBluetoothDisabledAlert() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.interoperabilityTest
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message, completion: { _ in
            self.viewModel?.stopTest()
        })
    }
    
    //MARK: INITIALIZE VIEW MODEL
    
    func setupViewModel() {
        guard let deviceName =  self.deviceNameToSearch else { return }
        self.viewModel = SILIOPTesterViewModel(deviceNameToSearch: deviceName)
    }
    
    func showDocumentPickerView() {
        let documentPickerViewController = SILDocumentPickerViewController(documentTypes: ["public.gbl"], in: .import)
        documentPickerViewController.setupDocumentPickerView()
        documentPickerViewController.delegate = self
        self.present(documentPickerViewController, animated: false, completion: nil)
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellViewModel = self.viewModel?.cellViewModels[indexPath.section] as SILCellViewModel?
        
        guard let cellViewModel = cellViewModel else { return UITableViewCell() }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as?  SILIOPTestScenarioCellView else { return UITableViewCell() }
        
        cell.setViewModel(cellViewModel)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.cellViewModels.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
        
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 5.0)
    }
}

extension SILIOPTesterViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        debugPrint("DID PICK")
        self.sendChosenUrl(urls: urls)
    }
    
    private func sendChosenUrl(urls: [URL]) {
        if let gblFile = urls.first {
            let gblFileDict: [String: Any] = ["gblFileUrl": gblFile]
            
            NotificationCenter.default.post(Notification(name: .SILIOPFileUrlChosen, object: nil, userInfo: gblFileDict))
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        debugPrint("DID CANCEL")
        NotificationCenter.default.post(Notification(name: .SILIOPFileUrlChosen, object: nil, userInfo: nil))
        controller.dismiss(animated: true, completion: nil)
    }
}
