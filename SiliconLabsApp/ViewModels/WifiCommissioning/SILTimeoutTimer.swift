//
//  SILTimeoutTimer.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 06/12/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILTimeoutTimer {
    private var readTimer: WeakTimer?
    private var timeoutTimer: WeakTimer?
    
    private let timeoutExceedAction: () -> ()
    private let action: () -> ()
    private let interval: TimeInterval
    private let timeout: TimeInterval
    
    init(action: @escaping () -> (), timeoutExceedAction: @escaping () -> (), interval: TimeInterval , timeout: TimeInterval) {
        self.action = action
        self.timeoutExceedAction = timeoutExceedAction
        self.timeout = timeout
        self.interval = interval
    }
    
    public func start() {
        self.setTimeout()
        self.readTimer = WeakTimer.scheduledTimer(interval, repeats: true) {
            self.action()
        }
        self.readTimer?.start()
    }
    
    public func stop() {
        stopTimeout()
        stopReadTimer()
    }
    
    private func stopReadTimer() {
        self.stopTimeout()
        self.readTimer?.stop()
        self.readTimer = nil
    }
    
    private func setTimeout() {
        self.timeoutTimer = WeakTimer.scheduledTimer(timeout, repeats: false) {
            self.stopReadTimer()
            self.timeoutExceedAction()
        }
    }
    
    private func stopTimeout() {
        self.timeoutTimer?.stop()
        self.timeoutTimer = nil
    }
}
