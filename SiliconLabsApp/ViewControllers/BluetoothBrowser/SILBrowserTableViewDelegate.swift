//
//  SILBrowserTableViewDelegate.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 27/12/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
@objc class SILBrowserTableViewDelegate : NSObject, UITableViewDelegate, SILBrowserDeviceViewCellDelegate {
    
    private let headerHeight : CGFloat = 12
    
    var browserViewModel : BrowserViewModel
    private let uiScrollViewDelegate: SILUIScrollViewDelegate
    
    @objc init(browserViewModel: BrowserViewModel, uiScrollViewDelegate: SILUIScrollViewDelegate) {
        self.browserViewModel = browserViewModel
        self.uiScrollViewDelegate = uiScrollViewDelegate
    }
    
    //MARK: SILBrowserDeviceViewCellDelegate

    func favouriteButtonTappedInCell(_ cell: SILBrowserDeviceViewCell?) {
        cell?.viewModel?.toggleFavorite()
        cell?.configure()
    }
    
    func connectButtonTappedInCell(_ cell: SILBrowserDeviceViewCell?) {
        guard let cellVM = cell?.viewModel else { return }
        self.browserViewModel.connectOrDisconnect(cellVM)
        cell?.configure()
    }
    
    //MARK: UITableViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        uiScrollViewDelegate.scrollViewDidScroll(scrollView)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionViewModel = self.browserViewModel.peripheralViewModel(at: indexPath.section) else { return }
        
        sectionViewModel.isExpanded.toggle()
        
        let sectionsToReload = IndexSet(integer: indexPath.section)
        tableView.beginUpdates()
        tableView.fixCellBounds()
        tableView.reloadSections(sectionsToReload, with: .none)
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    //MARK: Headers and footers
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        headerHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: headerHeight)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        self.browserViewModel.discoveredPeripheralsViewModels.count - 1 == section ? LastFooterHeight : 0;
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.browserViewModel.discoveredPeripheralsViewModels.count - 1 == section {
            return SILTableViewWithShadowCells.tableView(tableView, viewForFooterInSection: section, withHeight: LastFooterHeight)
        }
        
        return nil
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        uiScrollViewDelegate.scrollViewWillBeginDragging(scrollView)
    }
}
