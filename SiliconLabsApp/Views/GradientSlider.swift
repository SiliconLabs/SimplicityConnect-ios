//
//  GradientSlider.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 7/27/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import UIKit

final class GradientSlider: UISlider {

    // MARK: - Properties

    var colors: [UIColor] = [] {
        didSet {
            gradientTrack.colors = colors
        }
    }

    private lazy var gradientTrack: GradientView = {
        let view = GradientView(colors: [],
                                direction: .horizontal)
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var thickerMaximumTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = .sil_lineGrey()
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        return view
    }()

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    convenience init(colors: [UIColor]) {
        self.init(frame: .zero)
        defer { self.colors = colors }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let trackRect = self.trackRect(forBounds: rect)
        let trackHeight: CGFloat = 3
        let thumbRect = self.thumbRect(forBounds: rect, trackRect: trackRect, value: value)
        let gradientTrackFrame = CGRect(x: trackRect.origin.x,
                                        y: trackRect.midY - trackHeight / 2,
                                        width: thumbRect.midX,
                                        height: trackHeight)
        gradientTrack.frame = gradientTrackFrame
        thickerMaximumTrackView.frame = CGRect(x: gradientTrackFrame.maxX,
                                               y: gradientTrackFrame.origin.y,
                                               width: bounds.width - gradientTrackFrame.maxX - trackRect.minX,
                                               height: trackHeight)
    }

    // MARK: - Actions

    @objc private func redraw() {
        setNeedsDisplay()
    }

    // MARK: Setup

    private func setup() {
        isContinuous = true
        minimumTrackTintColor = .clear
        maximumTrackTintColor = .clear

        insertSubview(gradientTrack, at: 1)
        insertSubview(thickerMaximumTrackView, at: 1)

        addTarget(self, action: #selector(redraw), for: .valueChanged)
    }
}
