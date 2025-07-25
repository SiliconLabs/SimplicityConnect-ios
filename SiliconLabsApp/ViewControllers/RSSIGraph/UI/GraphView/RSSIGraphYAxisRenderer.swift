//
//  RSSIGraphYAxisRenderer.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 14/03/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import DGCharts

class RSSIGraphYAxisRenderer : YAxisRenderer {
    private let arrowWidth = CGFloat(6)
    private let arrowHeight = CGFloat(7)
    
    override func renderLimitLines(context: CGContext) {
        guard let yAxis = self.axis as? YAxis,
            let transformer = self.transformer
            else { return }
        let trans = transformer.valueToPixelMatrix
        
        for limitLine in yAxis.limitLines {
            if !limitLine.isEnabled {
                continue
            }
            
            context.saveGState()
            defer { context.restoreGState() }
            
            let position = CGPoint(x: 0, y: limitLine.limit).applying(trans)
            
            drawLine(forLimitLine: limitLine, inContext: context, onPosition: position)
        }
    }
    
    private func drawLine(forLimitLine limitLine: ChartLimitLine, inContext context: CGContext, onPosition position: CGPoint) {
        var clippingRect = viewPortHandler.contentRect
        clippingRect.origin.y -= limitLine.lineWidth / 2.0
        clippingRect.size.height += limitLine.lineWidth
        context.resetClip()
        context.clip(to: clippingRect)
        
        context.beginPath()
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
        
        let lineX = viewPortHandler.contentRight + (limitLine.limit != 0 ? 0 : arrowWidth)
        context.addLine(to: CGPoint(x: lineX, y: position.y))
        
        context.setStrokeColor(limitLine.lineColor.cgColor)
        context.setLineWidth(limitLine.lineWidth)
        
        if limitLine.lineDashLengths != nil {
            context.setLineDash(phase: limitLine.lineDashPhase, lengths: limitLine.lineDashLengths!)
        } else {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        context.strokePath()
    }
}

class RSSIGraphYAxisValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let sign = value > 0 ? "+" : ""
        return String(format: "%@%g dBm", sign, value)
    }
}

