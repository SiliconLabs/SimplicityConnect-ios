//
//  RSSISliderTableViewCell.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 7/26/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import UIKit

protocol RSSISliderTableViewCellDelegate: class {
    func rssiValueDidChange(_ newValue: Int)
}

@objc(SILRSSISliderTableViewCell)
final class RSSISliderTableViewCell: UITableViewCell {

    // MARK: - Properties

    static let cellIdentifier = "RSSISliderTableViewCell"

    private struct Constants {
        static let sliderGrey = UIColor(red:0.85, green:0.84, blue:0.84, alpha:1.00)
        static let sliderRed = UIColor(red:0.84, green:0.14, blue:0.19, alpha:1.00)
        static let backgroundGrey = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.00)
    }

    weak var delegate: RSSISliderTableViewCellDelegate? = nil

    /// Set the initial value of the slider
    var initialValue: Int? = nil {
        didSet {
            if let initialValue = initialValue {
                currentRSSIValueLabel.text = "\(initialValue)"
                rssiSliderIsSet = true
                slider.value = Float(initialValue)
            } else {
                prepareForReuse()
            }
        }
    }

    private(set) var currentValue: Int? = nil {
        didSet {
            if let currentValue = currentValue {
                currentRSSIValueLabel.text = "\(currentValue)"
                delegate?.rssiValueDidChange(currentValue)
            } else {
                currentRSSIValueLabel.text = "Not Set"
            }
        }
    }

    private let sliderColors = [
        Constants.sliderGrey,
        Constants.sliderRed
    ]
    private let slider: GradientSlider
    private let topView = UIView()
    private let currentRSSIValueLabel = UILabel()
    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .sil_lineGrey()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var disabledKnobImage: UIImage? = {
        let size = CGSize(width: 24, height: 24)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
        UIColor.sil_lineGrey().setFill()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }()

    private lazy var enabledKnobImage: UIImage? = {
        let size = CGSize(width: 24, height: 24)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
        UIColor(red:0.84, green:0.14, blue:0.19, alpha:1.00).setFill()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }()

    var rssiSliderIsSet = false {
        didSet {
            guard rssiSliderIsSet != oldValue else { return }
            if rssiSliderIsSet {
                slider.setThumbImage(enabledKnobImage, for: .normal)
                slider.setThumbImage(enabledKnobImage, for: .highlighted)
            } else {
                slider.setThumbImage(disabledKnobImage, for: .normal)
                slider.setThumbImage(enabledKnobImage, for: .highlighted)
            }
        }
    }

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        slider = GradientSlider(colors: sliderColors)
        super.init(coder: aDecoder)
        setup()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        slider = GradientSlider(colors: sliderColors)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentValue = nil
        rssiSliderIsSet = false
        slider.value = slider.minimumValue
        slider.setNeedsDisplay()
    }

    // MARK: - Actions

    @objc private func rssiSliderValueDidChange(slider: GradientSlider) {
        currentValue = Int(slider.value)
    }

    @objc private func rssiSliderWasHighlighted(slider: GradientSlider) {
        rssiSliderIsSet = true
    }

    // MARK: Setup

    private func setup() {
        setupTopView()
        setupSliderView()
        setupDivider()
        
        contentView.backgroundColor = Constants.backgroundGrey
    }

    private func setupTopView() {
        topView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topView)

        topView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        topView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        topView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15).isActive = true
        topView.heightAnchor.constraint(equalToConstant: 19).isActive = true

        let rssiIconView = UIImageView(image: #imageLiteral(resourceName: "icRssi"))
        rssiIconView.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(rssiIconView)

        rssiIconView.leadingAnchor.constraint(equalTo: topView.leadingAnchor).isActive = true
        rssiIconView.centerYAnchor.constraint(equalTo: topView.centerYAnchor).isActive = true

        let rssiLabel = UILabel()
        rssiLabel.text = "RSSI"
        rssiLabel.font = .helveticaNeue(size: 14)
        rssiLabel.textColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.54)
        rssiLabel.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(rssiLabel)

        rssiLabel.leadingAnchor.constraint(equalTo: rssiIconView.trailingAnchor, constant: 8).isActive = true
        rssiLabel.centerYAnchor.constraint(equalTo: topView.centerYAnchor).isActive = true

        currentRSSIValueLabel.text = "Not Set"
        currentRSSIValueLabel.font = .helveticaNeue(size: 16)
        currentRSSIValueLabel.textColor = UIColor(red:0.31, green:0.31, blue:0.31, alpha:1.00)
        currentRSSIValueLabel.textAlignment = .right
        currentRSSIValueLabel.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(currentRSSIValueLabel)

        currentRSSIValueLabel.trailingAnchor.constraint(equalTo: topView.trailingAnchor).isActive = true
        currentRSSIValueLabel.topAnchor.constraint(equalTo: topView.topAnchor).isActive = true
        currentRSSIValueLabel.bottomAnchor.constraint(equalTo: topView.bottomAnchor).isActive = true
        currentRSSIValueLabel.leadingAnchor.constraint(equalTo: rssiLabel.trailingAnchor, constant: 8).isActive = true

        currentRSSIValueLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 240), for: .horizontal)
    }

    private func setupSliderView() {
        let minValueLabel = UILabel()
        minValueLabel.text = "-100"
        minValueLabel.textColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.34)
        minValueLabel.font = .helveticaNeue(size: 12)
        minValueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(minValueLabel)

        let maxValueLabel = UILabel()
        maxValueLabel.text = "0"
        maxValueLabel.textColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.34)
        maxValueLabel.font = .helveticaNeue(size: 12)
        maxValueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(maxValueLabel)

        slider.minimumValue = -100
        slider.maximumValue = 0
        slider.value = -100
        slider.addTarget(self, action: #selector(rssiSliderValueDidChange(slider:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(rssiSliderWasHighlighted(slider:)), for: UIControl.Event.allTouchEvents)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setThumbImage(disabledKnobImage, for: .normal)
        slider.setThumbImage(enabledKnobImage, for: .highlighted)
        contentView.addSubview(slider)

        // Constraints
        minValueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 21).isActive = true
        minValueLabel.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 11).isActive = true

        maxValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        maxValueLabel.topAnchor.constraint(equalTo: minValueLabel.topAnchor).isActive = true

        slider.leadingAnchor.constraint(equalTo: minValueLabel.trailingAnchor, constant: 8).isActive = true
        slider.trailingAnchor.constraint(equalTo: maxValueLabel.leadingAnchor, constant: -8).isActive = true
        slider.centerYAnchor.constraint(equalTo: minValueLabel.centerYAnchor).isActive = true
    }

    private func setupDivider() {
        addSubview(divider)

        divider.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        divider.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        divider.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        divider.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
}
