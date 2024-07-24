//
//  SILWiFiLEDModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 27/06/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
enum LedImage {
    static let ledOnImage = UIImage(named: "lightOn")
    static let ledOffImage = UIImage(named: "lightOff")
    static let redLedOnImage = UIImage(named: "bulb_red")
    static let greenLedOnImage = UIImage(named: "bulb_green")
    static let blueLedOnImage = UIImage(named: "bulb_blue")
    static let magentaLedImage = UIImage(named: "bulb_magenta")
    static let cyanLedImage = UIImage(named: "bulb_cyan")
    static let yellowLedImage = UIImage(named: "bulb_yellow")
    static let checkBoxActiveImage = UIImage(named: "checkBoxActive")
    static let checkBoxInactiveImage = UIImage(named: "checkBoxInactive")
    static let blubOffTint = UIImage(named: "blub_off_tint")
}
enum LedType: String {
    case ledOn = "ledOn"
    case ledOff = "ledOff"
    case redOn = "redOn"
    case greenOn = "greenOn"
    case blueOn = "blueOn"
    case redOff = "redOff"
    case greenOff = "greenOff"
    case blueOff = "blueOff"
    case redGreenOn = "redGreenOn"
    case redBlueOn = "redBlueOn"
    case greenBuleOn = "greenBuleOn"
}
enum LedStatus: String {
    case ledOnState = "on"
    case ledOffState = "off"
}
enum LedColorType: String {
    case redType = "red"
    case greenType = "green"
    case blueType = "blue"
}
