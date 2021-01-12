//
//  SILAdvertiserDetailsViewController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertiserDetailsViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var aboveSafeAreaView: UIView!
    
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var navigationBarTitleLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var advertisingSetNameTextField: UITextField!
    
    @IBOutlet weak var bodyContainer: UIView!
    
    @IBOutlet weak var dataContainerView: UIView!
    @IBOutlet weak var advertisingDataTableContainerView: UIView!
    @IBOutlet weak var advertisingDataTableView: SILIntrinsicTableView!
    @IBOutlet weak var addDataTypeButton: UIButton!
    @IBOutlet weak var allSpaceStackView: UIStackView!
    @IBOutlet weak var availableBytesCountLabel: UILabel!
    
    @IBOutlet weak var scanResponseDataContainerView: UIView!
    @IBOutlet weak var scanResponseTableContainerView: UIView!
    @IBOutlet weak var scanResponseTableView: SILIntrinsicTableView!
    @IBOutlet weak var addScanResponseDataTypeButton: SILPrimaryButton!
    @IBOutlet weak var scanResponseBytesCountLabel: UILabel!
    
    @IBOutlet weak var timeLimitRadioButtonView: SILRadioButton!
    @IBOutlet weak var noLimitRadioButtonView: SILRadioButton!
    @IBOutlet weak var executionTimeTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var viewModel: SILAdvertiserDetailsViewModel!
    
    private var advertisingDataSource: [SILCellViewModel] = []
    private var scanResponseDataSource: [SILCellViewModel] = []
    private var advertisingDataToken: SILObservableToken?
    private var advertisingDataBytesAvailableToken: SILObservableToken?
    private var scanResponseDataToken: SILObservableToken?
    private var scanResponseBytesAvailableToken: SILObservableToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupLogic()
        setupKeyboardHandling()
        setupExecutionTime()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        DispatchQueue.main.async {
            self.bodyContainer.layer.shadowPath = UIBezierPath(roundedRect: self.bodyContainer.bounds, cornerRadius: CornerRadiusStandardValue).cgPath
            self.advertisingDataTableContainerView.layer.shadowPath = UIBezierPath(roundedRect: self.advertisingDataTableContainerView.bounds, cornerRadius: 4).cgPath
        }
    }
    
    func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
          return
        }

        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height , right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func setupExecutionTime() {
        addGestureRecognizersForRadioButtonsView()
        executionTimeTextField.text = viewModel.getExecutionTimeString()
        viewModel.updateRadioButtons(completion: { [weak self] newState in self?.updateRadioButtons(with: newState) })
    }
    
    func setupAppearance() {
        aboveSafeAreaView.backgroundColor = UIColor.sil_siliconLabsRed()

        navigationBarView.backgroundColor = UIColor.sil_siliconLabsRed()
        navigationBarTitleLabel.font = UIFont.robotoMedium(size: CGFloat(SILNavigationBarTitleFontSize))
        navigationBarTitleLabel.textColor = UIColor.sil_background()
        
        navigationBarView.layer.shadowColor = UIColor.black.cgColor
        navigationBarView.layer.shadowOpacity = 0.5
        navigationBarView.layer.shadowOffset = CGSize(width: 0, height: 1)
        navigationBarView.layer.shadowRadius = 2
        allSpaceStackView.bringSubviewToFront(navigationBarView)
        
        bodyContainer.layer.cornerRadius = CornerRadiusStandardValue
        bodyContainer.layer.shadowColor = UIColor.black.cgColor
        bodyContainer.layer.shadowOpacity = 0.3
        bodyContainer.layer.shadowOffset = CGSize.zero
        bodyContainer.layer.shadowRadius = 2
        
        advertisingDataTableContainerView.layer.cornerRadius = 4
        advertisingDataTableContainerView.layer.shadowColor = UIColor.black.cgColor
        advertisingDataTableContainerView.layer.shadowOpacity = 0.3
        advertisingDataTableContainerView.layer.shadowOffset = CGSize.zero
        advertisingDataTableContainerView.layer.shadowRadius = 2
        
        scanResponseTableContainerView.layer.cornerRadius = 4
        scanResponseTableContainerView.layer.shadowColor = UIColor.black.cgColor
        scanResponseTableContainerView.layer.shadowOpacity = 0.3
        scanResponseTableContainerView.layer.shadowOffset = CGSize.zero
        scanResponseTableContainerView.layer.shadowRadius = 2
    }
    
    func setupLogic() {
        navigationBarTitleLabel.text = viewModel.advertisingSetName
        advertisingSetNameTextField.text = viewModel.advertisingSetName
        advertisingDataTableView.dataSource = self
        scanResponseTableView.dataSource = self
        executionTimeTextField.delegate = self

        weak var weakSelf = self

        advertisingDataToken = viewModel.advertisingData.observe { data in
            weakSelf?.dataContainerView.isHidden = data.count == 0
            weakSelf?.advertisingDataSource = data
            weakSelf?.advertisingDataTableView.reloadData()
        }
        
        advertisingDataBytesAvailableToken = viewModel.advertisingDataBytesAvailable.observe { bytesAvailable in
            if bytesAvailable >= 3 {
                weakSelf?.availableBytesCountLabel.textColor = UIColor.sil_secondaryBackground()
                weakSelf?.availableBytesCountLabel.text = "\(bytesAvailable) bytes available\nFlags and TX Power will be added automatically, their values are managed internally by the system"
            } else if bytesAvailable >= 0 && bytesAvailable < 3 {
                weakSelf?.availableBytesCountLabel.textColor = UIColor.sil_secondaryBackground()
                weakSelf?.availableBytesCountLabel.text = "\(bytesAvailable) bytes available\nFlags will be added automatically\nTX Power won't be added due to out of space in the packet"
            } else {
                weakSelf?.availableBytesCountLabel.textColor = UIColor.sil_siliconLabsRed()
                weakSelf?.availableBytesCountLabel.text = "\(-1 * bytesAvailable) byte(s) beyond payload limit\nIf goes beyond advertising capacity some of it will be dropped. This is managed internally by the iOS stack"
            }
        }
        
        scanResponseDataToken = viewModel.scanResponseData.observe { data in
            weakSelf?.scanResponseDataContainerView.isHidden = data.count == 0
            weakSelf?.scanResponseDataSource = data
            weakSelf?.scanResponseTableView.reloadData()
        }
        
        scanResponseBytesAvailableToken = viewModel.scanResponseBytesAvailable.observe { bytesAvailable in
            if bytesAvailable == 28 {
                weakSelf?.scanResponseBytesCountLabel.textColor = UIColor.sil_secondaryBackground()
                weakSelf?.scanResponseBytesCountLabel.text = "28 bytes available"
            } else if bytesAvailable >= 0 && bytesAvailable < 28 {
                weakSelf?.scanResponseBytesCountLabel.textColor = UIColor.sil_secondaryBackground()
                weakSelf?.scanResponseBytesCountLabel.text = "\(bytesAvailable) bytes available\nIf you exceed the Advertising Data capacity not all bytes from the Complete Local Name will be advertised"
            } else {
                weakSelf?.scanResponseBytesCountLabel.textColor = UIColor.sil_siliconLabsRed()
                weakSelf?.scanResponseBytesCountLabel.text = "\(-1 * bytesAvailable) byte(s) beyond payload limit\nComplete Local Name won't advertise all bytes"
            }
        }
    }

    @IBAction func onBackTouch(_ sender: Any) {
        viewModel.backToHome()
    }
    
    @IBAction func onSaveTouch(_ sender: UIButton) {
        viewModel.save()
    }
    
    @IBAction func didChangeAdvertisingSetName(_ sender: UITextField) {
        viewModel.update(advertisingSetName: sender.text)
        navigationBarTitleLabel.text = sender.text
    }
    
    @IBAction func addDataType(_ sender: UIButton) {
        viewModel.addDataType(sourceView: sender)
    }
    
    @IBAction func addScanResponseDataType(_ sender: UIButton) {
        viewModel.addScanResponseDataType(sourceView: sender)
    }
    
    private func addGestureRecognizersForRadioButtonsView() {
        let tapNoLimitView = UITapGestureRecognizer(target: self, action: #selector(tapNoLimitView(_:)))
        noLimitRadioButtonView.addGestureRecognizer(tapNoLimitView)
        
        let tapTimeLimitView = UITapGestureRecognizer(target: self, action: #selector(tapTimeLimitView(_:)))
        timeLimitRadioButtonView.addGestureRecognizer(tapTimeLimitView)
    }
    
    private func updateRadioButtons(with newState: SILTimeLimitRadioButtonState) {
        switch newState {
        case .noLimit:
            noLimitRadioButtonView.select()
            timeLimitRadioButtonView.deselect()
            executionTimeTextField.isEnabled = false
            executionTimeTextField.textColor = UIColor.lightGray
        case .withLimit:
            noLimitRadioButtonView.deselect()
            timeLimitRadioButtonView.select()
            executionTimeTextField.isEnabled = true
            executionTimeTextField.textColor = UIColor.sil_primaryText()
        }
    }
    
    @objc func tapNoLimitView(_ sender: UITapGestureRecognizer?) {
        viewModel.updateExecutionTimeState(isExecutionTime: false)
        viewModel.updateRadioButtons(completion: { [weak self] newState in self?.updateRadioButtons(with: newState) })
    }
    
    @objc func tapTimeLimitView(_ sender: UITapGestureRecognizer?) {
        viewModel.updateExecutionTimeState(isExecutionTime: true)
        viewModel.updateRadioButtons(completion: { [weak self] newState in self?.updateRadioButtons(with: newState)})
    }
    
    
    @IBAction func didChangeExecutionTime(_ sender: UITextField) {
        viewModel.updateExecutionTimeString(sender.text)
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == advertisingDataTableView {
            return advertisingDataSource.count
        } else {
            return scanResponseDataSource.count
        }
    }
    
    // oddzielne cellki w table VIEW XDDD
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == advertisingDataTableView {
            let cellViewModel = advertisingDataSource[indexPath.row]
            let cellView = advertisingDataTableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as! SILCellView
        
            cellView.setViewModel(cellViewModel)
        
            return cellView as! UITableViewCell
        } else {
            let cellViewModel = scanResponseDataSource[indexPath.row]
            let cellView = scanResponseTableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as! SILCellView
            
            cellView.setViewModel(cellViewModel)
            
            return cellView as! UITableViewCell
        }
    }
}

extension SILAdvertiserDetailsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow deleting
        if range.length > 0 && string.isEmpty {
            return true
        }
        // Max digits
        if range.location == 6 {
            return false
        }
        let replaceString = onlyDigitalString(string)
        if (replaceString.count <= 6) {
            textField.text = "\(textField.text ?? "")\(replaceString)"
            textField.sendActions(for: .editingChanged)
        }
        return false
    }
    
    func onlyDigitalString(_ string: String) -> String {
        let hexChars = CharacterSet.decimalDigits
        return String(string.unicodeScalars.filter { hexChars.contains($0) })
    }
}

