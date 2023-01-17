//
//  SILIOPTestReport.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 15.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

struct SILIOPTestReportBuilder {
    func buildGeneralTag(tagName: String, innerString: String) -> String {
        return "<\(tagName)>\(innerString)\n</\(tagName)>"
    }
    
    func buildInnerTag(innerTagName: String, text: String) -> String {
        return "\n\t<\(innerTagName)>\(text)</\(innerTagName)>"
    }
}

struct SILIOPTestPhoneInfo {
    let tagName = "phone_informations"
    let phoneNameTag = "phone_name"
    let phoneOSVersionTag = "phone_os_version"
    
    let phoneName: String
    let phoneOSVersion: String
    
    func generateReport() -> String {
        let reportBuilder = SILIOPTestReportBuilder()
        var textReport = reportBuilder.buildInnerTag(innerTagName: phoneNameTag, text: phoneName)
        textReport.append(reportBuilder.buildInnerTag(innerTagName: phoneOSVersionTag, text: phoneOSVersion))
        
        return reportBuilder.buildGeneralTag(tagName: tagName, innerString: textReport)
    }
}

enum SILIOPFirmware: Equatable {
    case unknown
    case BRD4104A
    case BRD4181A
    case BRD4181B
    case BRD4182A
    case BRD4186B
    case readName(_ name: String)

    var rawValue: String {
        switch self {
        case .unknown:
            return "Unknown_ic_version"
        case .BRD4104A:
            return "BG13"
        case .BRD4181A, .BRD4181B:
            return "xG21"
        case .BRD4182A:
            return "xG22"
        case .BRD4186B:
            return "xG24"
        case .readName(let name):
            return name
        }
    }
}

struct SILIOPFirmwareVersion {
    let version: String
    
    func isLesserThan3_3_0() -> Bool {
        return version.versionCompare("3.3.0") == .orderedAscending
    }
}

struct SILIOPTestFirmwareInfo {
    let tagName = "firmware_informations"
    
    let originalVersionTag = "firmware_original_version"
    let otaAckVersionTag = "firmware_ota_ack_version"
    let otaNonAckVersionTag = "firmware_ota_non_ack_version"
    
    let nameTag = "firmware_name"
    let firmwareTag = "firmware_ic_name"
    
    var originalVersion: SILIOPFirmwareVersion
    var otaAckVersion: SILIOPFirmwareVersion?
    var otaNonAckVersion: SILIOPFirmwareVersion?
    
    let name: String
    let firmware: SILIOPFirmware
    
    func generateReport() -> String {
        let reportBuilder = SILIOPTestReportBuilder()
        var textReport = reportBuilder.buildInnerTag(innerTagName: originalVersionTag, text: originalVersion.version)
        textReport.append(reportBuilder.buildInnerTag(innerTagName: otaAckVersionTag, text: otaAckVersion?.version ?? "N/A"))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: otaNonAckVersionTag, text: otaNonAckVersion?.version  ?? "N/A"))

        textReport.append(reportBuilder.buildInnerTag(innerTagName: nameTag, text: name))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: firmwareTag, text: firmware.rawValue))
        
        return reportBuilder.buildGeneralTag(tagName: tagName, innerString: textReport)
    }
    
    static func generateReportWithUknownValues() -> String {
        let reportBuilder = SILIOPTestReportBuilder()
        var textReport = reportBuilder.buildInnerTag(innerTagName: "firmware_original_version", text: "N/A")
        textReport.append(reportBuilder.buildInnerTag(innerTagName: "firmware_ota_ack_version", text: "N/A"))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: "firmware_ota_non_ack_version", text: "N/A"))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: "firmware_name", text: "N/A"))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: "firmware_ic_name", text: "N/A"))
        
        return reportBuilder.buildGeneralTag(tagName: "firmware_informations", innerString: textReport)
    }
}

struct SILIOPTestConnectionParameters {
    let tagName = "connection_parameters"
    let mtu_sizeTag = "mtu_size"
    let pdu_sizeTag = "pdu_size"
    let intervalTag = "interval"
    let latencyTag = "latency"
    let supervision_timeoutTag = "supervision_timeout"

    let mtu_size: Int
    let pdu_size: Int
    let interval: Int
    let latency: Int
    let supervision_timeout: Int
    
    func generateReport() -> String {
        let reportBuilder = SILIOPTestReportBuilder()
        var textReport = reportBuilder.buildInnerTag(innerTagName: mtu_sizeTag, text: String(mtu_size))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: pdu_sizeTag, text: String(pdu_size)))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: intervalTag, text: String(interval)))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: latencyTag, text: String(latency)))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: supervision_timeoutTag, text: String(supervision_timeout)))
        
        return reportBuilder.buildGeneralTag(tagName: tagName, innerString: textReport)
    }
    
    static func generateReportWithUknownValues() -> String {
        let reportBuilder = SILIOPTestReportBuilder()
        var textReport = reportBuilder.buildInnerTag(innerTagName: "mtu_size", text: "N/A")
        textReport.append(reportBuilder.buildInnerTag(innerTagName: "pdu_size", text: "N/A"))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: "interval", text: "N/A"))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: "latency", text: "N/A"))
        textReport.append(reportBuilder.buildInnerTag(innerTagName: "supervision_timeout", text: "N/A"))
        
        return reportBuilder.buildGeneralTag(tagName: "connection_parameters", innerString: textReport)
    }
}

enum DateFormatString {
    case dayMonthYear
    case monthYear
    case dateWithTime
    case dayMonthYearWithSpace
    case fileNameDateTime
    case fullTime
    case fullTimeNoTimezone
    
    var formatString: String {
        switch self {
        case .dayMonthYear: return "dd/MM/yyyy"                                       // 12/12/2019
        case .monthYear: return "MM/yyyy"                                            // 12/2019
        case .dateWithTime: return "dd MMM YYYY h:mma"                              // 12 Dec 2019 7:26AM
        case .dayMonthYearWithSpace: return "dd MMM YYYY"                           // 12 Dec 2019
        case .fileNameDateTime: return "yyyy MM dd HH mm ss"                        // 2020 01 09 13 52 03
        case .fullTime: return "yyyy-MM-dd'T'HH:mm:ss.SSSZ"                        // 2019-12-12T07:26:30.000+0000
        case .fullTimeNoTimezone: return "yyyy-MM-dd'T'HH:mm:ss.SSS"              // 2019-12-12T07:26:30.000
            
        }
    }
}

struct SILTestCaseResults {
    var testCaseResults: [SILTestResult] = []

    mutating func update(newTestResult: SILTestResult) {
        if let index = testCaseResults.firstIndex(where: { testCaseResult in testCaseResult.testID == newTestResult.testID }) {
            testCaseResults[index].testStatus = newTestResult.testStatus
        }
    }
    
    func testInProgressCount() -> Int {
        var i = 0
        for testCaseResult in testCaseResults {
            switch testCaseResult.testStatus {
            case .passed(details: _),
                 .failed(reason: _),
                 .unknown(reason: _),
                 .inProgress:
                i = i + 1
            default:
                break
            }
        }
        
        return i
    }
    
    mutating func markTestAfterIndex(_ index: Int, with status: SILTestStatus) {
        let firstTestIDToFail = index + 1
        guard firstTestIDToFail < testCaseResults.count else { return }
        
        for i in firstTestIDToFail..<testCaseResults.count {
            testCaseResults[i].testStatus = status
        }
    }
}

struct SILIOPTestReport {
    let timestampTag = "timestamp"
    let testResultsTag = "test_results"
    
    let timestamp: Date
    let phoneInfo: SILIOPTestPhoneInfo
    let firmwareInfo: SILIOPTestFirmwareInfo?
    let connectionParameters: SILIOPTestConnectionParameters?
    let testCaseResults: SILTestCaseResults
    
    private func generateDate() -> String {
        let dateText = Date.longStyleDateFormatter().string(from: timestamp)
        return "<\(timestampTag)>\(dateText)</\(timestampTag)>"
    }
    
    private func generateTestCaseResult(for testID: String, result: SILTestStatus) -> String {
        var text = ""
        switch result {
        case let .passed(details: details):
            if let details = details, details != "" {
                text = "\n\tTest Case \(testID) \(result.rawValue),\(details)"
            } else {
                text = "\n\tTest Case \(testID) \(result.rawValue)."
            }
        case let .failed(reason: reason):
            if testID == "7.1", let reason = reason, reason.description.contains("(Throughput") {
                text = "\n\tTest Case \(testID) \(result.rawValue),\(reason.description)"
            } else {
                text = "\n\tTest Case \(testID) \(result.rawValue)."
            }
        
        case let .unknown(reason: reason):
            if testID == "7.1", let reason = reason, reason.description.contains("(Throughput") {
                text = "\n\tTest Case \(testID) \(result.rawValue),\(reason.description)"
            } else {
                text = "\n\tTest Case \(testID) \(result.rawValue)."
            }
        
        case .waiting:
            text = "\n\tTest Case \(testID) \(result.rawValue)."
            
        default:
            text = ""
        }
        
        return text
    }
    
    private func generateTestCaseResultsReport() -> String {
        var testResultText = ""
        let sortedTestCaseResults = testCaseResults.testCaseResults.sorted(by: { first, second -> Bool in first <= second })
        for testCaseResult in sortedTestCaseResults {
            testResultText.append(generateTestCaseResult(for: testCaseResult.testID, result: testCaseResult.testStatus))
        }
        
        let reportBuilder = SILIOPTestReportBuilder()
        return reportBuilder.buildGeneralTag(tagName: testResultsTag, innerString: testResultText)
    }
    
    func generateReport() -> String {
        let timestampText = generateDate()
        let phoneInfoText = phoneInfo.generateReport()
        var firmwareInfoText = ""
        if let firmwareInfo = firmwareInfo {
            firmwareInfoText = firmwareInfo.generateReport()
        } else {
            firmwareInfoText = SILIOPTestFirmwareInfo.generateReportWithUknownValues()
        }
        var connectionParametersText = ""
        if let connectionParameters = connectionParameters {
            connectionParametersText = connectionParameters.generateReport()
        } else {
            connectionParametersText = SILIOPTestConnectionParameters.generateReportWithUknownValues()
        }
        let testCaseResultsText = generateTestCaseResultsReport()
    
        var finalReport = timestampText
        finalReport.append("\n\(phoneInfoText)")
        finalReport.append("\n\(firmwareInfoText)")
        finalReport.append("\n\(connectionParametersText)")
        finalReport.append("\n\(testCaseResultsText)")
        
        return finalReport
    }
}
