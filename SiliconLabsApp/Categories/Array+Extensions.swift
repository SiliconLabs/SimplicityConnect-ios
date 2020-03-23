//
//  Array+Extensions.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

extension Array where Element == Int {
    
    var indexPaths: [IndexPath] {
        return self.count.indexPaths
    }
}
