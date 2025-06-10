//
//  SILStatusLED.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 29/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
// MARK: - SILStatusLED
struct SILStatusLED: Codable {
    let statusLED: String

    enum CodingKeys: String, CodingKey {
        case statusLED = "status_led"
    }
}
