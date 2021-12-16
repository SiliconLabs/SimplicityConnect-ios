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
class SILIOPTesterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var allSpace: UIStackView!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var navigationBarTitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var firmwareNameLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var totalTestCases: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var runTestButton: UIButton!
    
    private var viewModel: SILIOPTesterViewModel!
    var deviceNameToSearch: String?

    private var disposeBag = SILObservableTokenBag()
    
    private var currentTestState: SILIOPTesterViewModel.TestState?
    private var currentTestScenarioIndex: Int = 0
    
    //MARK: ViewController LifeCycle Method
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViewModel()
        self.setupView()
        self.subscribeToUpdateUINotifications()
        infoView.addShadow()
        if let deviceNameToSearch = deviceNameToSearch {
            firmwareNameLabel.text = "Firmware Name: \(deviceNameToSearch)"
        }
        deviceNameLabel.text = "Device Name: \(UIDevice.deviceName)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.registerNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(showDocumentPickerView), name: .SILIOPShowFilePicker, object: nil)
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self, name: .SILIOPShowFilePicker, object: nil)
    }
    
    //MARK: Initialize Views
    func setupView() {
        runTestButton.setTitle("Run Tests", for: .normal)
        runTestButton.setTitle("Waiting...", for: .disabled)
        
        self.setupNavigationBar()
    }
    
    func setupNavigationBar() {
        navigationBarTitleLabel.adjustsFontSizeToFitWidth = true
        navigationBarView.addShadow()
        allSpace.bringSubviewToFront(navigationBarView)
    }
    
    func subscribeToUpdateUINotifications() {
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
            weakSelf.updateInfoView(newState: status)
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
    
    private func updateInfoView(newState: SILIOPTesterViewModel.TestState) {
        switch newState {
        case .initiated:
            shareButton.isHidden = true
            runTestButton.isEnabled = true

            runTestButton.backgroundColor = UIColor.sil_regularBlue()
            
        case .running:
            shareButton.isHidden = true
            runTestButton.isEnabled = false
            runTestButton.backgroundColor = .lightGray
            
        case .ended:
            shareButton.isHidden = false
            runTestButton.isEnabled = true
            runTestButton.backgroundColor = UIColor.sil_regularBlue()
            
        }
    }
    
    private func showPopupAlert() {
        guard self.currentTestState == .running else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        let alert = UIAlertController(title: "Are you sure you want to stop the test?", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .default)
        let okAction = UIAlertAction(title: "Yes", style: .destructive) { (action) in
            self.viewModel.stopTest()
            self.navigationController?.popViewController(animated: true)
        }

        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
 
    private func shareTestResult() {
        let filesToShare = [viewModel.getReportFile()] as [Any]
        let iopTestLogSubject = "IOP Test Log"
        
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        activityViewController.setValue(iopTestLogSubject, forKey: "Subject")
        
        activityViewController.popoverPresentationController?.sourceView = self.shareButton
        activityViewController.popoverPresentationController?.sourceRect = self.shareButton.bounds
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func showBluetoothDisabledAlert() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.interoperabilityTest
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message, completion: { _ in
            self.viewModel.stopTest()
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    //MARK: INITIALIZE VIEW MODEL
    
    func setupViewModel() {
        guard let deviceName =  self.deviceNameToSearch else { return }
        self.viewModel = SILIOPTesterViewModel(deviceNameToSearch: deviceName)
    }
    
    //MARK: Action Methods
    @IBAction func didTappedRunOrStopBtn(_ sender: Any) {
        self.viewModel.startTest()
    }
    
    @IBAction func didTappedShareBtn(_ sender: Any) {
        self.shareTestResult()
    }
    
    @IBAction func tappedBackBtn(_ sender: Any) {
        self.showPopupAlert()
    }
    
    func showDocumentPickerView() {
        let documentPickerView = SILDocumentPickerViewController(documentTypes: ["public.gbl"], in: .import)
        documentPickerView.delegate = self
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.sil_regularBlue()], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.sil_regularBlue()
        self.present(documentPickerView, animated: false, completion: nil)
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var _cellViewModel: SILCellViewModel?
        _cellViewModel = self.viewModel.cellViewModels[indexPath.section] as SILCellViewModel
        
        guard let cellViewModel = _cellViewModel else { return UITableViewCell() }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as?  SILIOPTestScenarioCellView else { return UITableViewCell() }
        
        cell.setViewModel(cellViewModel)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
        
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 20.0)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        showPopupAlert()
        return false
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
