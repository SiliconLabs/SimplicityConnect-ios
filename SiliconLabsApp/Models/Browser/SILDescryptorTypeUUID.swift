//
//  SILDescryptorTypeUUID.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 07/12/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

enum SILDesciptorTypeUUID {
    case environmentalSensingConfiguration
    case environmentalSensingMeasurement
    case environmentalSensingTriggerSetting
    case externalReportReference
    case characteristicAggregateFormat
    case characteristicExtendedProperties
    case characteristicPresentationFormat
    case characteristicUserDescription
    case clientCharacteristicConfiguration
    case serverCharacteristicConfiguration
    case numberOfDigitals
    case reportReference
    case timeTriggerSetting
    case validRange
    case valueTriggerSetting
}

extension SILDesciptorTypeUUID: RawRepresentable {
    typealias RawValue = CBUUID
    
    init?(rawValue: RawValue) {
        switch rawValue {
        case CBUUID(string: "0x290B"): self = .environmentalSensingConfiguration
        case CBUUID(string: "0x290C"): self = .environmentalSensingMeasurement
        case CBUUID(string: "0x290D"): self = .environmentalSensingTriggerSetting
        case CBUUID(string: "0x2907"): self = .externalReportReference
        case CBUUID(string: "0x2905"): self = .characteristicAggregateFormat
        case CBUUID(string: "0x2900"): self = .characteristicExtendedProperties
        case CBUUID(string: "0x2904"): self = .characteristicPresentationFormat
        case CBUUID(string: "0x2901"): self = .characteristicUserDescription
        case CBUUID(string: "0x2902"): self = .clientCharacteristicConfiguration
        case CBUUID(string: "0x2903"): self = .serverCharacteristicConfiguration
        case CBUUID(string: "0x2909"): self = .numberOfDigitals
        case CBUUID(string: "0x2908"): self = .reportReference
        case CBUUID(string: "0x290E"): self = .timeTriggerSetting
        case CBUUID(string: "0x2906"): self = .validRange
        case CBUUID(string: "0x290A"): self = .valueTriggerSetting
        default:
            return nil
        }
    }
    
    var rawValue: RawValue {
        switch self {
        case .environmentalSensingConfiguration: return CBUUID(string: "0x290B")
        case .environmentalSensingMeasurement: return CBUUID(string: "0x290C")
        case .environmentalSensingTriggerSetting: return CBUUID(string: "0x290D")
        case .externalReportReference: return CBUUID(string: "0x2907")
        case .characteristicAggregateFormat: return CBUUID(string: "0x2905")
        case .characteristicExtendedProperties: return CBUUID(string: "0x2900")
        case .characteristicPresentationFormat: return CBUUID(string: "0x2904")
        case .characteristicUserDescription: return CBUUID(string: "0x2901")
        case .clientCharacteristicConfiguration: return CBUUID(string: "0x2902")
        case .serverCharacteristicConfiguration: return CBUUID(string: "0x2903")
        case .numberOfDigitals: return CBUUID(string: "0x2909")
        case .reportReference: return CBUUID(string: "0x2908")
        case .timeTriggerSetting: return CBUUID(string: "0x290E")
        case .validRange: return CBUUID(string: "0x2906")
        case .valueTriggerSetting: return CBUUID(string: "0x290A")
        }
    }
}
