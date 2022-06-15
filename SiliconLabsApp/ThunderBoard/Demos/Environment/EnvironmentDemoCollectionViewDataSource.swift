//
//  EnvironmentDemoCollectionViewDataSource.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct EnvironmentCellData {
    let name: String
    let value: String
    let imageName: String
    let imageBackgroundColor: UIColor?
    
    enum Power {
        case na
        case off
        case on
    }
    let power: Power
}

class EnvironmentDemoCollectionViewDataSource : NSObject {
    
    fileprivate typealias DataMapperFunction = ((EnvironmentData) -> EnvironmentCellData)
    fileprivate let capabilities = BehaviorRelay(value: Set<DeviceCapability>())
    fileprivate let allViewModels = BehaviorRelay<[EnvironmentDemoViewModel]>(value: [])
    let activeViewModels: Observable<[EnvironmentDemoViewModel]>
    
    func update() {
        calculateAllViewModelsValue()
    }
    
    fileprivate static let capabilityOrder: [DeviceCapability] = [
        .temperature,
        .humidity,
        .ambientLight,
        
        .uvIndex,
        .airPressure,
        .soundLevel,
        
        .airQualityCO2,
        .airQualityVOC,
        .hallEffectState,
        
        .hallEffectFieldStrength
    ]
    
    fileprivate static let dataMappers: [DeviceCapability : DataMapperFunction] = [
        .temperature : { data in
            
            let title = "Temperature"
            if let temperature = data.temperature {

                let color = UIColor.colorForTemperature(temperature)
                
                let settings = ThunderboardSettings()
                var value = ""
                switch settings.temperature {
                case .fahrenheit:
                    let temperatureInWholeDegrees = Int(temperature.tb_FahrenheitValue)
                    value = "\(temperatureInWholeDegrees)°F"
                case .celsius:
                    let temperature = temperature.tb_roundToTenths()
                    value = "\(temperature)°C"
                }
                
                return EnvironmentCellData(name: title, value: value, imageName: "icon - temp", imageBackgroundColor: color, power: .na)
            }
            
            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "icn_demo_temp_inactive", imageBackgroundColor: nil, power: .na)
        },
        
        .humidity : { data in
            
            let title = "Humidity"
            if let humidity = data.humidity {

                let color = UIColor.colorForHumidity(humidity)
                let value = "\(Int(humidity))%"
                
                return EnvironmentCellData(name: title, value: value, imageName: "icon - environment", imageBackgroundColor: color, power: .na)
            }
            
            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "icn_demo_humidity_inactive", imageBackgroundColor: nil, power: .na)
        },
        
        .ambientLight : { data in
            
            let title = "Ambient Light"
            if let ambientLight = data.ambientLight {
                
                let color = UIColor.colorForIlluminance(ambientLight)
                let value = "\(ambientLight.tb_toString(0)!) lx"
                
                return EnvironmentCellData(name: title, value: value, imageName: "icon - light", imageBackgroundColor: color, power: .na)
            }
            
            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "icn_demo_ambient_light_inactive", imageBackgroundColor: nil, power: .na)
        },
        
        .uvIndex : { data in
            
            let title = "UV Index"
            if let uvIndex = data.uvIndex {
                
                let color = UIColor.colorForUVIndex(uvIndex)
                let value = uvIndex.tb_toString(0) ?? ""
                
                return EnvironmentCellData(name: title, value: value, imageName: "icon - UV", imageBackgroundColor: color, power: .na)
            }
            
            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "icn_demo_uv_index_inactive", imageBackgroundColor: nil, power: .na)
        },
        
        .airQualityCO2 : { data in
            let title = "Carbon Dioxide"
            if let co2 = data.co2 {
                if co2.enabled, let co2Value = co2.value {
                    let color = UIColor.colorForCO2(co2Value)
                    let value = "\(Int(co2Value)) ppm"

                    return EnvironmentCellData(name: title, value: value, imageName: "icon - CO2", imageBackgroundColor: color, power: .on)
                }

                return EnvironmentCellData(name: title, value: "OFF", imageName: "ic_carbon_dioxide_inactive", imageBackgroundColor: nil, power: .off)
            }
            
            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "ic_carbon_dioxide_inactive", imageBackgroundColor: nil, power: .na)
        },
        
        .airQualityVOC : { data in
            let title = "VOCs"
            if let voc = data.voc {
                if voc.enabled, let vocValue = voc.value {
                    let color = UIColor.colorForVOC(vocValue)
                    let value = "\(Int(vocValue)) ppb"
                    
                    return EnvironmentCellData(name: title, value: value, imageName: "icon - VOCs", imageBackgroundColor: color, power: .on)
                }

                return EnvironmentCellData(name: title, value: "OFF", imageName: "ic_voc_inactive", imageBackgroundColor: nil, power: .off)
            }
            
            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "ic_voc_inactive", imageBackgroundColor: nil, power: .na)
        },
        
        .airPressure : { data in
            let title = "Air Pressure"
            if let pressure = data.pressure {
                
                let color = UIColor.colorForAtmosphericPressure(pressure)
                let value = "\(Int(pressure)) mbar"
                
                return EnvironmentCellData(name: title, value: value, imageName: "icon - air pressure", imageBackgroundColor: color, power: .na)
            }
            
            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "ic_atmospheric_pressure_inactive", imageBackgroundColor: nil, power: .na)
        },
        
        .soundLevel : { data in
            let title = "Sound Level"
            if let soundLevel = data.sound {
                
                let color = UIColor.colorForSoundLevel(soundLevel)
                let value = "\(Int(soundLevel)) dB"
                
                return EnvironmentCellData(name: title, value: value, imageName: "icon - sound", imageBackgroundColor: color, power: .na)
            }
            
            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "ic_sound_level_inactive", imageBackgroundColor: nil, power: .na)
        },

        .hallEffectState : { data in
            let title = "Door State"
            if let hallEffectState = data.hallEffectState {

                let color = UIColor.colorForHallEffectState(hallEffectState)
                let value: String
                switch hallEffectState {
                case .closed:
                    value = "Closed"
                case .open:
                    value = "Opened"
                case .tamper:
                    value = "Tampered\nTap to Reset"
                }
                let imageName = UIImage.imageNameForHallEffectState(hallEffectState)
                return EnvironmentCellData(name: title, value: value, imageName: "icon - door state", imageBackgroundColor: color, power: .na)
            }

            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "icon - door state inactive", imageBackgroundColor: nil, power: .na)
        },

        .hallEffectFieldStrength : { data in
            let title = "Magnetic Field"
            if let hallEffectFieldStrength = data.hallEffectFieldStrength {

                let color = UIColor.colorForHallEffectFieldStrength(mT: hallEffectFieldStrength)
                let value = "\(hallEffectFieldStrength) uT"
                return EnvironmentCellData(name: title, value: value, imageName: "icon - magnetic field", imageBackgroundColor: color, power: .na)
            }

            return EnvironmentCellData(name: title, value: String.tb_placeholderText(), imageName: "icon - magnetic field inactive", imageBackgroundColor: nil, power: .na)
        },
    ]
    
    var currentHallEffectState: HallEffectState? = nil
    
    override init() {
        activeViewModels = Observable.combineLatest(allViewModels.asObservable(), capabilities.asObservable().distinctUntilChanged())
            .map { viewModels, capabilities in
                return viewModels.filter({ capabilities.contains($0.capability) })
        }
        
        super.init()
        
        calculateAllViewModelsValue()
    }
    
    private func calculateAllViewModelsValue() {
        let lastEmitedValueIsEmpty = allViewModels.value.isEmpty
        
        let capabilityOrder = EnvironmentDemoCollectionViewDataSource.capabilityOrder
        let allViewModelsValue = capabilityOrder
            .compactMap { capability -> EnvironmentDemoViewModel? in
                guard let data = EnvironmentDemoCollectionViewDataSource.dataMappers[capability]?(EnvironmentData()) else {
                    return nil
                }
                
                let viewModel = EnvironmentDemoViewModel(capability: capability)
                viewModel.updateData(cellData: data, reload: lastEmitedValueIsEmpty)
                return viewModel
        }
        
        allViewModels.accept(allViewModelsValue)
    }
    
    // MARK: - Public (Internal)
    
    func updateData(_ data: EnvironmentData, capabilities deviceCapabilities: Set<DeviceCapability>) {
        capabilities.accept(deviceCapabilities)
        
        allViewModels.value.forEach { viewModel in
            guard let cellData = EnvironmentDemoCollectionViewDataSource.dataMappers[viewModel.capability]?(data) else {
                return
            }
            
            viewModel.updateData(cellData: cellData)
        }
        
        if let hallEffectState = data.hallEffectState {
            currentHallEffectState = hallEffectState
        }
    }
}
