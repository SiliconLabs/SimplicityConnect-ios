//
//  SILRangeTestSettingValue.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 04.06.2018.
//  Copyright © 2018 SiliconLabs. All rights reserved.
//

import UIKit

enum SILRangeTestSetting: Int {
    case txPower        = 0b00000001
    case payloadLength  = 0b00000010
    case maWindowSize   = 0b00000100
    case channelNumber  = 0b00001000
    case packetCount    = 0b00010000
    case remoteId       = 0b00100000
    case selfId         = 0b01000000
    case phyConfig      = 0b10000000
    case all            = 0b11111111
}

class SILRangeTestSettingValue {
    private let stringFormat: String
    let title: String
    private(set) var availableValues: [Double] = []
    private(set) var availableStringValues: [String] = []
    private(set) var defaultValue: Double = 0
    private(set) var selectedValue: Double = 0
    
    init(title: String, values: [Double], stringFormat: String = "%g") {
        self.stringFormat = stringFormat
        self.title = title
        
        self.availableValues = values
        self.availableStringValues = availableValues.map { String(format: self.stringFormat, $0) }
        self.defaultValue = values[0]
        self.selectedValue = values[0]
    }
    
    init(title: String, values: [Double], stringValues: [String]) {
        assert(values.count == stringValues.count)
        
        self.stringFormat = ""
        self.title = title
        
        self.availableValues = values
        self.availableStringValues = stringValues
        self.defaultValue = values[0]
        self.selectedValue = values[0]
    }
    
    func update(withSelectedValue selectedValue: Double) {
        self.selectedValue = selectedValue
    }
    
    func update(withSelectedValue selectedValue: Double, andAvailableValues availableValues: [Double]) {
        self.update(withSelectedValue: selectedValue,
                    andAvailableValues: availableValues,
                    andAvailableStringValues: availableValues.map { String(format: self.stringFormat, $0) })
    }
    
    func update(withSelectedValue selectedValue: Double, andAvailableValues availableValues: [Double], andAvailableStringValues availableStringValues: [String]) {
        assert(availableValues.count == availableStringValues.count)
        
        self.selectedValue = selectedValue
        self.defaultValue = availableValues[0]
        self.availableValues = availableValues
        self.availableStringValues = availableStringValues
    }
}
