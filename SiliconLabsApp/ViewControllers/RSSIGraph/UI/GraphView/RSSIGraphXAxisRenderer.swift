//
//  RSSIGraphXAxisRenderer.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 14/03/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import Charts

class RSSIGraphXAxisRenderer: XAxisRenderer {
    
    override func computeAxisValues(min: Double, max: Double) {
        // sometimes rounding of float numbers causes disappearing the last label, we must ensure to have range 30.0
        super.computeAxisValues(min: min, max: min + RSSIConstants.maxNumberOfVisibleXValues)
    }
    
    override func renderLimitLines(context: CGContext) {
        let xAxis = self.axis
        
        guard let transformer = self.transformer else { return }
        let trans = transformer.valueToPixelMatrix
        
        for limitLine in xAxis.limitLines {
            if !limitLine.isEnabled {
                continue
            }
            
            context.saveGState()
            defer { context.restoreGState() }
            
            let position = CGPoint(x: limitLine.limit, y: 0).applying(trans)
            
            drawLine(forLimitLine: limitLine, inContext: context, onPosition: position)
            renderLimitLineLabel(context: context, limitLine: limitLine, position: position, yOffset: limitLine.yOffset)
        }
    }
    
    private func drawLine(forLimitLine limitLine: ChartLimitLine, inContext context: CGContext, onPosition position: CGPoint) {
        var clippingRect = viewPortHandler.contentRect
        clippingRect.origin.x -= limitLine.lineWidth / 2.0
        clippingRect.size.width += limitLine.lineWidth
        context.resetClip()
        context.clip(to: clippingRect)
        
        context.beginPath()
        context.move(to: CGPoint(x: position.x, y: viewPortHandler.contentTop))
        context.addLine(to: CGPoint(x: position.x, y: viewPortHandler.contentBottom))
        
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

class RSSIGraphXAxisValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return "\(Int(value)) s"
    }
}
