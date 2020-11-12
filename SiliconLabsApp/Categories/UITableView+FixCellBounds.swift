//
//  UITableView+FixCellBounds.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 07/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

extension UITableView {
    @objc func fixCellBounds() {
        DispatchQueue.main.async { [weak self] in
            for cell in self?.visibleCells ?? [] {
                cell.layer.masksToBounds = false
                cell.contentView.layer.masksToBounds = false
            }
        }
    }
}
