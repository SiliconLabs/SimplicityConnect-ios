//
//  SILSortViewModel.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 12/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

struct SortMode {
    var modeName: String
    var option: SILSortOption
}

struct SortSection {
    var type: String
    var modes: [SortMode]
    
    init(type: String, modes: [SortMode]) {
        self.type = type
        self.modes = modes
    }
}

@objc
@objcMembers
class SILSortViewModel: NSObject {
    var sections: [SortSection] = [
        SortSection(type: "RSSI", modes: [SortMode(modeName: "Ascending", option: .ascendingRSSI), SortMode(modeName: "Descending", option: .descendingRSSI)]),
        SortSection(type: "Name", modes: [SortMode(modeName: "A > Z", option: .AZ), SortMode(modeName: "Z > A", option: .ZA)])
    ]
    
    var selectedOption: SILSortOption = .none
    let typeCellHeight: CGFloat = 44.0
    let modeCellHeight: CGFloat = 37.0
    
    static let _sharedInstance = SILSortViewModel()
    
    private override init(){}
    
    @objc
    class func sharedInstance() -> SILSortViewModel {
        return SILSortViewModel._sharedInstance
    }
    
    func cellHeight(forIndexPath indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return typeCellHeight
        } else {
            return modeCellHeight
        }
    }
    
    @objc func deselectSelectedOption() {
        selectedOption = .none
    }
    
    func selectOption(forIndexPath indexPath: IndexPath) {
        if indexPath.row == 0 { return }
        let sortOption = sections[indexPath.section].modes[indexPath.row - 1].option
        if sortOption == selectedOption {
            selectedOption = .none
        } else {
            selectedOption = sortOption
        }
    }
    
    func isSelected(forIndexPath indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 { return false }
        return selectedOption == sections[indexPath.section].modes[indexPath.row - 1].option
    }
    
    @objc
    func getViewControllerHeight() -> CGFloat {
        var result: CGFloat = 0.0
        for section in sections {
            result += CGFloat(section.modes.count) * modeCellHeight
            result += typeCellHeight
        }
        let paddingBottom: CGFloat = 15.0
        return result + paddingBottom
    }
}
