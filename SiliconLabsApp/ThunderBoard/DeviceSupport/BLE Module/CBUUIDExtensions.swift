//
//  CBUUIDExtensions.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import CoreBluetooth

extension CBUUID {
    
    //MARK:- Service Identifiers
    
    /// Generic Access Service (org.bluetooth.service.generic_access)
    static let GenericAccess = CBUUID(string: "0x1800")
    
    /// Device Information (org.bluetooth.service.device_information)
    static let DeviceInformation = CBUUID(string: "0x180A")
    
    /// Battery Info Service (org.bluetooth.service.battery_service)
    static let BatteryService = CBUUID(string: "0x180F")
    
    /// Environmental Sensing (org.bluetooth.service.environmental_sensing)
    static let EnvironmentalSensing = CBUUID(string: "0x181A")
    
    /// Cycling Speed and Cadence (org.bluetooth.service.cycling_speed_and_cadence)
    static let CyclingSpeedAndCadence = CBUUID(string: "0x1816")
    
    /// Inertial Measurement (custom) (aka Acceleration and Orientation)
    static let InertialMeasurement = CBUUID(string: "0xa4e649f4-4be5-11e5-885d-feff819cdc9f")
    
    /// Automation IO (org.bluetooth.service.automation_io)
    static let AutomationIO = CBUUID(string: "0x1815")
    
    static let IndoorAirQualityCustom = CBUUID(string: "0xefd658ae-c400-ef33-76e7-91b00019103b")
    
    static let PowerSourceServiceCustom = CBUUID(string: "EC61A454-ED00-A5E8-B8F9-DE9EC026EC51")

    static let HallEffectCustom = CBUUID(string: "f598dbc5-2f00-4ec5-9936-b3d1aa4f957f")
    
    
    // ---------------------------------------------------------------------------------------
    // MARK:- Characteristic Identifiers
    // ---------------------------------------------------------------------------------------
    
    //
    // Generic Access Characteristics
    //

    /// Manufacturer Name (org.bluetooth.characteristic.gap.???)
    static let ManufacturerName = CBUUID(string: "0x2A29")
    
    /// Model Number (org.bluetooth.characteristic.gap.???)
    static let ModelNumber = CBUUID(string: "0x2A24")
    
    /// Hardware Revision (org.bluetooth.characteristic.gap.???)
    static let HardwareRevision = CBUUID(string: "0x2A27")
    
    /// Firmware Revision (org.bluetooth.characteristic.gap.???)
    static let FirmwareRevision = CBUUID(string: "0x2A26")
    
    static let SystemIdentifier = CBUUID(string: "0x2A23")
    
    //
    // Battery Characteristics
    //
    
    /// Battery Level Characteristic (org.bluetooth.characteristic.battery_level)
    static let BatteryLevel = CBUUID(string: "0x2A19")

    static let PowerSourceCharacteristicCustom = CBUUID(string: "EC61A454-ED01-A5E8-B8F9-DE9EC026EC51")

    //
    // Environmental Sensing Characteristics
    //
    
    /// Humidity (org.bluetooth.characteristic.humidity)
    static let Humidity = CBUUID(string: "0x2A6F")
    
    ///  Temperature (org.bluetooth.characteristic.temperature)
    static let Temperature = CBUUID(string: "0x2A6E")
    
    // UV Index (org.bluetooth.characteristic.uv_index)
    static let UVIndex = CBUUID(string: "0x2A76")
    
    static let Pressure = CBUUID(string: "0x2A6D")
    
    /// Ambient Light (custom)
    static let AmbientLight = CBUUID(string: "0xc8546913-bfd9-45eb-8dde-9f8754f4a32e")
    
    /// Sound Level (sense)
    static let SoundLevelCustom = CBUUID(string: "0xC8546913-BF02-45EB-8DDE-9F8754F4A32E")
    
    /// Environment Control Point (sense)
    static let SenseEnvironmentControlPointCustom = CBUUID(string: "0xC8546913-BF03-45EB-8DDE-9F8754F4A32E")

    //
    // Sense Indoor Air Quality Service
    //
    
    /// Air Quality: Carbon Dioxide (sense)
    static let SenseAirQualityCarbonDioxide = CBUUID(string: "0xefd658ae-c401-ef33-76e7-91b00019103b")
    
    /// Air Quality: Volatile Organic Compounds
    static let SenseAirQualityVolatileOrganicCompounds = CBUUID(string: "0xefd658ae-c402-ef33-76e7-91b00019103b")
    
    /// Air Quality Control Point
    static let SenseAirQualityControlPoint = CBUUID(string: "0xefd658ae-c403-ef33-76e7-91b00019103b")

    //
    // Sense Hall Effect Service
    //

    /// Hall Effect: State
    static let HallState = CBUUID(string: "f598dbc5-2f01-4ec5-9936-b3d1aa4f957f")

    /// Hall Effect: Field Strength
    static let HallFieldStrength = CBUUID(string: "f598dbc5-2f02-4ec5-9936-b3d1aa4f957f")

    /// Hall Effect: Control Point
    static let HallControlPoint = CBUUID(string: "f598dbc5-2f03-4ec5-9936-b3d1aa4f957f")

    //
    // Cycling Speed and Cadence Characteristics
    //
    
    /// CSC Control Point (org.bluetooth.characteristic.sc_control_point)
    static let CSCControlPoint = CBUUID(string: "0x2A55")
    
    /// CSC Measurement (org.bluetooth.characteristic.csc_measurement)
    static let CSCMeasurement = CBUUID(string: "0x2A5B")
    
    /// CSC Feature (org.bluetooth.characteristic.csc_feature)
    static let CSCFeature = CBUUID(string: "0x2A5C")
    
    //
    // Inertial Measurement Characteristics
    //
    
    /// Acceleration Measurement (custom)
    static let AccelerationMeasurement = CBUUID(string: "0xc4c1f6e2-4be5-11e5-885d-feff819cdc9f")
    
    /// Orientation Measurement (custom)
    static let OrientationMeasurement = CBUUID(string: "0xb7c4b694-bee3-45dd-ba9f-f3b5e994f49a")

    /// Command (custom)
    static let Command = CBUUID(string: "0x71e30b8c-4131-4703-b0a0-b0bbba75856b")
    
    //
    // Digital Characteristics
    //

    /// Digital (org.bluetooth.characteristic.digital)
    static let Digital = CBUUID(string: "0x2A56")
    
    /// Characteristic Presentation Format (org.bluetooth.descriptor.gatt.characteristic_presentation_format)
    static let CharacteristicPresentationFormat = CBUUID(string: "0x2904")
    
    /// Number of Digitals (org.bluetooth.descriptor.number_of_digitals)
    static let NumberOfDigitals = CBUUID(string: "0x2909")
    
    static let SenseRGBOutput = CBUUID(string: "FCB89C40-C603-59F3-7DC3-5ECE444A401B")
}
