//
//  Throttle.swift
//  Thunderboard
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

class Throttle {
    typealias ThrottleBlock = () -> ()
    fileprivate var queuedActions: Dictionary<String, ThrottleBlock> = [:]
    var interval: TimeInterval
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func run(_ block: @escaping ThrottleBlock) {
        run("default", block: block)
    }
    
    func run(_ key: String, block: @escaping ThrottleBlock) {
        dispatch_main_async {
            if self.queuedActions[key] == nil {
                delay(self.interval) {
                    if let action = self.queuedActions.removeValue(forKey: key) {
                        action()
                    }
                }
            }

            self.queuedActions[key] = block
        }
    }
}
