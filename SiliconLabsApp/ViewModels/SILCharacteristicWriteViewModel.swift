//
//  SILCharacteristicWriteViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation
import CoreBluetooth

enum SILCharacteristicWriteError : Error {
    case parsingError(String)
}

class SILCharacteristicWriteViewModel {
    private let delegate: SILCharacteristicEditEnablerDelegate
    private let characteristicModel: SILCharacteristicTableModel
    private let assosiatedServiceModel: SILServiceTableModel
    private let support: (writeRequest: Bool, writeCommand: Bool)
    private var currentState: SILCharacteristicWriteRadioButtonState = .unknown
    private let asLocalIndicate: Bool?
    
    var assosiatedService: (name: String, hexUuidString: String) {
        get {
            return (name: assosiatedServiceModel.name(),
                    hexUuidString: assosiatedServiceModel.hexUuidString())
        }
    }
    
    var characteristic: (name: String, hexUuidString: String) {
        get {
            return (name: characteristicModel.name(),
                    hexUuidString: characteristicModel.hexUuidString())
        }
    }
    
    private var fieldsTableRowModels: [SILCharacteristicFieldRow] {
        get {
            return characteristicModel.fieldTableRowModels as! [SILCharacteristicFieldRow]
        }
    }
    
    private var cellViewModels = [SILCharacteristicWriteCellViewModel]()
        
    var numberOfCells: Int {
        get {
            return cellViewModels.count
        }
    }
    
    init(characteristic: CBCharacteristic, asLocalIndicate: Bool?,
         delegate: SILCharacteristicEditEnablerDelegate) {
        self.delegate = delegate
        self.characteristicModel = SILCharacteristicTableModel(characteristic: characteristic)
        self.assosiatedServiceModel = SILServiceTableModel(service: characteristic.service)
        self.support.writeRequest = characteristic.properties.contains(.write)
        self.support.writeCommand = characteristic.properties.contains(.writeWithoutResponse)
        self.asLocalIndicate = asLocalIndicate
        createCellViewModels()
    }
    
    func createCellViewModels() {
        if fieldsTableRowModels.isEmpty {
            cellViewModels.append(SILCharacteristicWriteEncodingFieldCellViewModel(titleName: "Hex",
                                                                                   currentValue: "",
                                                                                   encodingType: "Hex",
                                                                                   index: 0))
            cellViewModels.append(SILCharacteristicWriteEncodingFieldCellViewModel(titleName: "Ascii",
                                                                                   currentValue: "",
                                                                                   encodingType: "Ascii",
                                                                                   index: 1))
            cellViewModels.append(SILCharacteristicWriteEncodingFieldCellViewModel(titleName: "Decimal",
                                                                                   currentValue: "",
                                                                                   encodingType: "Decimal",
                                                                                   index: 2))
        } else {
            var fieldsRowModelIndex = 0
            for rowModel in fieldsTableRowModels {
                if let valueFieldRowModel = rowModel as? SILValueFieldRowModel {
                    cellViewModels.append(SILCharacteristicWriteFieldCellViewModel(titleName: valueFieldRowModel.fieldModel.name,
                                                                                   currentValue: valueFieldRowModel.primaryValue,
                                                                                   indexInModel: fieldsRowModelIndex,
                                                                                   isMandatoryField: rowModel.fieldModel.isMandatoryField(),
                                                                                   format: valueFieldRowModel.fieldModel.format))
                } else if let enumListRowModel = rowModel as? SILEnumerationFieldRowModel {
                    cellViewModels.append(SILCharacteristicWriteEnumListCellViewModel(titleName: enumListRowModel.fieldModel.name,
                                                                                      currentValue: enumListRowModel.activeValue,
                                                                                      allPossibleValues: enumListRowModel.enumertations as! [SILBluetoothEnumerationModel],
                                                                                      indexInModel: fieldsRowModelIndex))
                } else if let bitFieldRowModel = rowModel as? SILBitFieldFieldModel {
                    if let bitRowModels = bitFieldRowModel.bitRowModels() {
                        var bitRowModelIndex = 0
                        for bitRowModel in bitRowModels {
                            cellViewModels.append(SILCharacteristicWriteBitFieldCellViewModel(name: bitRowModel.bit.name,
                                                                                              currentValue: 0,
                                                                                              allPossibleValues: bitRowModel.bit.enumerations as! [SILBluetoothEnumerationModel],
                                                                                              index: (inModel: fieldsRowModelIndex, inBitModel: bitRowModelIndex)))
                            bitRowModelIndex = bitRowModelIndex + 1
                        }
                    }
                }
                fieldsRowModelIndex = fieldsRowModelIndex + 1
            }
        }
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> SILCharacteristicWriteCellViewModel {
        return cellViewModels[indexPath.row]
    }
    
    func updateRadioButton(writeRequestButtonSelected: Bool = false,
                           writeCommandButtonSelected: Bool = false,
                           completion: @escaping (SILCharacteristicWriteRadioButtonState) -> (Void)) {
        if !support.writeRequest {
            self.currentState = .supportOnlyWriteCommand
            completion(.supportOnlyWriteCommand)
            return
        }
        
        if !support.writeCommand {
            self.currentState = .supportOnlyWriteRequest
            completion(.supportOnlyWriteRequest)
            return
        }
        
        if writeRequestButtonSelected {
            self.currentState = .writeRequestSelected
            completion(.writeRequestSelected)
            return
        }
        
        if writeCommandButtonSelected {
            self.currentState = .writeCommandSelected
            completion(.writeCommandSelected)
            return
        }
        
        self.currentState = .writeRequestSelected
        completion(.writeRequestSelected)
    }
    
    func clear(completion: @escaping () -> ()) {
        for cellViewModel in cellViewModels {
            cellViewModel.clear()
        }
        completion()
    }
    
    func send(completion: @escaping (SILCharacteristicWriteError?) -> ()) {
        let backupValues = prepareBackup()
        
        do {
            try updateFieldRowModels()
            if let asLocalIndicate = asLocalIndicate {
                try delegate.write(toLocalCharacteristic: characteristicModel, asLocalIndicate: asLocalIndicate)
                completion(.none)
            } else if let writeType = chooseWriteType() {
                try delegate.saveCharacteristic(characteristicModel, with: writeType)
                completion(.none)
            }
        } catch let error as SILCharacteristicWriteError {
            restoreValues(from: backupValues)
            completion(error)
        } catch {
            restoreValues(from: backupValues)
            completion(.parsingError(error.localizedDescription))
        }
    }
    
    private func chooseWriteType() -> CBCharacteristicWriteType? {
        switch currentState {
        case .supportOnlyWriteCommand,
             .writeCommandSelected:
            return .withoutResponse
        case .supportOnlyWriteRequest,
             .writeRequestSelected:
            return .withResponse
        default:
            return nil
        }
    }
    
    private func prepareBackup() -> [String] {
        return self.fieldsTableRowModels.map { model -> String in
            switch model {
                case let model as SILValueFieldRowModel:
                    return model.primaryValue
                case let model as SILEnumerationFieldRowModel:
                    return String(model.activeValue)
                case let model as SILBitFieldFieldModel:
                    var result = ""
                    if let bitModels = model.bitRowModels() {
                        for bitModel in bitModels {
                            result += "\(String(describing: bitModel.toggleState ?? 0))\n"
                        }
                    }
                    return result
                default:
                    print("Unrecognized model")
                    return ""
            }
        }
    }
    
    private func restoreValues(from backupValues: [String]) {
        for (model, value) in zip(self.fieldsTableRowModels, backupValues) {
            switch model {
            case let model as SILValueFieldRowModel:
                model.primaryValue = value
            case let model as SILEnumerationFieldRowModel:
                model.activeValue = Int(value) ?? 0
            case let model as SILBitFieldFieldModel:
                let splitValues = value.split(separator: "\n")
                if let bitModels = model.bitRowModels() {
                    for (bitModel, splitValue) in zip(bitModels, splitValues) {
                        let stringValue = String(splitValue)
                        bitModel.toggleState = NSNumber(integerLiteral: Int(stringValue) ?? 0)
                    }
                }
            default:
                print("Unrecognized model")
            }
        }
    }
    
    private func updateFieldRowModels() throws {
        if fieldsTableRowModels.isEmpty {
            if let hexViewModel = cellViewModels[0] as? SILCharacteristicWriteEncodingFieldCellViewModel,
                let resolver = SILCharacteristicFieldValueResolver.shared() {
                if hexViewModel.currentValue.isEmpty {
                    throw SILCharacteristicWriteError.parsingError(CannotWriteEmptyTextToCharacteristic)
                }
                do {
                    let encodingData = try resolver.data(forHexString: hexViewModel.currentValue, decimalExponent: 0)
                    characteristicModel.setIfAllowedFullWriteValue(encodingData)
                } catch {
                    throw SILCharacteristicWriteError.parsingError(error.localizedDescription)
                }
            }
        } else {
            for i in 0..<numberOfCells {
                if let bitFieldViewModel = cellViewModels[i] as? SILCharacteristicWriteBitFieldCellViewModel {
                    let indexInFieldModels = bitFieldViewModel.index.inModel
                    if let bitFieldRowModel = self.fieldsTableRowModels[indexInFieldModels] as? SILBitFieldFieldModel,
                        let bitModels = bitFieldRowModel.bitRowModels() {
                        bitModels[bitFieldViewModel.index.inBitModel].toggleState = bitFieldViewModel.currentValue as NSNumber
                    }
                } else if let fieldCellViewModel = cellViewModels[i] as? SILCharacteristicWriteFieldCellViewModel {
                    let indexInModel = fieldCellViewModel.indexInModel
                    if let fieldRowModel = self.fieldsTableRowModels[indexInModel] as? SILValueFieldRowModel {
                        if !fieldRowModel.fieldModel.isMandatoryField() && fieldCellViewModel.currentValue.isEmpty{
                            fieldRowModel.primaryValue = nil
                        }else if fieldRowModel.fieldModel.isMandatoryField() && fieldCellViewModel.currentValue.isEmpty{
                            throw SILCharacteristicWriteError.parsingError(FillAllMandatoryFields)
                        }else {
                            fieldRowModel.primaryValue = fieldCellViewModel.currentValue
                        }
                    }
                } else if let enumListCellViewModel = cellViewModels[i] as? SILCharacteristicWriteEnumListCellViewModel {
                    let indexInModel = enumListCellViewModel.indexInModel
                    if let enumListRowModel = self.fieldsTableRowModels[indexInModel] as? SILEnumerationFieldRowModel {
                        enumListRowModel.activeValue = enumListCellViewModel.currentValue
                    }
                }
            }
        }
    }
    
    func updateEncodings(with text: String, at index: Int, completion: @escaping (SILCharacteristicWriteError?) -> (Void)) {
        if let resolver = SILCharacteristicFieldValueResolver.shared(),
            let hexViewModel = cellViewModels[0] as? SILCharacteristicWriteEncodingFieldCellViewModel,
            let asciiViewModel = cellViewModels[1] as? SILCharacteristicWriteEncodingFieldCellViewModel,
            let decimalViewModel = cellViewModels[2] as? SILCharacteristicWriteEncodingFieldCellViewModel {
            if text == "" {
                hexViewModel.currentValue = ""
                asciiViewModel.currentValue = ""
                decimalViewModel.currentValue = ""
                completion(.none)
                return
            }
            if index == 0 && resolver.isLegalHexString(text, length: UInt(text.count)) {
                hexViewModel.currentValue = text
                do {
                    let encodingData = try resolver.data(forHexString: text, decimalExponent: 0)
                    asciiViewModel.currentValue = resolver.asciiString(for: encodingData)
                    decimalViewModel.currentValue = resolver.decimalString(for: encodingData)
                    completion(.none)
                } catch {
                    completion(.parsingError("Incorrect data format"))
                }
            } else if index == 2 && resolver.isLegalDecimalString(text) {
                decimalViewModel.currentValue = text
                let encodingData = resolver.data(forDecimalString: text)
                hexViewModel.currentValue = resolver.hexString(for: encodingData, decimalExponent: 0)
                asciiViewModel.currentValue = resolver.asciiString(for: encodingData)
                completion(.none)
            } else if !(index == 1) {
                completion(.parsingError("Incorrect data format"))
            } else {
                asciiViewModel.currentValue = text
                let encodingData = resolver.data(forAsciiString: text)
                hexViewModel.currentValue = resolver.hexString(for: encodingData, decimalExponent: 0)
                decimalViewModel.currentValue = resolver.decimalString(for: encodingData)
                completion(.none)
            }
        }
    }
}
