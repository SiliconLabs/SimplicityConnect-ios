//
//  SILGattConfiguratorRemoveSetting.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 27/05/2021.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILGattConfiguratorSettingsType {
    var gattConfiguratorRemoveSetting: Bool { get set }
    var gattConfiguratorNonSaveChangesExitWarning: Bool { get set }
}

class SILGattConfiguratorSettings: SILGattConfiguratorSettingsType {
    private static let GattConfiguratorRemoveSettingKey = "SILGattConfiguratorRemoveSetting"
    private static let GattConfiguratorNonSaveChangesExitWarningKey = "GattConfiguratorNonSaveChangesExitWarningKey"
    
    private let userDefaults = UserDefaults.standard
    
    var gattConfiguratorRemoveSetting: Bool {
        get { !userDefaults.bool(forKey: Self.GattConfiguratorRemoveSettingKey) }
        set { userDefaults.set(newValue, forKey: Self.GattConfiguratorRemoveSettingKey) }
    }
    
    var gattConfiguratorNonSaveChangesExitWarning: Bool {
        get { userDefaults.bool(forKey: Self.GattConfiguratorNonSaveChangesExitWarningKey) }
        set { userDefaults.set(newValue, forKey: Self.GattConfiguratorNonSaveChangesExitWarningKey) }
    }
}
