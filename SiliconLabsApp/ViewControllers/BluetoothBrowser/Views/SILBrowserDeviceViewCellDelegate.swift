//
//  SILBrowserDeviceViewCellDelegate.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc protocol SILBrowserDeviceViewCellDelegate: class {
    func favouriteButtonTappedInCell(_ cell: SILBrowserDeviceViewCell?)
    func connectButtonTappedInCell(_ cell: SILBrowserDeviceViewCell?)
}
