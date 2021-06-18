//
//  SILTableViewControllerHelper.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 23/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

@objc
@objcMembers
class SILTableViewWithShadowCells: NSObject {
    
    class func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layoutIfNeeded()
        if let first = tableView.indexPathsForVisibleRows?.first, first == indexPath {
            tableView.bringSubviewToFront(cell)
        }
        if (indexPath.row == 0) {
            if (tableView.numberOfRows(inSection: indexPath.section) > 1) {
                cell.addShadowWhenAtTop()
                cell.roundCornersTop()
            } else {
                cell.addShadowWhenAlone()
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
    
    class func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int, withHeight height: CGFloat) -> UIView? {
        let size = CGRect(origin: tableView.bounds.origin, size: CGSize(width: tableView.bounds.size.width, height: height))
        let view = UIView(frame: size)
        view.backgroundColor = .clear
        return view
    }
    
    class func tableView(_ tableView: UITableView, viewForFooterInSection section: Int, withHeight height: CGFloat) -> UIView? {
        let size = CGRect(origin: tableView.bounds.origin, size: CGSize(width: tableView.bounds.size.width, height: height))
        let view = UIView(frame: size)
        view.backgroundColor = .clear
        return view
    }
}
