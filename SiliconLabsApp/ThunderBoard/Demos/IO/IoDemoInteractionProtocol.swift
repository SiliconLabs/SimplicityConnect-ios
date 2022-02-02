//
//  IoDemoInteractionProtocol.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import Foundation

protocol IoDemoInteractionOutput : class {
    func showButtonState(_ button: Int, pressed: Bool)
    func showLedState(_ led: Int, state: LedState)
    func disableRgb()
    func disableLeds()
    func enable(_ enable: Bool, led ledNo: Int)
    func enable(_ enable: Bool, switch switchNo: Int)
}
