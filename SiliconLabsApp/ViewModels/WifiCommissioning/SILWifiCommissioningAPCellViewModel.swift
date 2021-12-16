//
//  SILWifiCommissioningAPCellViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 19/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILWifiCommissioningAPCellViewModel: SILCellViewModel {
    var reusableIdentifier: String = "SILWifiCommissioningAPCell"
    
    let name: String
    let securityType: String
    let dotColor: UIColor
    let selectAction: () -> ()
    
    required init(accessPoint: SILWifiCommissioningAccessPoint, selectAction: @escaping () -> ()) {
        self.name = accessPoint.name
        self.securityType = accessPoint.securityType.name
        self.dotColor = accessPoint.connected ? UIColor.systemGreen : UIColor.sil_siliconLabsRed()
        self.selectAction = selectAction
    }
    
    func select() {
        selectAction()
    }
}
