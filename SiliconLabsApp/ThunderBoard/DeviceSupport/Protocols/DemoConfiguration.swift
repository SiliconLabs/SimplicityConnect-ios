//
//  DemoConfiguration.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

protocol DemoConfiguration: class {
    var deviceIdentifier: DeviceId? { get }
    var configurationDelegate: DemoConfigurationDelegate? { get set }
    func configureForDemo(_ demo: ThunderboardDemo)
    func resetDemoConfiguration()
}

protocol DemoConfigurationDelegate: class {
    
    func deviceIdentifierUpdated(_ deviceId: DeviceId)

    func modelNameReady(device: Device)
    
    func configuringIoDemo()
    func ioDemoReady(_ connection: IoDemoConnection)
    
    func configuringMotionDemo()
    func motionDemoReady(_ connection: MotionDemoConnection)
    
    func configuringEnvironmentDemo()
    func environmentDemoReady(_ connection: EnvironmentDemoConnection)
    
    func demoConfigurationReset()
}
