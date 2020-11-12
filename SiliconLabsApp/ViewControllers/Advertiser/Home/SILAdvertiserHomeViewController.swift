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
    @IBOutlet weak var aboveSafeAreaView: UIView!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var navigationBarTitleLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noAdvertisersView: UIView!
    
    var viewModel: SILAdvertiserHomeViewModel!
    var dataSource: [SILAdvertiserCellViewModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        viewModel.viewDidLoad()
    }
    
    func setupNavigationBar() {
        navigationBarView.backgroundColor = UIColor.sil_siliconLabsRed()
        aboveSafeAreaView.backgroundColor = UIColor.sil_siliconLabsRed()
        
        navigationBarTitleLabel.font = UIFont.robotoMedium(size: CGFloat(SILNavigationBarTitleFontSize))
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
            return 80.0
        } else {
            return UITableView.automaticDimension
        }
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
        if (tableView.indexPathsForVisibleRows?[0] == indexPath) {
            tableView.bringSubviewToFront(cell)
        }
        if (indexPath.row == 0) {
            if (tableView.numberOfRows(inSection: indexPath.section) > 1) {
                cell.addShadowWhenAtTop()
                cell.roundCornersTop()
            } else {
                cell.addShadowWhenAtBottom()
                cell.roundCornersAll()
            }
        } else {
            if (tableView.numberOfRows(inSection: indexPath.section) - 1 == indexPath.row) {
                cell.addShadowWhenAtBottom()
                cell.roundCornersBottom()
            } else {
                cell.roundCornersNone()
                cell.addShadowWhenInMid()
            }
        }
        cell.clipsToBounds = false
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let size = CGRect(origin: tableView.bounds.origin, size: CGSize(width: tableView.bounds.size.width, height: 20))
        let view = UIView(frame: size)
        view.backgroundColor = .clear
        return view
    }
}
