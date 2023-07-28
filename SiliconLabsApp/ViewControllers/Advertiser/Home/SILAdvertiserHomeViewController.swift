//
//  SILAdvertiserViewController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 22/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAdvertiserHomeViewController: UIViewController, SILAdvertiserHomeViewDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var allSpace: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noAdvertisersView: UIView!
    @IBOutlet weak var controllerHeight: NSLayoutConstraint!
    
    var viewModel: SILAdvertiserHomeViewModel!
    var dataSource: [SILAdvertiserCellViewModel] = []
    private weak var floatingButtonSettings: FloatingButtonSettings?
    
    private lazy var uiScrollViewDelegate = SILUIScrollViewDelegate(onHideUIElements: { [weak self] in
        guard let self = self else { return }
        self.floatingButtonSettings?.setPresented(false)
        self.viewModel.isActiveScrollingUp = true
    }, onShowUIElements: { [weak self] in
        guard let self = self else { return }
        self.floatingButtonSettings?.setPresented(true)
        self.viewModel.isActiveScrollingUp = false
    })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        viewModel.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.floatingButtonSettings?.setPresented(true)
        self.floatingButtonSettings?.controllerHeight = self.controllerHeight
        self.viewModel.isActiveScrollingUp = false
    }
    
    fileprivate func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    func setupFloatingButton(_ settings: FloatingButtonSettings) {
        floatingButtonSettings = settings
        floatingButtonSettings?.setButtonText("Create New")
        floatingButtonSettings?.setPresented(!viewModel.isActiveScrollingUp)
    }
    
    // MARK: SILAdvertiserHomeViewDelegate
    
    func updateAdvertisers(advertisers: [SILAdvertiserCellViewModel]) {
        dataSource = advertisers
        tableView.reloadData()
        noAdvertisersView.isHidden = dataSource.count > 0
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].advertiserAdTypes.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 120.0
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.numberOfSections(in: tableView) - 1 == section ?
        SILTableViewWithShadowCells.tableView(tableView, viewForFooterInSection: section, withHeight: LastFooterHeight) : nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.numberOfSections(in: tableView) - 1 == section ? LastFooterHeight : 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var _cellViewModel: SILCellViewModel?
        
        if indexPath.row == 0 {
            _cellViewModel = dataSource[indexPath.section] as SILCellViewModel
        } else {
            _cellViewModel = dataSource[indexPath.section].advertiserAdTypes[indexPath.row - 1] as SILCellViewModel
        }
        
        guard let cellViewModel = _cellViewModel else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as! SILAdvertiserHomeCellView
        cell.setViewModel(cellViewModel)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let cellViewModel = dataSource[indexPath.section]
            UIView.performWithoutAnimation {
                cellViewModel.updateSection { [weak self] in self?.tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .none) }
            }
        }
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 8.0)
    }
    
}

extension SILAdvertiserHomeViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        uiScrollViewDelegate.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        uiScrollViewDelegate.scrollViewDidScroll(scrollView)
    }
}
