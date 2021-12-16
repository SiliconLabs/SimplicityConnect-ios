//
//  SILWifiCommissioningConnectedAPCellViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 25/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILWifiCommissioningConnectedAPCellViewModel: SILWifiCommissioningAPCellViewModel {
    
    let macAddress: String
    let ipAddress: String
    
    required init(accessPoint: SILWifiCommissioningAccessPoint, selectAction: @escaping () -> ()) {
        self.macAddress = accessPoint.macAddress!
        self.ipAddress = accessPoint.ipAddres!
        super.init(accessPoint: accessPoint, selectAction: selectAction)
        self.reusableIdentifier = "SILWifiCommissioningConnectedAPCell"
    }
}
