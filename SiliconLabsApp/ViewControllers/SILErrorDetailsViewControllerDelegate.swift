//
//  SILErrorDetailsViewControllerDelegate.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 08/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc protocol SILErrorDetailsViewControllerDelegate {
    func shouldCloseErrorDetailsViewController(_ errorDetailsViewController: SILErrorDetailsViewController)
}
