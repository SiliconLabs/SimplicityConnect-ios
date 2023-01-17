//
//  SILIOPTestScenarioCellViewModel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 15.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTestScenarioCellViewModel: SILCellViewModel, ObservableObject {
    var reusableIdentifier = "SILIOPTestScenarioCellView"
    var name: String
    var description: String
    private var previousStatus: SILTestStatus = .none
    @Published private var testCaseStatuses: [SILTestStatus]

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
                if case .unknown(reason: _) = status {
                    return true
                }
                
                return false
            }) {
                return .unknown(reason: nil)
            }
            
            if testCaseStatuses.allSatisfy({ status in
                switch status {
                case .passed(details: _), .unknown(reason: _):
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
