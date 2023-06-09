//
//  SILBrowserMappingsSegmentedControl.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 02/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILBrowserMappingsSegmentedControl: UISegmentedControl {
    
    enum SegmentType: Int {
        case services = 0
        case characteristics = 1
    }
    
    var segmentType: SegmentType {
        return SegmentType(rawValue: self.selectedSegmentIndex)!
    }
}
