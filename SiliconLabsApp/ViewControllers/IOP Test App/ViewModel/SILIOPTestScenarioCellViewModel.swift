//
//  SILIOPTestScenarioCellViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 15.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTestScenarioCellViewModel: SILCellViewModel {
    var reusableIdentifier = "SILIOPTestScenarioCellView"
    var name: String
    var description: String
    private var previousStatus: SILTestStatus = .none
    
    var shouldUpdateView: Bool {
        if status == .waiting {
            return true
        }
        
        return previousStatus != status
    }
    
    var status: SILTestStatus {
        get {
            if testCaseStatuses.allSatisfy({ status in status == .waiting }) {
                return .waiting
            }
            
            if testCaseStatuses.contains(where: { status in status == .waiting || status == .inProgress }) {
                return .inProgress
            }

            if testCaseStatuses.allSatisfy({ status in
                if case .uknown(reason: _) = status {
                    return true
                }
                
                return false
            }) {
                return .uknown(reason: nil)
            }
            
            if testCaseStatuses.allSatisfy({ status in
                switch status {
                case .passed(details: _), .uknown(reason: _):
                    return true
                
                default:
                    return false
                }
            }) {
                return .passed(details: nil)
            }
            
            return .failed(reason: nil)
        }
    }
    
    private var testCaseStatuses: [SILTestStatus]

    init(name: String, description: String, testCaseStatuses: [SILTestStatus]) {
        self.name = name
        self.description = description
        self.testCaseStatuses = testCaseStatuses
    }
    
    func update(newTestCaseStatuses: [SILTestStatus]) {
        previousStatus = status
        _ = newTestCaseStatuses.enumerated().map { (index, newStatus) in testCaseStatuses[index] = newStatus }
    }
    
    func markTestCasesAsFail() {
        previousStatus = status
        testCaseStatuses = testCaseStatuses.map { _ in return .failed(reason: nil) }
    }
}
