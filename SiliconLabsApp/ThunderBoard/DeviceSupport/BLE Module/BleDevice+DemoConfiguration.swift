//
//  BleDevice+DemoConfiguration.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation
import CoreBluetooth

extension BleDevice {
    
    // TODO: cleanup (remove duplication between demo configurations)
    fileprivate func isNotificationProtected(_ characteristic: CBCharacteristic) -> Bool {
        return [
            CBUUID.BatteryLevel
            
        ].contains(characteristic.uuid)
    }


    fileprivate func allKnownCharacteristics() -> Set<CBUUID> {
        var result: Set<CBUUID> = []
        
        if let knownUUIDs = self.cbPeripheral.services?.compactMap({ $0.characteristics?.compactMap({ $0.uuid }) }).flatMap({$0}) {
            for uuid in knownUUIDs {
                result.insert(uuid)
            }
        }

        return result
    }
    
    fileprivate func waitForCharacteristics(_ uuids: Set<CBUUID>, timeout: Double = Double.infinity) -> AsyncOperation {
        var timeRemaining = timeout
        let operation = AsyncOperation(block: { (operation: AsyncOperation) -> Void in
            repeat {
                let knownUUIDs = self.allKnownCharacteristics()
                let matches = uuids.intersection(knownUUIDs)
                if matches.count == uuids.count {
                    log.debug("found all characteristics")
                    break
                }
                else {
                    let missing = uuids.subtracting(matches)
                    log.info("missing characteristics: \(missing)")
                }
                
                log.debug("waiting for characteristics")
                
                // TODO: remove sleep and inject operation into queue (linking dependencies)
                let sleepTime = min(timeRemaining, 1.0)
                Thread.sleep(forTimeInterval: sleepTime)
                timeRemaining -= sleepTime
            } while(self.connectionState == .connected && timeRemaining > 0.0)
            
            operation.done()
        })
        
        return operation
    }
    

    func resetDemoConfiguration() {
        log.debug("Demo Reset Requested")
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        allCharacteristics.forEach({ characteristic in
            if characteristic.tb_supportsNotificationOrIndication() && !self.isNotificationProtected(characteristic) {
                log.debug("Disabling notification on \(characteristic.uuid)")
                let _ = queue.tb_addAsyncOperationBlock({ (operation: AsyncOperation) -> Void in

                    self.characteristicNotificationUpdateHook = { (updatedCharacteristic: CBCharacteristic) -> Void in
                        if updatedCharacteristic == characteristic {
                            log.debug("Received notification update for \(characteristic.uuid)")
                            self.characteristicNotificationUpdateHook = nil
                            operation.done()
                        }
                    }
                    
                    self.cbPeripheral?.setNotifyValue(false, for: characteristic)
                })
            }
        })
    }
    
    func configureIoDemo() {
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Notify Configuration Starting
        let _ = queue.tb_addAsyncOperationBlock { (operation: AsyncOperation) -> Void in
            
            OperationQueue.main.addOperation({
                self.configurationDelegate?.configuringIoDemo()
                operation.done()
            })
        }
        
        // Enumerate services, characteristics
        let requiredCharacteristics: Set<CBUUID> = [
            CBUUID.Digital
        ]
        queue.addOperation(waitForCharacteristics(requiredCharacteristics))
        
        let completion = AsyncOperation(block: { (operation: AsyncOperation) -> Void in
            log.info("Finished IO configuration")
            OperationQueue.main.addOperation({ () -> Void in
                let connection = BleIoDemoConnection(device: self)
                self.configurationDelegate?.ioDemoReady(connection)
            })
        })
        
        // Enable notifications for the Digital characteristic
        let _ = queue.tb_addAsyncOperationBlock { (operation) -> Void in

            self.allCharacteristics.forEach({ characteristic in
                
                log.debug("checking \(characteristic.uuid)")
                if characteristic.tb_supportsNotificationOrIndication() && !self.isNotificationProtected(characteristic) {
                    
                    let notifyOperation = queue.tb_addAsyncOperationBlock({ (operation: AsyncOperation) -> Void in
                        
                        self.characteristicNotificationUpdateHook = { (updatedCharacteristic: CBCharacteristic) -> Void in
                            if updatedCharacteristic == characteristic {
                                log.debug("Received notification update for \(characteristic.uuid)")
                                self.characteristicNotificationUpdateHook = nil
                                operation.done()
                            }
                        }
                        
                        if requiredCharacteristics.contains(characteristic.uuid) {
                            log.debug("Updating notify for digital")
                            self.cbPeripheral.setNotifyValue(true, for: characteristic)
                        }
                            
                        else {
                            log.debug("disabling notify for \(characteristic.uuid)")
                            self.cbPeripheral.setNotifyValue(false, for: characteristic)
                        }
                    })
                    
                    completion.addDependency(notifyOperation)
                }
            })
            
            operation.done()
        }
        
        // add completion task
        queue.addOperation(completion)
        
        queue.isSuspended = false
    }
    
    func configureEnvironmentDemo() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Notify Configuration Starting
        let _ = queue.tb_addAsyncOperationBlock { (operation: AsyncOperation) -> Void in
            
            OperationQueue.main.addOperation({
                self.configurationDelegate?.configuringEnvironmentDemo()
                operation.done()
            })
        }
        
        // NOTE: the environmental demo polls most of the characteristics,
        // but we are waiting for discovery for the Hall State
        
        let requiredCharacteristics: Set<CBUUID> = [
            CBUUID.HallState,
            CBUUID.ModelNumber
        ]
        queue.addOperation(waitForCharacteristics(requiredCharacteristics, timeout: 5.0))
        
        let completion = AsyncOperation(block: { (operation: AsyncOperation) -> Void in
            log.info("Finished Environment configuration")
            OperationQueue.main.addOperation({ () -> Void in
                let connection = BleEnvironmentDemoConnection(device: self)
                self.configurationDelegate?.environmentDemoReady(connection)
            })
        })
        
        // Enable notifications for Hall State characteristic
        let _ = queue.tb_addAsyncOperationBlock { (operation) -> Void in
            
            self.allCharacteristics.forEach({ characteristic in
                
                log.debug("checking \(characteristic.uuid)")
                if characteristic.tb_supportsNotificationOrIndication() && !self.isNotificationProtected(characteristic) {
                    
                    let notifyOperation = queue.tb_addAsyncOperationBlock({ (operation: AsyncOperation) -> Void in
                        
                        self.characteristicNotificationUpdateHook = { (updatedCharacteristic: CBCharacteristic) -> Void in
                            if updatedCharacteristic == characteristic {
                                log.debug("Received notification update for \(characteristic.uuid)")
                                self.characteristicNotificationUpdateHook = nil
                                operation.done()
                            }
                        }
                        
                        // HallState only enables notification
                        // Other Environmental characteristics do not notify, so the demo connection class handles polling.
                        if requiredCharacteristics.contains(characteristic.uuid) {
                            log.debug("enabling notify for \(characteristic.uuid)")
                            self.cbPeripheral.setNotifyValue(true, for: characteristic)
                        } else {
                            log.debug("disabling notify for \(characteristic.uuid)")
                            self.cbPeripheral.setNotifyValue(false, for: characteristic)
                        }
                    })
                    completion.addDependency(notifyOperation)
                }
            })
            
            operation.done()
        }
        
        //add completion task
        queue.addOperation(completion)
        
        queue.isSuspended = false

    }

    func configureMotionDemo() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        // Notify Configuration Starting
        let _ = queue.tb_addAsyncOperationBlock { (operation: AsyncOperation) -> Void in
            
            OperationQueue.main.addOperation({
                self.configurationDelegate?.configuringMotionDemo()
                operation.done()
            })
        }
        
        // wait for required characteristics to become available
        var requiredCharacteristics: Set<CBUUID> = [
            CBUUID.Command,
            CBUUID.OrientationMeasurement,
            CBUUID.AccelerationMeasurement,
        ]

        if capabilities.contains(.revolutions) {
            requiredCharacteristics.insert(.CSCMeasurement)
            requiredCharacteristics.insert(.CSCControlPoint)
        }
        
        queue.addOperation(waitForCharacteristics(requiredCharacteristics))
        
        let completion = AsyncOperation(block: { operation in
            log.info("Finished Motion configuration")
            OperationQueue.main.addOperation({ () -> Void in
                let connection = BleMotionDemoConnection(device: self)
                self.configurationDelegate?.motionDemoReady(connection)
                operation.done()
            })
        })
        
        
        // Enable notifications for the Orientation, Acceleration, and Revolutions characteristics
        let _ = queue.tb_addAsyncOperationBlock({ operation in
            self.allCharacteristics.forEach({ characteristic in
                
                log.debug("checking \(characteristic.uuid)")
                
                if characteristic.tb_supportsNotificationOrIndication() && !self.isNotificationProtected(characteristic) {
                    
                    let notifyOperation = queue.tb_addAsyncOperationBlock({ (operation: AsyncOperation) -> Void in
                        
                        self.characteristicNotificationUpdateHook = { (updatedCharacteristic: CBCharacteristic) -> Void in
                            if updatedCharacteristic == characteristic {
                                log.debug("Received notification update for \(characteristic.uuid)")
                                self.characteristicNotificationUpdateHook = nil
                                operation.done()
                            }
                        }
                        
                        if requiredCharacteristics.contains(characteristic.uuid) {
                            log.debug("Enabling notify for \(characteristic.uuid)")
                            self.cbPeripheral.setNotifyValue(true, for: characteristic)
                        }
                            
                        else {
                            log.debug("disabling notify for \(characteristic.uuid)")
                            self.cbPeripheral.setNotifyValue(false, for: characteristic)
                        }
                    })
                    
                    completion.addDependency(notifyOperation)
                }
            })
            
            operation.done()
            
        })
        
        // add completion task
        queue.addOperation(completion)
        
        queue.isSuspended = false
    }
}
