//
//  UITableView+Extensions.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

extension UITableView {
    func tb_isLastCell(_ indexPath: IndexPath) -> Bool {
        guard let dataSource = self.dataSource else {
            return false
        }
        
        let count = dataSource.tableView(self, numberOfRowsInSection: indexPath.section)
        return indexPath.row == (count - 1)
    }
    
    func tb_isFirstCell(_ indexPath: IndexPath) -> Bool {
        return indexPath.row == 0
    }
}
