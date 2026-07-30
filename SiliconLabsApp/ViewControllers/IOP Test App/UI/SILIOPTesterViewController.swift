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
class SILIOPTesterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SILIOPTesterViewModelDelegate {
    
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
    
    private var throughputResultObserver: NSObjectProtocol?
    private var throughputContinueWithoutPopupObserver: NSObjectProtocol?
    private var expertLogObserver: NSObjectProtocol?
    private weak var throughputPopupViewController: SILIOPThroughputPopupViewController?
    
    private var currentTestState: SILIOPTesterViewModel.TestState?
    private var currentTestScenarioIndex: Int = 0
    private var expertLogEntries: [SILIOPExpertLogEntry] = []
    private var pendingExpertLogEntries: [SILIOPExpertLogEntry] = []
    private var expertLogFlushWorkItem: DispatchWorkItem?
    private let modeControl = UISegmentedControl(items: ["STANDARD", "EXPERT"])
    private let expertTableView = UITableView(frame: .zero, style: .plain)
    
    private static let descriptionFont = UIFont(name: "Stolzl-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
    private static let cellVerticalPadding: CGFloat = 48
    private static let minCellHeight: CGFloat = 80
    // Horizontal overhead between the screen edge and the description label (table margins + cell paddings + status view).
    private static let descriptionWidthOverhead: CGFloat = 127
    private var heightCache: [String: CGFloat] = [:]
    private let expertLogReuseIdentifier = "SILIOPExpertLogCell"
    private lazy var shareBarButtonItem = UIBarButtonItem(image: UIImage(named: "shareWhite"),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(shareTestResult))
    private lazy var gattInfoBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                                                             style: .plain,
                                                             target: self,
                                                             action: #selector(showGATTReference))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addRedLineBelowNavigationBar()
        self.disposeBag = SILObservableTokenBag()
        self.setupViewModel()
        self.setupFloatingButton()
        self.setupModeControl()
        self.setupExpertTableView()
        self.subscribeToUpdateUINotifications()
        self.floatingButton.layer.cornerRadius = 10
        infoView.addShadow()
        // Bottom inset so the last cell's shadow + rounded corner aren't clipped by the table edge.
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        if let deviceNameToSearch = deviceNameToSearch {
            firmwareNameLabel.text = "  \(deviceNameToSearch)"
        }
        deviceNameLabel.text = "  \(viewModel?.deviceModelName ?? "  Unknown")"
        self.setLeftAlignedTitle("Interoperability Test")
        self.navigationItem.rightBarButtonItems = [gattInfoBarButtonItem, shareBarButtonItem]
        updateNavigationButtonStates()
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
        throughputResultObserver = NotificationCenter.default.addObserver(forName: .SILIOPThroughputResultReady, object: nil, queue: .main) { [weak self] notification in
            self?.presentThroughputPopupIfNeeded(from: notification)
        }
        throughputContinueWithoutPopupObserver = NotificationCenter.default.addObserver(forName: .SILIOPThroughputContinueWithoutPopup, object: nil, queue: .main) { [weak self] _ in
            self?.viewModel?.continueAfterThroughputScenarioDeferred()
        }
        expertLogObserver = NotificationCenter.default.addObserver(forName: .SILIOPExpertLogDidAppend, object: nil, queue: .main) { [weak self] notification in
            self?.appendExpertLogEntry(from: notification)
        }
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self, name: .SILIOPShowFilePicker, object: nil)
        if let throughputResultObserver = throughputResultObserver {
            NotificationCenter.default.removeObserver(throughputResultObserver)
            self.throughputResultObserver = nil
        }
        if let throughputContinueWithoutPopupObserver = throughputContinueWithoutPopupObserver {
            NotificationCenter.default.removeObserver(throughputContinueWithoutPopupObserver)
            self.throughputContinueWithoutPopupObserver = nil
        }
        if let expertLogObserver = expertLogObserver {
            NotificationCenter.default.removeObserver(expertLogObserver)
            self.expertLogObserver = nil
        }
    }
    
    private func setupModeControl() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.appLineGrey.withAlphaComponent(0.65).cgColor
        container.layer.masksToBounds = true
        container.heightAnchor.constraint(equalToConstant: 52).isActive = true
        
        modeControl.selectedSegmentIndex = 0
        modeControl.selectedSegmentTintColor = UIColor.sil_siliconLabsRed()
        modeControl.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
        modeControl.layer.cornerRadius = 12
        modeControl.layer.borderWidth = 1
        modeControl.layer.borderColor = UIColor.appLineGrey.withAlphaComponent(0.65).cgColor
        modeControl.layer.masksToBounds = true
        modeControl.translatesAutoresizingMaskIntoConstraints = false
        modeControl.addTarget(self, action: #selector(modeControlChanged), for: .valueChanged)
        modeControl.setTitleTextAttributes([
            .foregroundColor: UIColor.sil_subtitleText(),
            .font: UIFont(name: "Stolzl-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        ], for: .normal)
        modeControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "Stolzl-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        ], for: .selected)
        container.addSubview(modeControl)
        
        NSLayoutConstraint.activate([
            modeControl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            modeControl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            modeControl.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            modeControl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        allSpace.insertArrangedSubview(container, at: 0)
    }
    
    private func setupExpertTableView() {
        guard let containerView = tableView.superview else { return }
        
        expertTableView.translatesAutoresizingMaskIntoConstraints = false
        expertTableView.backgroundColor = .clear
        expertTableView.separatorStyle = .none
        expertTableView.dataSource = self
        expertTableView.delegate = self
        expertTableView.estimatedRowHeight = 96
        expertTableView.rowHeight = UITableView.automaticDimension
        expertTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        expertTableView.register(SILIOPExpertLogCell.self, forCellReuseIdentifier: expertLogReuseIdentifier)
        expertTableView.isHidden = true
        containerView.addSubview(expertTableView)
        
        NSLayoutConstraint.activate([
            expertTableView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            expertTableView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            expertTableView.topAnchor.constraint(equalTo: tableView.topAnchor),
            expertTableView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
    }
    
    @objc private func modeControlChanged() {
        let isExpertMode = modeControl.selectedSegmentIndex == 1
        tableView.isHidden = isExpertMode
        expertTableView.isHidden = !isExpertMode
    }
    
    private func appendExpertLogEntry(from notification: Notification) {
        let info = notification.userInfo ?? [:]
        let entry = SILIOPExpertLogEntry(
            timestamp: info[SILIOPExpertLogKeys.timestamp] as? String ?? Date().toString(),
            category: info[SILIOPExpertLogKeys.category] as? String ?? "LOG",
            title: info[SILIOPExpertLogKeys.title] as? String ?? "",
            detail: (info[SILIOPExpertLogKeys.detail] as? String)?.isEmpty == true ? nil : info[SILIOPExpertLogKeys.detail] as? String,
            tone: info[SILIOPExpertLogKeys.tone] as? String ?? "info"
        )

        pendingExpertLogEntries.append(entry)
        scheduleExpertLogFlush()
    }
    
    private func clearExpertLog() {
        expertLogFlushWorkItem?.cancel()
        expertLogFlushWorkItem = nil
        pendingExpertLogEntries.removeAll()
        expertLogEntries = []
        expertTableView.reloadData()
    }
    
    private func scheduleExpertLogFlush() {
        guard expertLogFlushWorkItem == nil else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.expertLogFlushWorkItem = nil
            self?.flushPendingExpertLogEntries()
        }
        expertLogFlushWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)
    }
    
    private func flushPendingExpertLogEntries() {
        guard !pendingExpertLogEntries.isEmpty else { return }
        
        var didChangeEntries = false
        for entry in pendingExpertLogEntries {
            if let lastIndex = expertLogEntries.indices.last,
               expertLogEntries[lastIndex].canCollapse(with: entry) {
                expertLogEntries[lastIndex].repeatCount += 1
                expertLogEntries[lastIndex].timestamp = entry.timestamp
            } else {
                expertLogEntries.append(entry)
            }
            didChangeEntries = true
        }
        pendingExpertLogEntries.removeAll()
        
        guard didChangeEntries else { return }
        
        UIView.performWithoutAnimation {
            expertTableView.reloadData()
            expertTableView.layoutIfNeeded()
        }
        
        guard !expertLogEntries.isEmpty else { return }
        let lastRow = expertLogEntries.count - 1
        let indexPath = IndexPath(row: lastRow, section: 0)
        expertTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
    
    private func presentThroughputPopupIfNeeded(from notification: Notification) {
        let info = notification.userInfo ?? [:]
        let speed: Double = {
            if let d = info[SILIOPThroughputPopupKeys.speedKbps] as? Double { return d }
            if let n = info[SILIOPThroughputPopupKeys.speedKbps] as? NSNumber { return n.doubleValue }
            return 0
        }()
        let mtu: Int = {
            if let i = info[SILIOPThroughputPopupKeys.mtuSize] as? Int { return i }
            if let n = info[SILIOPThroughputPopupKeys.mtuSize] as? NSNumber { return n.intValue }
            return 247
        }()
        let buffer: Int = {
            if let i = info[SILIOPThroughputPopupKeys.bufferSize] as? Int { return i }
            if let n = info[SILIOPThroughputPopupKeys.bufferSize] as? NSNumber { return n.intValue }
            return max(0, mtu - 3)
        }()
        let isCompleted: Bool = {
            if let value = info[SILIOPThroughputPopupKeys.isCompleted] as? Bool { return value }
            if let value = info[SILIOPThroughputPopupKeys.isCompleted] as? NSNumber { return value.boolValue }
            return true
        }()
        let maxSpeed: Double = {
            if let d = info[SILIOPThroughputPopupKeys.maxSpeedKbps] as? Double { return d }
            if let n = info[SILIOPThroughputPopupKeys.maxSpeedKbps] as? NSNumber { return n.doubleValue }
            return speed
        }()
        let averageSpeed: Double = {
            if let d = info[SILIOPThroughputPopupKeys.averageSpeedKbps] as? Double { return d }
            if let n = info[SILIOPThroughputPopupKeys.averageSpeedKbps] as? NSNumber { return n.doubleValue }
            return speed
        }()
        let targetSpeed: Double = {
            if let d = info[SILIOPThroughputPopupKeys.targetSpeedKbps] as? Double { return d }
            if let n = info[SILIOPThroughputPopupKeys.targetSpeedKbps] as? NSNumber { return n.doubleValue }
            return 0
        }()
        if let popup = throughputPopupViewController {
            popup.update(speedKbps: speed, maxSpeedKbps: maxSpeed, averageSpeedKbps: averageSpeed, targetSpeedKbps: targetSpeed, isCompleted: isCompleted)
            return
        }
        let popup = SILIOPThroughputPopupViewController(speedKbps: speed, maxSpeedKbps: maxSpeed, averageSpeedKbps: averageSpeed, targetSpeedKbps: targetSpeed, mtuSize: mtu, bufferSize: buffer, isCompleted: isCompleted)
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve
        popup.onContinueThroughputSuite = { [weak self] in
            self?.throughputPopupViewController = nil
            self?.viewModel?.continueAfterThroughputScenarioDeferred()
        }
        throughputPopupViewController = popup
        present(popup, animated: true)
    }
    
    @IBAction func floatingButtonPressed() {
        if currentTestState! != .running {
            clearExpertLog()
            viewModel?.startTest()
        } else {
            showPopupAlert()
        }
    }
    
    func setupFloatingButton() {
        self.floatingButton.setTitle(self.buttonText(), for: .normal)
    }
    
    private func updateNavigationButtonStates() {
        let isRunning = currentTestState == .running
        gattInfoBarButtonItem.isEnabled = !isRunning
        gattInfoBarButtonItem.tintColor = !isRunning ? UIColor.white : UIColor.white.withAlphaComponent(0.45)
        shareBarButtonItem.tintColor = UIColor.white
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
            let sections = weakSelf.viewModel?.cellViewModels.count ?? 0
            // Clamp Scan/Connect to row 0 so the auto-scroll doesn't chase short-lived early scenarios.
            let targetIndex = index < 2 ? 0 : index
            let activeChanged = weakSelf.currentTestScenarioIndex != targetIndex
            if activeChanged {
                weakSelf.currentTestScenarioIndex = targetIndex
            }
            // Update the visible cell in place — reloadSections() detaches/re-attaches the row and makes it visibly jump.
            if index >= 0 && index < sections,
               let scenarioVM = weakSelf.viewModel?.cellViewModels[index] as? SILIOPTestScenarioCellViewModel,
               scenarioVM.shouldUpdateView,
               let cell = weakSelf.tableView.cellForRow(at: IndexPath(row: 0, section: index)) as? SILIOPTestScenarioCellView {
                UIView.performWithoutAnimation {
                    cell.setViewModel(scenarioVM)
                }
            }
            // Scroll once per scenario transition with .none so already-visible rows stay put.
            if activeChanged && targetIndex >= 0 && targetIndex < sections {
                let indexPath = IndexPath(row: 0, section: targetIndex)
                weakSelf.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
            }
        })
        disposeBag.add(token: updateTableViewSubscription)
        
        let testCasesInProgressSubscription = viewModel.testCasesInProgress.observe( { testCasesInProgress in
            guard let weakSelf = weakSelf else { return }
            weakSelf.totalTestCases.text = "  \(testCasesInProgress) Test Cases"
        })
        disposeBag.add(token: testCasesInProgressSubscription)
        
        let testStateStatusSubscription = viewModel.testStateStatus.observe( { status in
            guard let weakSelf = weakSelf else { return }
            let previousState = weakSelf.currentTestState
            weakSelf.currentTestState = status
            weakSelf.setupFloatingButton()
            weakSelf.updateNavigationButtonStates()
            // On Run Test, reset visible cells in place to clear stale Pass/Fail badges from a previous run.
            if status == .running && previousState != .running {
                weakSelf.refreshAllVisibleScenarioCells()
            }
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
    
    private func refreshAllVisibleScenarioCells() {
        UIView.performWithoutAnimation {
            for indexPath in tableView.indexPathsForVisibleRows ?? [] {
                guard let cell = tableView.cellForRow(at: indexPath) as? SILIOPTestScenarioCellView,
                      let scenarioVM = viewModel?.cellViewModels[indexPath.section] as? SILIOPTestScenarioCellViewModel else { continue }
                cell.setViewModel(scenarioVM)
            }
        }
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
        
        let alert = UIAlertController(title: "Select log file.", message: "", preferredStyle: .alert)
        let debugLog = UIAlertAction(title: "Application Debug Log", style: .default) { (action) in
            self.shareLogFile(logType: "ConsoleLog")
        }
        
        let resultLog = UIAlertAction(title: "Test Result Log", style: .default) { (action) in
            self.shareLogFile(logType: "UILog")
        }
        
       
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        alert.addAction(resultLog)
        alert.addAction(debugLog)
        alert.addAction(cancelAction)
        //alert.popoverPresentationController?.sourceView = self.btnShare
        self.present(alert, animated: true, completion: nil)

        
        //Console:
//         let fileSh = viewModel.getConsolLogsFile()
//   
////        if let file = viewModel.getMeshLogsFile() {
////            self.shareTestResultTemp(fileURL: file, fileName: "Application/Mesh Logs")
////        }
//
//        
//        let iopTestLogSubject = "IOP Test Log"
//        
//        let activityViewController = UIActivityViewController(activityItems: [fileSh as Any], applicationActivities: nil)
//        activityViewController.setValue(iopTestLogSubject, forKey: "Subject")
//        activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
//        
//        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc private func showGATTReference() {
        guard currentTestState != .running else { return }
        let controller = SILIOPGATTInfoViewController(deviceName: deviceNameToSearch)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        present(navigationController, animated: true)
    }
    
    func shareLogFile(logType: String)  {
        guard let viewModel = viewModel, currentTestState != .initiated else { return }
        if logType == "UILog" {
            viewModel.prepareTestReport()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            var filesToShare:[Any] = []
            if logType == "UILog" {
                filesToShare = [viewModel.getReportFile() as Any]
            }else if logType == "ConsoleLog" {
                filesToShare = [viewModel.getConsolLogsFile() as Any]
            }
            
            let iopTestLogSubject = "IOP Test Log"
            
            let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            activityViewController.setValue(iopTestLogSubject, forKey: "Subject")
            activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            
            self.present(activityViewController, animated: true, completion: nil)
        }

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
        
       self.viewModel?.SILIOPTesterViewModelDelegate = self
    }
    
    func showDocumentPickerView() {
        let documentPickerViewController = SILDocumentPickerViewController(documentTypes: ["public.gbl"], in: .import)
        documentPickerViewController.setupDocumentPickerView()
        documentPickerViewController.delegate = self
        self.present(documentPickerViewController, animated: false, completion: nil)
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == expertTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: expertLogReuseIdentifier, for: indexPath) as? SILIOPExpertLogCell else {
                return UITableViewCell()
            }
            cell.setEntry(expertLogEntries[indexPath.row])
            return cell
        }
        
        var cellViewModel = self.viewModel?.cellViewModels[indexPath.section] as SILCellViewModel?
        
        guard let cellViewModel = cellViewModel else { return UITableViewCell() }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as?  SILIOPTestScenarioCellView else { return UITableViewCell() }
        
        cell.setViewModel(cellViewModel)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == expertTableView {
            return 1
        }
        return viewModel?.cellViewModels.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == expertTableView {
            return expertLogEntries.count
        }
        return 1
    }
    
    // Use screen width as a stable source so multi-line cell heights don't change between layout passes.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == expertTableView {
            return UITableView.automaticDimension
        }
        guard let cellViewModel = self.viewModel?.cellViewModels[indexPath.section] as? SILIOPTestScenarioCellViewModel else {
            return Self.minCellHeight
        }
        let availableWidth = max(50, UIScreen.main.bounds.width - Self.descriptionWidthOverhead)
        if let cached = heightCache[cellViewModel.description] { return cached }
        let descRect = (cellViewModel.description as NSString).boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: Self.descriptionFont],
            context: nil
        )
        let height = max(Self.minCellHeight, ceil(descRect.height) + Self.cellVerticalPadding)
        heightCache[cellViewModel.description] = height
        return height
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard tableView == self.tableView else { return }
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard tableView == self.tableView else { return nil }
        return SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 5.0)
    }
}

extension SILIOPTesterViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        IOPLog().step(source: "SILIOPTesterViewController",
                      action: "Selected OTA file from document picker",
                      detail: urls.first?.lastPathComponent ?? "No file name available")
        self.sendChosenUrl(urls: urls)
    }
    
    private func sendChosenUrl(urls: [URL]) {
        if let gblFile = urls.first {
            let gblFileDict: [String: Any] = ["gblFileUrl": gblFile]
            
            NotificationCenter.default.post(Notification(name: .SILIOPFileUrlChosen, object: nil, userInfo: gblFileDict))
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        IOPLog().step(source: "SILIOPTesterViewController",
                      action: "Cancelled OTA file selection",
                      detail: "Document picker was dismissed without choosing a file.")
        NotificationCenter.default.post(Notification(name: .SILIOPFileUrlChosen, object: nil, userInfo: nil))
        controller.dismiss(animated: true, completion: nil)
    }
}
//MARK: SILIOPTesterViewModelDelegate
extension SILIOPTesterViewController {
    func notifyAfterAllTest() {
        print("END")
        DispatchQueue.main.async {
            let SILIOPDeviceResetInfoPopupViewControllerObj = SILIOPDeviceResetInfoPopupViewController(nibName: "SILIOPDeviceResetInfoPopupViewController", bundle: nil)
        SILIOPDeviceResetInfoPopupViewControllerObj.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(SILIOPDeviceResetInfoPopupViewControllerObj, animated: false)
        }
 
    }
}

private final class SILIOPExpertLogCell: UITableViewCell {
    private let accentBar = UIView()
    private let containerCard = UIView()
    private let timestampLabel = UILabel()
    private let categoryLabel = UILabel()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private var accentWidthConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        accentBar.layer.cornerRadius = 2
        contentView.addSubview(accentBar)
        accentWidthConstraint = accentBar.widthAnchor.constraint(equalToConstant: 4)
        
        containerCard.translatesAutoresizingMaskIntoConstraints = false
        containerCard.backgroundColor = .white
        containerCard.layer.cornerRadius = 12
        containerCard.layer.borderWidth = 1
        contentView.addSubview(containerCard)
        
        timestampLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        timestampLabel.textColor = UIColor.sil_subtitleText()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        
        categoryLabel.font = UIFont(name: "Stolzl-Medium", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .semibold)
        categoryLabel.textAlignment = .center
        categoryLabel.layer.cornerRadius = 9
        categoryLabel.layer.masksToBounds = true
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont(name: "Stolzl-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = UIColor.sil_primaryText()
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        detailLabel.font = UIFont(name: "Stolzl-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        detailLabel.textColor = UIColor.sil_subtitleText()
        detailLabel.numberOfLines = 0
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerCard.addSubview(timestampLabel)
        containerCard.addSubview(categoryLabel)
        containerCard.addSubview(titleLabel)
        containerCard.addSubview(detailLabel)
        
        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            accentBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            accentWidthConstraint!,
            
            containerCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerCard.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 8),
            containerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            timestampLabel.topAnchor.constraint(equalTo: containerCard.topAnchor, constant: 12),
            timestampLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 12),
            
            categoryLabel.centerYAnchor.constraint(equalTo: timestampLabel.centerYAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -12),
            categoryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 46),
            categoryLabel.heightAnchor.constraint(equalToConstant: 18),
            
            titleLabel.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -12),
            
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 12),
            detailLabel.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -12),
            detailLabel.bottomAnchor.constraint(equalTo: containerCard.bottomAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setEntry(_ entry: SILIOPExpertLogEntry) {
        timestampLabel.text = entry.timestamp
        titleLabel.text = entry.title
        detailLabel.text = entry.detail
        detailLabel.isHidden = entry.detail?.isEmpty ?? true
        
        let style = visualStyle(for: entry.tone)
        let isMilestone = entry.isMilestone
        let shouldShowCategoryBadge = Self.shouldShowCategoryBadge(for: entry)
        categoryLabel.isHidden = !shouldShowCategoryBadge
        categoryLabel.text = shouldShowCategoryBadge
            ? (entry.repeatCount > 1 ? " \(entry.category) x\(entry.repeatCount) " : " \(entry.category) ")
            : nil
        accentBar.backgroundColor = style.accent
        accentWidthConstraint?.constant = isMilestone ? 8 : 4
        containerCard.layer.borderColor = style.border.cgColor
        containerCard.layer.borderWidth = isMilestone ? 0 : 1
        containerCard.backgroundColor = isMilestone ? style.background : .white
        timestampLabel.textColor = style.accent
        categoryLabel.textColor = style.accent
        categoryLabel.backgroundColor = style.background
        titleLabel.textColor = style.title
        detailLabel.textColor = isMilestone ? style.title.withAlphaComponent(0.72) : UIColor.sil_subtitleText()
        titleLabel.font = isMilestone
            ? (UIFont(name: "Stolzl-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .semibold))
            : (UIFont(name: "Stolzl-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium))
        timestampLabel.font = isMilestone
            ? UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
            : UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    }
    
    private static func shouldShowCategoryBadge(for entry: SILIOPExpertLogEntry) -> Bool {
        switch entry.category {
        case "PASS", "FAIL", "WAIT", "RUN", "SCENARIO", "TEST":
            return true
        default:
            return false
        }
    }
    
    private func visualStyle(for tone: String) -> (accent: UIColor, background: UIColor, border: UIColor, title: UIColor) {
        switch tone {
        case "success":
            return (.systemGreen, UIColor.systemGreen.withAlphaComponent(0.12), UIColor.systemGreen.withAlphaComponent(0.25), UIColor.sil_primaryText())
        case "failure":
            return (.systemRed, UIColor.systemRed.withAlphaComponent(0.12), UIColor.systemRed.withAlphaComponent(0.25), UIColor.systemRed.darker())
        case "warning":
            return (.systemOrange, UIColor.systemOrange.withAlphaComponent(0.12), UIColor.systemOrange.withAlphaComponent(0.25), UIColor.sil_primaryText())
        case "session":
            return (UIColor.sil_siliconLabsRed(), UIColor.sil_siliconLabsRed().withAlphaComponent(0.10), UIColor.sil_siliconLabsRed().withAlphaComponent(0.20), UIColor.sil_primaryText())
        case "test":
            return (.darkGray, UIColor.darkGray.withAlphaComponent(0.08), UIColor.darkGray.withAlphaComponent(0.18), UIColor.sil_primaryText())
        default:
            return (UIColor.systemBlue.withAlphaComponent(0.78),
                    UIColor.systemBlue.withAlphaComponent(0.10),
                    UIColor.systemBlue.withAlphaComponent(0.22),
                    UIColor.sil_primaryText())
        }
    }
}

private extension UIColor {
    func darker() -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return self }
        return UIColor(red: max(red - 0.18, 0),
                       green: max(green - 0.18, 0),
                       blue: max(blue - 0.18, 0),
                       alpha: alpha)
    }
}
