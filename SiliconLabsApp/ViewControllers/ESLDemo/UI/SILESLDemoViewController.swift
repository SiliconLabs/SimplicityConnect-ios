//
//  SILESLDemoViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 2.2.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD
//import WYPopoverController

protocol QRMetadataDelegate: class {
    func setQRData(_ data: ESLQRData?)
}

class SILESLDemoViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, QRMetadataDelegate, UIDocumentPickerDelegate, WYPopoverControllerDelegate {
    @IBOutlet weak var tagsTableView: UITableView!
    @IBOutlet weak var noSynchronizedTagsStackView: UIStackView!
    @IBOutlet weak var groupLedButton: UIButton!
    @IBOutlet weak var groupDisplayImageButton: UIButton!
    @IBOutlet weak var progressPopupBgView: UIView!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var progressLabel: UILabel!
    
    var popover: WYPopoverController?
    
    var viewModel: SILESLDemoViewModel!
    private let disposeBag = DisposeBag()
    
    private var msgText = "The selected image exceeds 100 KB, which may result in a longer upload time. Do you want to proceed with the upload?"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLeftAlignedTitle("ESL Network")
        setupNavigationBarButtons()
        reloadTable()
        progressPopupBgView.isHidden = true
        popupView.tb_applyRoundedCorner(10)
        UserDefaults.standard.setValue(false, forKey: "isImageUploadStarted")
        progressLabel.text = "Image update progress: "
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
        subscribeToViewModel()
        showProgressView(with: "Initializing device...")
        configureNavigationController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
        popover = nil
        SILFileWriter(exportDirName: "EslDemo").clearExportDir()
        viewModel.viewWillDisappear()
        self.navigationController?.tabBarController?.showTabBarAndUpdateFrames()
    }
    
    private func setupNavigationBarButtons() {
        let refreshButton = UIButton(type: .custom)
        refreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshButton.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        refreshButton.addTarget(self, action: #selector(refreshButtonWasTapped(_:)), for: .touchUpInside)
        let refreshBarButtonItem = UIBarButtonItem(customView: refreshButton)

        let scanButton = UIButton(type: .custom)
        scanButton.setImage(UIImage(named: "qr")!, for: .normal)
        scanButton.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        scanButton.addTarget(self, action: #selector(scanQRButtonWasTapped(_:)), for: .touchUpInside)
        let scanBarButtonItem = UIBarButtonItem(customView: scanButton)

        self.navigationItem.setRightBarButtonItems([scanBarButtonItem, refreshBarButtonItem], animated: true)
    }
    
    @objc private func refreshButtonWasTapped(_ sender: Any) {
        viewModel.listTags()
    }
    
    @objc private func scanQRButtonWasTapped(_ sender: Any) {
        if let qrScannerViewController = storyboard?.instantiateViewController(withIdentifier: "scanQR") as? QRScannerViewController {
            qrScannerViewController.viewModel = QRScannerViewModel()
            qrScannerViewController.delegate = self
            present(qrScannerViewController, animated: true, completion: nil)
        }
    }
    
    func setQRData(_ data: ESLQRData?) {
        if let qrData = data {
            if !viewModel.tagWithAddressIsProvisioned(qrData.bluetoothAddress) {
                viewModel.provisionTag(with: qrData.rawData)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.alertWithOKButton(title: "Error", message: "Tag is already provisioned")
                }
            }
        } else {
            self.alertWithOKButton(title: "Error", message: "Wrong format of QR code")
        }
    }
    
    private func subscribeToViewModel() {
        viewModel.shouldLeaveViewController.asObservable().subscribe(onNext: { [weak self] shouldLeaveViewController in
            guard let self = self else { return }
            if shouldLeaveViewController {
                self.navigationController?.popViewController(animated: true)
            }
        }).disposed(by: disposeBag)
        
        viewModel.shouldShowPopupWithError.asObservable().subscribe(onNext: { [weak self] error in
            guard let self = self else { return }
            self.hideProgressView()
            if let error = error {
                self.showInitializationErrorPopup(error: error)
            }
        }).disposed(by: disposeBag)
        
        viewModel.commandState.asObservable().subscribe(onNext: { [weak self] commandState in
            guard let self = self else { return }
            switch commandState {
            case .starting:
                if UserDefaults.standard.bool(forKey: "isImageUploadStarted") {
                    progressPopupBgView.isHidden = false
                    progressLabel.text = "Image update progress: "
                } else {
                    self.showProgressView(with: "Command in progress")
                }
            case .provisioningInProgressConfig:
                SVProgressHUD.dismiss()
                self.showProvisioningProgressPopup()
                
            case .provisioningInProgressImageUpdate(let tag):
                SVProgressHUD.dismiss()
                progressPopupBgView.isHidden = true
                self.showImageUpdatePopup(for: tag)
            
            case .finishedWithError(commandName: let commandName, error: let error):
                SVProgressHUD.dismiss()
                progressPopupBgView.isHidden = true
                self.alertWithOKButton(title: "Error", message: "Command \(commandName) failed with error \(error.localizedDescription)")
                
            case .imageUpdateProgress(progress: let progress):
                progressPopupBgView.isHidden = false
                progressLabel.text = "Image update progress:\n \(progress)"
                UserDefaults.standard.setValue(true, forKey: "isImageUploadStarted")
                SVProgressHUD.dismiss()
                self.reloadTable()
            case .completed:
                SVProgressHUD.dismiss()
                progressPopupBgView.isHidden = true
                self.reloadTable()
                
            case .completedWithPopup(text: let text):
                SVProgressHUD.dismiss()
                self.reloadTable()
                self.alertWithOKButton(title: "Basic State Response", message: text)
                
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    
    private func reloadTable() {
        self.tagsTableView.reloadData()
        let areTagsAvailable = (self.viewModel.tagViewModels.count > 0)
        self.noSynchronizedTagsStackView.isHidden = areTagsAvailable
        self.tagsTableView.isHidden = !areTagsAvailable
        self.groupLedButton.isEnabled = areTagsAvailable
        self.groupLedButton.imageView?.tintColor = areTagsAvailable ? (viewModel.areGroupLedsOn ? UIColor.sil_regularBlue() : UIColor.black) : UIColor.gray
        self.groupDisplayImageButton.isEnabled = areTagsAvailable
        self.groupDisplayImageButton.imageView?.tintColor = areTagsAvailable ? UIColor.black : UIColor.gray
    }
    
    private func showProgressView(with title: String = "") {
        SVProgressHUD.show(withStatus: title)
    }
    
    private func hideProgressView() {
        SVProgressHUD.dismiss()
    }
    
    private func configureNavigationController() {
        self.navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isEqual(self.navigationController?.interactivePopGestureRecognizer) {
            self.navigationController?.popViewController(animated: true)
            return true
        }
        
        return false
    }
    
    func cancelImageUploading() {
        progressPopupBgView.isHidden = true
        let success = viewModel.cancelImageUpload()
        if success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.progressPopupBgView.isHidden = true
                SVProgressHUD.showError(withStatus: "Image Upload Cancled!")
            }
        } else {
            print("Not Cancled!")
        }
    }
        
    @IBAction func cancelUploadAction(_ sender: Any) {
       
        let alertViewController = UIAlertController(title: "Alert", message: "Do you wish to cancel image uploading? ", preferredStyle: .alert)
        let actionYes = UIAlertAction(title: "Yes", style: .default, handler: { [weak self] alert in
            guard let self = self else { return }
            cancelImageUploading()
        })
        let actionNo = UIAlertAction(title: "No", style: .destructive, handler: { [weak self] alart in
            guard let self = self else { return }
        })
        alertViewController.addAction(actionNo)
        alertViewController.addAction(actionYes)
        present(alertViewController, animated: true)
    }
        
    @IBAction func infoButtonWasTapped(_ sender: UIButton) {
        self.alertWithOKButton(title: "Group messages",
                               message: "Unlike messages sent to specific tags, group messages prompt an immediate response from the Access Point (AP) without tracking changes on individual devices. The information about the current tag state displayed in the app may differ from the actual state.")
    }
    
    @IBAction func ledButtonWasTapped(_ sender: Any) {
        viewModel.sendAllTagsLed(ledState: !viewModel.areGroupLedsOn ? .on : .off, index: 0)
    }
    
    @IBAction func displayImageButtonWasTapped(_ sender: Any) {
        let displayImagePopup = SILESLDisplayImagePopup()
        let displayImageViewModel = SILESLDisplayImagePopupViewModel(maxImageIndex: 1,
                                                                     imageSlot0: nil,
                                                                     imageSlot1: nil,
                                                                     onCancel: { [weak self] in
            guard let self = self else { return }
            self.popover?.dismissPopover(animated: true)
        },
                                                                     onDisplayImage: { [weak self] imageIndex in
            guard let self = self else { return }
            self.popover?.dismissPopover(animated: true)
            self.viewModel.displayImageAllTags(imageIndex: imageIndex, displayIndex: 0)
        })
        displayImagePopup.viewModel = displayImageViewModel
        
        popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: displayImagePopup,
                                                               presenting: self,
                                                               delegate: self,
                                                               animated: true)
    }
    
    private func showProvisioningProgressPopup() {
        let alertViewController = UIAlertController(title: "Provisioning", message: "Do you wish to configure connected ESL Tag? If no, it will disconnect.", preferredStyle: .alert)
        let actionYes = UIAlertAction(title: "Yes", style: .default, handler: { [weak self] alert in
            guard let self = self else { return }
            self.showProgressView()
            self.viewModel.configureConnectedTag()
        })
        let actionNo = UIAlertAction(title: "No", style: .destructive, handler: { [weak self] alart in
            guard let self = self else { return }
            self.showProgressView()
            self.viewModel.disconnectConnectedTag()
        })
        alertViewController.addAction(actionNo)
        alertViewController.addAction(actionYes)
        present(alertViewController, animated: true)
    }
    
    private func showImageUpdatePopup(for tag: SILESLTag) {
        let imageUpdatePopup = SILESLImageUpdatePopup()
        let imageUpdateViewModel = SILESLImageUpdatePopupViewModel(maxImageIndex: tag.maxImageIndex,
                                                                   imageSlot0: tag.knownImages[0],
                                                                   imageSlot1: tag.knownImages[1],
                                                                   onCancel: { [weak self] in
            guard let self = self else { return }
            self.popover?.dismissPopover(animated: true)
            self.viewModel.disconnectConnectedTag()
        },
                                                                   onImageUpdate: { [weak self] imageIndex, url, showImageAfterUpdate in
            guard let self = self else { return }
            guard let url = url else { return }
            self.popover?.dismissPopover(animated: true)
            self.viewModel.imageUpdateAtProvisioning(address: tag.eslId, imageIndex: imageIndex, imageFile: url, showImageAfterUpdate: showImageAfterUpdate)
        })
        
        imageUpdatePopup.viewModel = imageUpdateViewModel
        
        self.popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: imageUpdatePopup,
                                                                    presenting: self,
                                                                    delegate: self,
                                                                    animated: true)
    }
        
    private func showInitializationErrorPopup(error: SILESLPeripheralDelegateError) {
        self.alertWithOKButton(title: "Error: \(error.localizedDescription)",
                               message: "This demo requires Bluetooth - NCP ESL Access Point sample app running on the kit. Please ensure it has been correctly flashed",
                               completion: { alertAction in
            self.backToHomeScreenActions()
        })
    }
    
    private func backToHomeScreenActions() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.tagViewModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.tagViewModels[section].isExpanded {
            return viewModel.tagViewModels[section].tagDetailViewModels.count + 1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var _cellViewModel: SILCellViewModel?
        
        if indexPath.row == 0 {
            _cellViewModel = viewModel.tagViewModels[indexPath.section] as SILCellViewModel
        } else {
            _cellViewModel = viewModel.tagViewModels[indexPath.section].tagDetailViewModels[indexPath.row - 1] as SILCellViewModel
        }
        
        guard let cellViewModel = _cellViewModel else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as! SILCellView
        
        if indexPath.row == 0 {
            (cell as? SILESLDemoTagCell)?.hostingViewController = self
        }
        
        cell.setViewModel(cellViewModel)

        return cell as! UITableViewCell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 8.0)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.numberOfSections(in: tableView) - 1 == section ?
        SILTableViewWithShadowCells.tableView(tableView, viewForFooterInSection: section, withHeight: LastFooterHeight) : nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.numberOfSections(in: tableView) - 1 == section ? LastFooterHeight : 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section > 0 ? 12.0 : 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 121.0
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let cellViewModel = viewModel.tagViewModels[indexPath.section]
            UIView.performWithoutAnimation {
                cellViewModel.isExpanded.toggle()
                UIView.performWithoutAnimation { [weak self] in
                    guard let self = self else { return }
                    self.tagsTableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .none)
                }
            }
        }
    }
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        popover = nil
    }
}
