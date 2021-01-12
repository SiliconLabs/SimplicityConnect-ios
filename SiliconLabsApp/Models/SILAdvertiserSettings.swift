//
//  SILAdvertiserSettings.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 28/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILAdvertiserSettings {
    private static let CompleteLocalNameSettingKey = "SILCompleteLocalNameSetting"
    private static let DisableRemoveServiceListWarningKey = "SILDisableRemoveServiceListWarningKey"
    private static let NonSaveChangesExitWarningKey = "SILNonSaveChangesExitWarningKey"

    private let userDefaults = UserDefaults.standard

    var completeLocalName: String {
        get { userDefaults.string(forKey: Self.CompleteLocalNameSettingKey) ?? UIDevice.current.name }
        set { userDefaults.set(newValue, forKey: Self.CompleteLocalNameSettingKey) }
    }

    var disableRemoveServiceListWarning: Bool {
        get { userDefaults.bool(forKey: Self.DisableRemoveServiceListWarningKey) }
        set { userDefaults.set(newValue, forKey: Self.DisableRemoveServiceListWarningKey) }
    }
    
    var nonSaveChangesExitWarning: Bool {
        get { userDefaults.bool(forKey: Self.NonSaveChangesExitWarningKey) }
        set { userDefaults.set(newValue, forKey: Self.NonSaveChangesExitWarningKey) }
    }
}
