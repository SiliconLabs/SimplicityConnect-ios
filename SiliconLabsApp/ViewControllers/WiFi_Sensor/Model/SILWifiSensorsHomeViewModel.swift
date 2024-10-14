//
//  SILWifiSensorsHomeViewModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 25/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation

// MARK: - SILWifiSensorsHomeViewModel
struct SILWifiSensorsHomeViewModel: Codable {
    let led: LED
    let light: Light
    let temperature: TemperatureData
    let accelerometer, gyroscope: Accelerometer
    let humidity: HumidityData
    let microphone: Microphone
    enum CodingKeys: String, CodingKey {
        case temperature = "temperature"
        case humidity = "humidity"
        case led, light, accelerometer, gyroscope, microphone
    }
}

// MARK: - Accelerometer
struct Accelerometer: Codable {
    let x, y, z: String
}

// MARK: - Humidity
struct HumidityData: Codable {
    let humidityPercentage: String

    enum CodingKeys: String, CodingKey {
        case humidityPercentage = "humidity_percentage"
    }
}

// MARK: - LED
struct LED: Codable {
    let red, green, blue: String
}

// MARK: - Light
struct Light: Codable {
    let ambientLightLux, whiteLightLux: String

    enum CodingKeys: String, CodingKey {
        case ambientLightLux = "ambient_light_lux"
        case whiteLightLux = "white_light_lux"
    }
}

// MARK: - Microphone
struct Microphone: Codable {
    let microphoneDecibel: String

    enum CodingKeys: String, CodingKey {
        case microphoneDecibel = "microphone_decibel"
    }
}

// MARK: - Temperature
struct TemperatureData: Codable {
    let temperatureCelcius: String

    enum CodingKeys: String, CodingKey {
        case temperatureCelcius = "temperature_celcius"
    }
}
