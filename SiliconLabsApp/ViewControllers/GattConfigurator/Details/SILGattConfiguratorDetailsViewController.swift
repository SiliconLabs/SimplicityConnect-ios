//
//  SILGattConfiguratorDetailsViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 11/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit

class SILGattConfiguratorDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var allSpaceStackView: UIStackView!
    @IBOutlet weak var gattConfigurationName: SILTextField!
    @IBOutlet weak var tableView: UITableView!
    var viewModel: SILGattConfiguratorDetailsViewModel!
    var dataSource: [SILGattConfiguratorServiceCellViewModel] = []
    
    private var serviceDataToken: SILObservableToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupLogic()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.tabBarController?.showTabBarAndUpdateFrames()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    func setupNavigationBar() {
        self.navigationItem.title = viewModel.gattConfigurationName
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(backButtonTouch))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(onSaveTouch))
    }
    
    func setupLogic() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)

        gattConfigurationName.text = viewModel.gattConfigurationName
        gattConfigurationName.delegate = self
        
        weak var weakSelf = self

        
        serviceDataToken = viewModel.gattServicesData.observe { data in
            weakSelf?.dataSource = data
            weakSelf?.tableView.reloadData()
        }
    }
    
    @objc private func backButtonTouch(_ sender: UIButton) {
        viewModel.backToHome()
      }
    
    @objc private func onSaveTouch(_ sender: UIButton) {
        viewModel.save()
    }
    
    @IBAction func onAddServiceTouch(_ sender: UIButton) {
        viewModel.addService()
    }
    
    @IBAction func didChangeGattConfigurationName(_ sender: UITextField) {
        viewModel.update(gattConfigurationName: sender.text)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewModel.backToHome()
        return false
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].characteristicsAndDescriptorsCells.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var _cellViewModel: SILCellViewModel?
        if indexPath.row == 0 {
            _cellViewModel = dataSource[indexPath.section] as SILGattConfiguratorServiceCellViewModel
        } else {
            _cellViewModel = dataSource[indexPath.section].characteristicsAndDescriptorsCells[indexPath.row - 1] as SILCellViewModel
        }
        guard let cellViewModel = _cellViewModel else {
            return UITableViewCell()
        }
        let cellView = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as! SILCellView
        
        cellView.setViewModel(cellViewModel)
        let cell = cellView as! UITableViewCell
        cell.isExclusiveTouch = true
        cell.contentView.isExclusiveTouch = true
        setExclusiveTouchToChildrenOf(cell.subviews)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let cellViewModel = dataSource[indexPath.section]
            cellViewModel.changeExpand()
            UIView.performWithoutAnimation { [weak self] in
                self?.tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .none)
            }
        }
    }
    
    private func setExclusiveTouchToChildrenOf(_ subviews: [UIView]) {
        for v in subviews {
            self.setExclusiveTouchToChildrenOf(v.subviews)
            v.isExclusiveTouch = true
        }
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        DispatchQueue.main.async {
            cell.layer.zPosition = CGFloat(tableView.numberOfRows(inSection: indexPath.section) - indexPath.row)
            tableView.setNeedsLayout()
            tableView.layoutIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 20.0)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForFooterInSection: section, withHeight: 8.0)
    }
}
