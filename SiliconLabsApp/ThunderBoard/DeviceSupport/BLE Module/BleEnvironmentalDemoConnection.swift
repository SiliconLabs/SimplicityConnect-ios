//
//  BleEnvironmentDemoConnection.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation
import CoreBluetooth

class BleEnvironmentDemoConnection : EnvironmentDemoConnection {
    
    var device: Device
    fileprivate var bleDevice: BleDevice {
        get { return device as! BleDevice }
    }
    
    fileprivate var currentData: EnvironmentData = EnvironmentData()
    fileprivate var pollingTimer: WeakTimer?
    fileprivate var vocEnabled = false
    fileprivate var co2Enabled = false
    weak var connectionDelegate: EnvironmentDemoConnectionDelegate?

    init(device: BleDevice) {
        self.device = device
        self.bleDevice.demoConnectionCharacteristicValueUpdated = { [weak self] (characteristic: CBCharacteristic) in
            self?.characteristicUpdated(characteristic)
        }
        self.bleDevice.demoDeviceDisconnectedHook = { [weak self] in
            self?.connectionDelegate?.demoDeviceDisconnected()
        }
        
        pollingTimer = WeakTimer.scheduledTimer(3, repeats: true, action: { [weak self] () -> Void in
            self?.readCurrentValues()
        })

        self.readCurrentValues()
    }

    var deviceId: DeviceId {
        get {
            guard let id = device.deviceIdentifier else {
                return 0
            }
            
            return id
        }
        set { }
    }

    fileprivate func characteristicUpdated(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case CBUUID.Temperature:
            if let temperature = characteristic.tb_int16Value() {
                currentData.temperature = Double(temperature)/100
                notifyUpdatedData()
            }

        case CBUUID.Humidity:
            if let humidity = characteristic.tb_int16Value() {
                currentData.humidity = Double(humidity)/100
                notifyUpdatedData()
            }
        case CBUUID.UVIndex:
            if let uv = characteristic.tb_uint8Value() {
                currentData.uvIndex = Double(uv)
                notifyUpdatedData()
            }

        case CBUUID.AmbientLight:
            if let ambient = characteristic.tb_uint32Value() {
                currentData.ambientLight = Double(ambient / 100) // delivered with hundredths precision
                notifyUpdatedData()
            }
            
        case CBUUID.SenseAirQualityCarbonDioxide:
            if let co2 = characteristic.tb_uint16Value() {
                co2Enabled = true
                currentData.co2 = CarbonDioxideReading(enabled: co2Enabled, value: AirQualityCO2(co2))
                notifyUpdatedData()
            }
            
        case CBUUID.SenseAirQualityVolatileOrganicCompounds:
            if let voc = characteristic.tb_uint16Value() {
                vocEnabled = true
                currentData.voc = VolatileOrganicCompoundsReading(enabled: vocEnabled, value: AirQualityVOC(voc))
                notifyUpdatedData()
            }
            
        case CBUUID.SoundLevelCustom:
            if let db = characteristic.tb_int16Value() {
                currentData.sound = SoundLevel(db / 100)
                notifyUpdatedData()
            }
            
        case CBUUID.Pressure:
            if let pressure = characteristic.tb_uint32Value() {
                currentData.pressure = AtmosphericPressure(pressure / 1000)
                notifyUpdatedData()
            }

        case CBUUID.HallState:
            if let state = characteristic.tb_uint8Value() {
                currentData.hallEffectState = HallEffectState(rawValue: state)
                notifyUpdatedData()
            }

        case CBUUID.HallFieldStrength:
            if let fieldStrength = characteristic.tb_int32Value() {
                currentData.hallEffectFieldStrength = Double(fieldStrength)
                notifyUpdatedData()
            }
        default:
            break
        }
    }
    
    fileprivate func readCurrentValues() {

        capabilities.forEach({
            switch $0 {
            case .temperature:
                bleDevice.readValuesForCharacteristic(CBUUID.Temperature)
            case .humidity:
                bleDevice.readValuesForCharacteristic(CBUUID.Humidity)
            case .uvIndex:
                bleDevice.readValuesForCharacteristic(CBUUID.UVIndex)
            case .ambientLight:
                bleDevice.readValuesForCharacteristic(CBUUID.AmbientLight)
            case .airQualityCO2:
                bleDevice.readValuesForCharacteristic(CBUUID.SenseAirQualityCarbonDioxide)
            case .airQualityVOC:
                bleDevice.readValuesForCharacteristic(CBUUID.SenseAirQualityVolatileOrganicCompounds)
            case .soundLevel:
                bleDevice.readValuesForCharacteristic(CBUUID.SoundLevelCustom)
            case .airPressure:
                bleDevice.readValuesForCharacteristic(CBUUID.Pressure)
            case .hallEffectState:
                bleDevice.readValuesForCharacteristic(CBUUID.HallState)
            case .hallEffectFieldStrength:
                bleDevice.readValuesForCharacteristic(CBUUID.HallFieldStrength)
            default:
                break
            }
        })
    }
    
    fileprivate func notifyUpdatedData() {
        self.connectionDelegate?.updatedEnvironmentData(currentData)
    }

    func resetTamper() {
        let data = Data(bytes: [UInt8(0x01), UInt8(0x00)])
        bleDevice.writeValueForCharacteristic(.HallControlPoint, value: data)
    }
}
