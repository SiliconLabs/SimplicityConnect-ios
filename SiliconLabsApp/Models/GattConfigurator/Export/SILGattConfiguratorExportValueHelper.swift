//
//  SILGattConfiguratorExportHelper.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 21/06/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

class SILGattConfiguratorExportValueHelper {
    private let xmlNodeInfo: SILGattXmlNodeInfo
    private let initialValueType: SILGattConfigurationValueType
    private let initialValue: String?
    private let fixedVariableLength: Bool
    private var length: String
    
    init(node: SILGattXmlNodeInfo, initialValueType: SILGattConfigurationValueType, initialValue: String?, fixedVariableLength: Bool, length: String) {
        self.xmlNodeInfo = node
        self.initialValueType = initialValueType
        self.initialValue = initialValue
        self.fixedVariableLength = fixedVariableLength
        self.length = length
    }
    
    private func countInitialValueLength() -> Int {
        if let initialValue = initialValue {
            if initialValueType == .text {
                return initialValue.utf8.count
            } else {
                return initialValue.count / 2
            }
        }
        return 0
    }
    
    private func getVariableLengthValue() -> String {
        return fixedVariableLength == true ? "false" : "true"
    }
    
    func export() -> AEXMLElement? {
        if initialValueType == .none {
            return nil
        }
        if let initialValue = initialValue, countInitialValueLength() <= SILGattConfiguratorXmlDatabase.GattConfigurationValue.maxValueLength,
           let initialValueTag = initialValueType.xmlTag  {
            
            let variableLengthAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.variableLengthAttribute
            let lengthAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.lengthAttribute
            let typeAttribute = SILGattConfiguratorXmlDatabase.GattConfigurationValue.typeAttribute
            
            var lengthInt: Int? = Int(length)
            
            if lengthInt != nil {
                if countInitialValueLength() >= lengthInt! {
                    lengthInt = countInitialValueLength()
                }
            } else {
                lengthInt = countInitialValueLength()
            }
            
            return AEXMLElement(name: SILGattConfiguratorXmlDatabase.GattConfigurationValue.name, value: initialValue, attributes: [
                variableLengthAttribute.name: getVariableLengthValue(),
                lengthAttribute.name: "\(String(describing: lengthInt!))",
                typeAttribute.name: initialValueTag
            ])
        }
        return nil
    }
}
