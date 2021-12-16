//
//  WeakTimer.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import Foundation

typealias WeakTimerBlock = (() -> Void)

class WeakTimer : NSObject {
    
    fileprivate var timer: Timer?
    
    //MARK: -
    
    class func scheduledTimer(_ interval: TimeInterval, repeats: Bool, action: @escaping WeakTimerBlock) -> WeakTimer {
        let result = WeakTimer(interval: interval, repeats: repeats, action: action)
        result.start()
        return result
    }
    
    init(interval: TimeInterval, repeats: Bool, action: @escaping WeakTimerBlock) {
        super.init()
        let target = WeakTimerObserver(action: action)
        timer = Timer(timeInterval: interval, target: target, selector: #selector(WeakTimerObserver.timerFired), userInfo: nil, repeats: repeats)
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func start() {
        if let timer = timer {
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    //MARK: - Internal
    
    fileprivate class WeakTimerObserver : NSObject {
        var actionBlock: WeakTimerBlock?
        
        init(action: @escaping WeakTimerBlock) {
            self.actionBlock = action
            super.init()
        }
        
        @objc func timerFired() {
            actionBlock?()
        }
    }
    
    
}
