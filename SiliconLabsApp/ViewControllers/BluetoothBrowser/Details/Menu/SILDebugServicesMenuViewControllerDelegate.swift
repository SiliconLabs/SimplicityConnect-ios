//
//  SILDebugServicesMenuViewControllerDelegate.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 19/05/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc
protocol SILDebugServicesMenuViewControllerDelegate {
    @objc
    func performActionForMenuOption(using completion: () -> ())
}
