//
//  EnvironmentDemoViewModel.swift
//  Thunderboard
//
//  Created by Jamal Sedayao on 9/26/17.
//  Copyright © 2017 Silicon Labs. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class EnvironmentDemoViewModel {
    let capability: DeviceCapability
    let name: BehaviorRelay<String> = BehaviorRelay(value: "")
    let value: BehaviorRelay<String> = BehaviorRelay(value: "")
    let imageName: BehaviorRelay<String> = BehaviorRelay(value: "")
    let imageBackgroundColor: BehaviorRelay<UIColor?> = BehaviorRelay(value: nil)
    
    init(capability: DeviceCapability) {
        self.capability = capability
    }
    
    func updateData(cellData: EnvironmentCellData, reload: Bool = true) {
        self.name.accept(cellData.name)
        self.value.accept(cellData.value)
        if reload {
            self.imageName.accept(cellData.imageName)
        }
        self.imageBackgroundColor.accept(cellData.imageBackgroundColor)
    }
}
