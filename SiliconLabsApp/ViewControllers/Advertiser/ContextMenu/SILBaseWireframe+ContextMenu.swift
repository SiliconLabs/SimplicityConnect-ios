//
//  SILBaseWireframe+ContextMenu.swift
//  BlueGecko
//
//  Created by Michał Lenart on 05/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

extension SILBaseWireframe {
    func presentContextMenu(sourceView: UIView, options: [ContextMenuOption]) {
        SILContextMenu.present(owner: viewController, sourceView: sourceView, options: options)
    }

    func open(url: String) {
        UIApplication.shared.open(URL(string: url)!)
    }
}
