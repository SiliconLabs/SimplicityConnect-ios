//
//  UIDevice+extensions.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 17/03/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import Foundation
import UIKit

public
extension UIDevice {
    public var hasNoth: Bool {
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                return false
            case 1334:
                return false
            case 1920, 2208:
                return false
            case 2436:
                return true
            case 2688:
                return true
            case 1792:
                return true
            default:
                return true
            }
        } else {
            return false
        }
    }
}
