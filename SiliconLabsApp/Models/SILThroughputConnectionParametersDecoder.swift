//
//  SILThroughputConnectionParametersDecoder.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 17.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

enum PHY: String {
    case _1M = "1M"
    case _2M = "2M"
    case _125k = "Coded 125k"
    case _500k = "Coded 500k"
    case _unknown = "N/A"
}

enum ConnectionParameter {
    case phy(phy: PHY)
    case connectionInterval(value: Double)
    case slaveLatency(value: Double)
    case supervisionTimeout(value: Double)
    case pdu(value: Int)
    case mtu(value: Int)
    case unknown
}

protocol SILThroughputConnectionParametersDecoderType {
    func decode(data: Data, characterisitc: CBUUID) -> ConnectionParameter
}

struct SILThroughputConnectionParametersDecoder {
    func decode(data: Data, characterisitc: CBUUID) -> ConnectionParameter {
        switch characterisitc {
        case SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PHYStatus.cbUUID:
            return .phy(phy: decodePHY(data: data))
            
        case SILThroughputPeripheralGATTDatabase.ThroughputInformationService.ConnectionInterval.cbUUID:
            return .connectionInterval(value: decodeConnectionInterval(data: data))
            
        case SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SlaveLatency.cbUUID:
            return .slaveLatency(value: decodeSlaveLatency(data: data))
            
        case SILThroughputPeripheralGATTDatabase.ThroughputInformationService.SupervisionTimeout.cbUUID:
            return .supervisionTimeout(value: decodeSupervisionTimeout(data: data))
            
        case SILThroughputPeripheralGATTDatabase.ThroughputInformationService.PDUSize.cbUUID:
            return .pdu(value: decodePDU(data: data))
            
        case SILThroughputPeripheralGATTDatabase.ThroughputInformationService.MTUSize.cbUUID:
            return .mtu(value: decodeMTU(data: data))
            
        default:
            return .unknown
        }
    }
    
    private func decodePHY(data: Data) -> PHY {
        let value = data.integerValueFromData()
        
        switch value {
        case 0x01:
            return ._1M
            
        case 0x02:
            return ._2M
            
        case 0x04:
            return ._125k
            
        case 0x08:
            return ._500k
            
        default:
            return ._unknown
        }
    }
    
    private func decodeConnectionInterval(data: Data) -> Double {
        let value = data.integerValueFromData()
        return Double(value) * 1.25
    }
    
    private func decodeSlaveLatency(data: Data) -> Double {
        let value = data.integerValueFromData()
        return Double(value) * 1.25
    }
    
    private func decodeSupervisionTimeout(data: Data) -> Double {
        let value = data.integerValueFromData()
        return Double(value) * 10.0
    }
    
    private func decodePDU(data: Data) -> Int {
        let value = data.integerValueFromData()
        
        if value > 255 {
            return -1
        }
        
        return value
    }
    
    private func decodeMTU(data: Data) -> Int {
        let value = data.integerValueFromData()
        
        if value > 255 {
            return -1
        }
        
        return value
    }
}
