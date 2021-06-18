//
//  SILGattConfiguratorHomeViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 01/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit
import CoreBluetooth

class SILGattConfiguratorHomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SILGattConfiguratorHomeViewDelegate {

    @IBOutlet weak var allSpace: UIStackView!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var aboveSafeAreaView: UIView!
    @IBOutlet weak var navigationBarTitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noConfigurationsView: UIStackView!
    
    var viewModel: SILGattConfiguratorHomeViewModel!
    var dataSource: [SILGattConfiguratorCellViewModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
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

    @IBAction func onBackTouch(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onMenuTouch(_ sender: UIButton) {
        viewModel.openMenu(sourceView: sender)
    }
    
    // MARK: SILGattConfiguratorHomeViewDelegate
    
    func updateConfigurations(configurations: [SILGattConfiguratorCellViewModel]) {
        dataSource = configurations
        tableView.reloadData()
        noConfigurationsView.isHidden = dataSource.count > 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].serviceCells.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var _cellViewModel: SILCellViewModel?
        if indexPath.row == 0 {
            _cellViewModel = dataSource[indexPath.section] as SILCellViewModel
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
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        DispatchQueue.main.async {
            cell.layer.zPosition = CGFloat(tableView.numberOfRows(inSection: indexPath.section) - indexPath.row)
            tableView.setNeedsLayout()
            tableView.layoutIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 20.0)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForFooterInSection: section, withHeight: 8.0)
    }
}
