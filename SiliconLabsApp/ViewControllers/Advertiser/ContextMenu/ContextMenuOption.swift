//
//  SILContextMenuOption.swift
//  BlueGecko
//
//  Created by Michał Lenart on 05/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

struct ContextMenuOption {
    let enabled: Bool
    let title: String
    let callback: () -> Void
    
    init(title: String, callback: @escaping () -> Void) {
        self.init(enabled: true, title: title, callback: callback)
    }
    
    init(enabled: Bool, title: String, callback: @escaping () -> Void) {
        self.enabled = enabled
        self.title = title
        self.callback = callback
    }
}
