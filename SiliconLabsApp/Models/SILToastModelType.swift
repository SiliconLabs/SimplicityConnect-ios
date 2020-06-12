//
//  SILToastModelType.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 01/06/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc
protocol SILToastModelType {
    var errorDescription: String { get }
    var peripheralName: String { get }
    var errorCode: Int { get }
    @objc func getErrorMessageForToast() -> String
}
