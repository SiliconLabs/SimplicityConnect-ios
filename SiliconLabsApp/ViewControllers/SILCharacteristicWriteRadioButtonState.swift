//
//  SILCharacteristicWriteRadioButton.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 28/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

enum SILCharacteristicWriteRadioButtonState {
    case unknown
    case supportOnlyWriteCommand
    case supportOnlyWriteRequest
    case writeRequestSelected
    case writeCommandSelected
}
