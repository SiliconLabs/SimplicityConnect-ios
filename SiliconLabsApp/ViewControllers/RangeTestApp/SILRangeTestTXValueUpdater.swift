//
//  SILRangeTestTXValueUpdater.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 31.08.2018.
//  Copyright © 2018 SiliconLabs. All rights reserved.
//

import UIKit

class SILRangeTestTXValueUpdater {
    private let timer : DispatchSourceTimer
    
    private var value: Int
    private let maxValue: Int
    private let callback: (Int) -> Void
    
    init(withValue value: Int, upToValue: Int, updateInterval: TimeInterval, callback: @escaping (Int) -> Void) {
        self.value = value
        self.maxValue = upToValue
        self.callback = callback
        
        self.timer = DispatchSource.makeTimerSource()
        self.timer.schedule(deadline: .now(), repeating: updateInterval)
        self.timer.setEventHandler { [weak self] in
            self?.timerBlock()
        }
        self.timer.resume()
    }
    
    deinit {
        cancelTimer()
    }
    
    func update(withActualValue value: Int) {
        self.value = value
        self.callback(value)
    }
    
    private func timerBlock() {
        guard self.maxValue == -1 || self.value < self.maxValue else {
            cancelTimer()
            return
        }
        
        self.callback(self.value)
    }
    
    private func cancelTimer() {
        self.timer.setEventHandler {}
        self.timer.cancel()
    }
}
