//
//  SILBrowserMappingsSegmentedControl.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 02/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILBrowserMappingsSegmentedControl: SILSegmentedControl {
    
    enum SegmentType: Int {
        case characteristics = 0
        case services = 1
    }
    
    var segmentType: SegmentType {
        return SegmentType(rawValue: self.selectedSegmentIndex)!
    }
}
