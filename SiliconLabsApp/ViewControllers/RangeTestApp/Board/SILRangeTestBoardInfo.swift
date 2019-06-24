//
//  SILRangeTestBoardInfo.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 12/02/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import UIKit

class SILRangeTestBoardInfo: NSObject {
    let deviceName: String?
    let modelNumber: String?
    let features: SILRangeTestBoardFeatures?
    
    init(deviceName: String?, modelNumber: String?) {
        self.deviceName = deviceName
        self.modelNumber = modelNumber
        self.features = SILRangeTestBoardFeatures.features(basedOnModelNumber: modelNumber)
    }
}
