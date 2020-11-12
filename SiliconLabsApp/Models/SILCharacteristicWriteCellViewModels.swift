//
//  SILCharacteristicWriteCellViewModels.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILCharacteristicWriteCellViewModel : class {
    var titleName: String { get }
    var indexInModel: Int { get }
    func clear()
}

protocol SILCharacteristicWriteCellViewModelType : SILCharacteristicWriteCellViewModel {
    associatedtype ValueType
    var currentValue: ValueType { get set }
    func updateValue(newValue: ValueType)
}

class SILCharacteristicWriteFieldCellViewModel : SILCharacteristicWriteCellViewModelType {
    typealias ValueType = String
    
    let titleName: String
    let indexInModel: Int
    var currentValue: String
    let format: String

    init(titleName: String,
         currentValue: String,
         indexInModel: Int,
         format: String = "") {
        self.titleName = titleName
        self.currentValue = currentValue
        self.indexInModel = indexInModel
        self.format = format
    }
    
    func updateValue(newValue: String) {
        self.currentValue = newValue
    }
    
    func clear() {
        self.currentValue = ""
    }
}

class SILCharacteristicWriteEnumListCellViewModel : SILCharacteristicWriteCellViewModelType {
    typealias ValueType = Int
    
    let titleName: String
    let indexInModel: Int
    var currentValue: Int
    var allPossibleValues: [SILBluetoothEnumerationModel]

    init(titleName: String,
         currentValue: Int,
         allPossibleValues: [SILBluetoothEnumerationModel],
         indexInModel: Int) {
        self.titleName = titleName
        self.currentValue = currentValue
        self.allPossibleValues = allPossibleValues
        self.indexInModel = indexInModel
    }
    
    func updateValue(newValue: Int) {
        self.currentValue = newValue
    }
    
    func clear() {
        self.currentValue = 0
    }
    
    func currentSelectedValueText() -> String {
        return allPossibleValues[currentValue].value
    }
}

class SILCharacteristicWriteEncodingFieldCellViewModel : SILCharacteristicWriteFieldCellViewModel {
    var encodingType: String
    var index: Int
    
    init(titleName: String,
         currentValue: String,
         encodingType: String,
         index: Int) {
        self.encodingType = encodingType
        self.index = index
        super.init(titleName: titleName,
                   currentValue: currentValue,
                   indexInModel: -1)
    }
}

class SILCharacteristicWriteBitFieldCellViewModel : SILCharacteristicWriteEnumListCellViewModel {
    var index: (inModel: Int,
                inBitModel: Int)
    
    init(currentValue: Int,
         allPossibleValues: [SILBluetoothEnumerationModel],
         index: (inModel: Int, inBitModel: Int)) {
        self.index = index
        super.init(titleName: "",
                   currentValue: currentValue,
                   allPossibleValues: allPossibleValues,
                   indexInModel: index.inModel)
    }
}
