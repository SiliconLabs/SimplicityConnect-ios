//
//  SILRangeTestMovingAverageCalculator.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 30.07.2018.
//  Copyright © 2018 SiliconLabs. All rights reserved.
//

import UIKit

class SILRangeTestMovingAverageCalculator: NSObject {
    
    private let windowSize: Int
    private var previousKnownRx: Int = 0
    private var previousKnownTotalRx: Int = 0
    private var rxValues: [Int] = []
    private(set) var value: Float = 0

    init(withWindowSize windowSize: Int) {
        self.windowSize = windowSize
    }
    
    func add(rx: Int, andTotalRx totalRx: Int) {
        guard totalRx != previousKnownTotalRx else { return }
        
        if totalRx < previousKnownTotalRx {
            rxValues.removeAll()
        }
        
        approximateRxValues(withRx: rx, andTotalRx: totalRx)
        
        previousKnownRx = rx
        previousKnownTotalRx = totalRx
        rxValues = Array(rxValues.suffix(windowSize))
        
        let minValue = rxValues.first! - 1
        let maxValue = rxValues.last!
        value = perValue(forRx: maxValue - minValue, andTotalRx: rxValues.count)
    }
    
    private func approximateRxValues(withRx rx: Int, andTotalRx totalRx: Int) {
        guard rxValues.count > 0 else {
            rxValues.append(rx)
            return
        }
        
        let totalRxDiff = totalRx - previousKnownTotalRx
        let rxDiff = rx - previousKnownRx
        let rxChangeRate = Float(rxDiff) / Float(totalRxDiff)
        
        for i in 1...totalRxDiff {
            let approximatedRx = Float(previousKnownRx) + (rxChangeRate * Float(i))
            
            rxValues.append(Int(roundf(approximatedRx)))
        }
    }
    
    private func perValue(forRx rx: Int, andTotalRx totalRx: Int) -> Float {
        let value = totalRx != 0 ? Float(totalRx - rx) / Float(totalRx) : 0
        let flooredValue = floorf(value * 1000) / 10
        return flooredValue
    }
}
