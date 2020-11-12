//
//  SILAdvertiserRemoveSetting.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 13/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertiserRemoveSetting {
    private static let AdvertiserRemoveSettingKey = "SILAdvertiserRemoveSetting"
    
    static func shouldDisplayAdvertiserRemoveWarning() -> Bool {
        return !UserDefaults.standard.bool(forKey: AdvertiserRemoveSettingKey)
    }
    
    static func setDisplayAdvertiserRemoveWarning(value: Bool) {
        UserDefaults.standard.set(value, forKey: AdvertiserRemoveSettingKey)
    }
}
