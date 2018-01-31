//
//  GradientView.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 7/27/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import UIKit

struct GradientSpec {
    var direction: GradientView.Direction
    var colors: [UIColor] = []
    var locations: [CGFloat]?
}

class GradientView: UIView {
    enum Direction {
        case vertical
        case horizontal
        case topLeftToBottomRight

        func startPoint(for rect: CGRect) -> CGPoint {
            return CGPoint(x: 0, y: 0)
        }

        func endPoint(for rect: CGRect) -> CGPoint {
            switch self {
            case .vertical:
                return CGPoint(x: 0, y: rect.height)
            case .horizontal:
                return CGPoint(x: rect.width, y: 0)
            case .topLeftToBottomRight:
                return CGPoint(x: rect.width, y: rect.height)
            }
        }
    }

    var colors: [UIColor] = [] {
        didSet {
            guard let gradient = CGGradient(colorsSpace: nil, colors: colors.map { $0.cgColor } as CFArray, locations: locations) else { return }
            self.gradient = gradient
        }
    }

    var locations: [CGFloat]? = nil {
        didSet {
            guard let gradient = CGGradient(colorsSpace: nil, colors: colors.map { $0.cgColor } as CFArray, locations: locations) else { return }
            self.gradient = gradient
        }
    }

    var direction: Direction = .vertical {
        didSet {
            setNeedsDisplay()
        }
    }

    private var gradient: CGGradient? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    init(colors: [UIColor] = [], locations: [CGFloat]? = nil, direction: Direction = .vertical) {
        self.direction = direction
        self.colors = colors
        self.locations = locations
        super.init(frame: .zero)

        if let gradient = CGGradient(colorsSpace: nil, colors: colors.map { $0.cgColor } as CFArray, locations: locations) {
            self.gradient = gradient
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        guard
            let context = UIGraphicsGetCurrentContext(),
            let gradient = gradient
            else { return }

        context.drawLinearGradient(
            gradient,
            start: direction.startPoint(for: rect),
            end: direction.endPoint(for: rect),
            options: CGGradientDrawingOptions())
    }

    func apply(_ spec: GradientSpec) {
        direction = spec.direction
        colors = spec.colors
        locations = spec.locations
    }
}
