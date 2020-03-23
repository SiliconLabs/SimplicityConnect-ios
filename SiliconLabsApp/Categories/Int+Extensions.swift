//
//  Int+Extensions.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 8/4/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import Foundation

extension Int {
    var number: NSNumber {
        return NSNumber(value: self)
    }
    
    var indexPath: IndexPath {
        return IndexPath(row: self, section: 0)
    }
    
    var indexPaths: [IndexPath] {
        var indexPaths = [IndexPath]()
        for i in 0..<self {
            indexPaths.append(i.indexPath)
        }
        return indexPaths
    }
}
