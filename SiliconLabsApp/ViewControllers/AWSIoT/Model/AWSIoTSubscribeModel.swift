//
//  AWSIoTSubscribeModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 19/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation

// MARK: - AWSIoTSubscribeModel
//struct AWSIoTSubscribeModel: Codable {
//    let temperature, ambientLight, whiteLight: Double
//    let humidity: Int
//    let accelerometer, gyro: AccelerometerAWSIoT
//    //let led: LEDValue
//    
//    enum CodingKeys: String, CodingKey {
//        case temperature
//        case ambientLight = "ambient_light"
//        case whiteLight = "white_light"
//        case humidity, accelerometer, gyro
//    }
//}
//
//// MARK: - Accelerometer
//struct AccelerometerAWSIoT: Codable {
//    let x, y, z: Int
//}

// MARK: - LED
//struct LEDValue: Codable {
//    let red, green, blue: String
//}
// MARK: - SILAWSIoTHomeModel
struct AWSIoTSubscribeModel: Codable {
    let temperature, ambientLight, whiteLight, humidity: ValueTypeForSensorData
    let accelerometer, gyro: AccelerometerAWSIoT

    enum CodingKeys: String, CodingKey {
        case temperature
        case ambientLight = "ambient_light"
        case whiteLight = "white_light"
        case humidity, accelerometer, gyro
    }
}

// MARK: - Accelerometer
struct AccelerometerAWSIoT: Codable {
    let x, y, z: ValueTypeForSensorData
}



// Define an enum to represent multiple types
enum ValueTypeForSensorData: Codable {
    case intValue(Int)
    case doubleValue(Double)
    case stringValue(String)

    // Custom decoding logic
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .intValue(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .doubleValue(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .stringValue(stringValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid data type")
        }
    }

    // Custom encoding logic
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .intValue(let intValue):
            try container.encode(intValue)
        case .doubleValue(let doubleValue):
            try container.encode(doubleValue)
        case .stringValue(let stringValue):
            try container.encode(stringValue)
        }
    }
}

