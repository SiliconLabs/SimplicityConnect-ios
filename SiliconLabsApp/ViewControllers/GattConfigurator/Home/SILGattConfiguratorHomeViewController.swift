//
//  SILGattConfiguratorHomeViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 01/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit
import CoreBluetooth
import SVProgressHUD

class SILGattConfiguratorHomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SILGattConfiguratorHomeViewDelegate {

    @IBOutlet weak var allSpace: UIStackView!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var aboveSafeAreaView: UIView!
    @IBOutlet weak var navigationBarTitleLabel: UILabel!
    @IBOutlet weak var configurationsTableView: UITableView!
    @IBOutlet weak var exportCheckBoxTableView: UITableView!
    @IBOutlet weak var noConfigurationsView: UIStackView!
    @IBOutlet weak var exportButtonView: UIView!
    @IBOutlet weak var exportViewHeight: NSLayoutConstraint!
    @IBOutlet weak var exportCheckBoxTableViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var exportButton: SILPrimaryButton!
    @IBOutlet weak var cancelExportButton: SILPrimaryButton!
    
    var viewModel: SILGattConfiguratorHomeViewModel!
    var dataSource: [SILGattConfiguratorCellViewModel] = []
    var checkBoxDataSource: [SILGattConfiguratorCheckBoxCellViewModel] = []
    
    private var tokenBag = SILObservableTokenBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupNormalModeView()
        disallowMutlipleTouchesInTheExportModeView()
        setupLogic()
        viewModel.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func setupNavigationBar() {
        navigationBarView.backgroundColor = UIColor.sil_siliconLabsRed()
        aboveSafeAreaView.backgroundColor = UIColor.sil_siliconLabsRed()
        
        navigationBarTitleLabel.font = UIFont.robotoMedium(size: CGFloat(SILGattConfiguratorNavigationBarTitleFontSize))
        navigationBarTitleLabel.textColor = UIColor.sil_background()
        
        navigationBarView.addShadow()
        allSpace.bringSubviewToFront(navigationBarView)
    }
    
    private func setupNormalModeView() {
        self.exportCheckBoxTableViewWidthConstraint.constant = 16
        exportButtonView.addShadow()
        exportButtonView.isHidden = true
        exportViewHeight.constant = 0.0
    }
    
    private func disallowMutlipleTouchesInTheExportModeView() {
        exportButton.isExclusiveTouch = true
        cancelExportButton.isExclusiveTouch = true
    }
    
    private func setupLogic() {
        viewModel.isExportButtonEnable.observe { enable in
            self.exportButton.isEnabled = enable
        }.putIn(bag: tokenBag)
        
        viewModel.isMenuEnabled.observe { enabled in
            self.menuButton.isEnabled = enabled
        }.putIn(bag: tokenBag)
        
        viewModel.isExportModeOn.observe { isOn in
            self.exportButtonView.isHidden = !isOn
            self.exportViewHeight.constant = isOn ? 70.0 : 0.0
            self.exportCheckBoxTableViewWidthConstraint.constant = isOn ? 52.0 : 16.0
            self.configurationsTableView.reloadData()
            self.exportCheckBoxTableView.reloadData()
            self.exportCheckBoxTableView.setNeedsLayout()
            UIView.animate(withDuration: 0.0, delay: 0.0, options: [], animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                if self.configurationsTableView.numberOfSections > 0 && isOn {
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.configurationsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    self.exportCheckBoxTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    self.view.layoutIfNeeded()
                }
            })
        }.putIn(bag: tokenBag)
    }

    @IBAction func onBackTouch(_ sender: Any) {
        viewModel.onBack()
    }
    
    func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onMenuTouch(_ sender: UIButton) {
        viewModel.openMenu(sourceView: sender)
    }
    
    @IBAction func onExport(_ sender: UIButton) {
        showProgressView(status: "Exporting")
        viewModel.export(onFinish: { filesToShare in
            self.hideProgressView()
            self.showSharingExportFiles(filesToShare: filesToShare)
        })
    }
    
    @IBAction func onCancelExportMode(_ sender: UIButton) {
        viewModel.turnOffExportMode()
    }
    
    private func showProgressView(status: String) {
        SVProgressHUD.show(withStatus: status)
    }
    
    private func hideProgressView() {
        SVProgressHUD.dismiss()
    }
    
    // MARK: SILGattConfiguratorHomeViewDelegate
    
    func updateConfigurations(configurations: [SILGattConfiguratorCellViewModel], checkBoxCells: [SILGattConfiguratorCheckBoxCellViewModel]) {
        dataSource = configurations
        checkBoxDataSource = checkBoxCells
        configurationsTableView.reloadData()
        exportCheckBoxTableView.reloadData()
        noConfigurationsView.isHidden = dataSource.count > 0
    }
    
    func showSharingExportFiles(filesToShare: [URL]) {
        let filesToShare = filesToShare
        let gattConfiguratorSubject = "Gatt Configurator Export"
        
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.sil_regularBlue()], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.sil_regularBlue()
        activityViewController.setValue(gattConfiguratorSubject, forKey: "Subject")
        activityViewController.completionWithItemsHandler = { activity, success, items, error in
            if self.canFinishExport(activity: activity, success: success) {
                self.viewModel.turnOffExportMode()
            }
        }
        
        activityViewController.popoverPresentationController?.sourceView = self.exportButton
        activityViewController.popoverPresentationController?.sourceRect = self.exportButton.bounds
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func canFinishExport(activity: UIActivity.ActivityType?, success: Bool) -> Bool {
        let activityNotChosen = activity == .none
        let finishedActivityAction = activity != .none && success == true
        return activityNotChosen || finishedActivityAction
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let serverCellHeight: CGFloat = 100.0
        let characteristicCellHeight: CGFloat = 80.0
        
        if tableView == self.configurationsTableView {
            if indexPath.row == 0 {
                return serverCellHeight
            } else {
                return characteristicCellHeight
            }
        } else if tableView == self.exportCheckBoxTableView {
            return serverCellHeight + CGFloat(dataSource[indexPath.section].serviceCells.count) * characteristicCellHeight
        }
        
        return 0;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.configurationsTableView {
            return dataSource[section].serviceCells.count + 1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.configurationsTableView {
            var _cellViewModel: SILCellViewModel?
            if indexPath.row == 0 {
                _cellViewModel = dataSource[indexPath.section] as SILCellViewModel
                dataSource[indexPath.section].isExportModeOn = viewModel.isExportModeOn.value
            } else {
                _cellViewModel = dataSource[indexPath.section].serviceCells[indexPath.row - 1] as SILCellViewModel
            }
            guard let cellViewModel = _cellViewModel else {
                return UITableViewCell()
            }
            
            let cellView = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as! SILCellView
            cellView.setViewModel(cellViewModel)
            let cell = cellView as! UITableViewCell
            return cell
        } else {
            let cellViewModel = checkBoxDataSource[indexPath.section] as SILCellViewModel

            let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as! SILGattConfiguratorCheckBoxCellView
            cell.setViewModel(cellViewModel)
            
            return cell
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == configurationsTableView {
            exportCheckBoxTableView.contentOffset = configurationsTableView.contentOffset
            if exportCheckBoxTableView.contentOffset.y < 0.0 {
                exportCheckBoxTableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
            }
        } else if scrollView == exportCheckBoxTableView {
            configurationsTableView.contentOffset = exportCheckBoxTableView.contentOffset
            if configurationsTableView.contentOffset.y < 0.0 {
                configurationsTableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.configurationsTableView {
            tableView.deselectRow(at: indexPath, animated: true)
            if !viewModel.isExportModeOn.value {
                if indexPath.row == 0 {
                    let cellViewModel = dataSource[indexPath.section]
                    cellViewModel.changeExpand()
                    UIView.performWithoutAnimation { [weak self] in
                        self?.configurationsTableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .none)
                        self?.exportCheckBoxTableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .none)
                    }
                }
            }
        }
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == self.configurationsTableView {
            SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
            DispatchQueue.main.async {
                cell.layer.zPosition = CGFloat(tableView.numberOfRows(inSection: indexPath.section) - indexPath.row)
                tableView.setNeedsLayout()
                tableView.layoutIfNeeded()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 10.0)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForFooterInSection: section, withHeight: 8.0)
    }
}

extension SILGattConfiguratorHomeViewController: UIDocumentPickerDelegate {    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        debugPrint("DID PICK")
        self.handleImportXmls(urls: urls)
    }
    
    private func handleImportXmls(urls: [URL]) {
        if let xmlFile = urls.first {
            self.viewModel.importXml(url: xmlFile,
                                      onStarted: {
                                        self.showProgressView(status: "Importing")
                                    }, onFinish: { error in
                                        self.hideProgressView()
                                        if !error.isEmpty {
                                            self.alertWithOKButton(title: "Import with error", message: "\(self.importMessage(from: error))")
                                        } else {
                                            self.alertWithOKButton(title: "Successful import", message: "Created 1 configuration from the XML file")
                                        }
                                    })
        }
    }
    
    private func importMessage(from error: [URL: SILGattXmlParserError]) -> String {
        var description = ""
        for (_, error) in error.enumerated() {
            let url = error.key as URL
            let error = error.value as SILGattXmlParserError
            description.append("\(error.localizedDescription) in file \(url.lastPathComponent)")
        }
        return description
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        debugPrint("DID CANCEL")
        controller.dismiss(animated: true, completion: nil)
    }
}
