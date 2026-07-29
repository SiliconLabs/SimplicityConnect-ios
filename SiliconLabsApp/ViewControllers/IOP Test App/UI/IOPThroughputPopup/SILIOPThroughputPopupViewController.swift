//
//  SILIOPThroughputPopupViewController.swift
//  BlueGecko
//
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit

/// Modal card matching IOP throughput summary: gauge, MTU, buffer size, kbps readout.
final class SILIOPThroughputPopupViewController: UIViewController {

    private var speedKbps: Double
    private var maxSpeedKbps: Double
    private var averageSpeedKbps: Double
    private var targetSpeedKbps: Double
    private let mtuSize: Int
    private let bufferSize: Int
    private var isCompleted: Bool

    private let dimView = UIView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let gaugeView = SILIOPThroughputGaugeView()
    private let mtuLabel = UILabel()
    private let bufferLabel = UILabel()
    private let maxThroughputLabel = UILabel()
    private let averageThroughputLabel = UILabel()
    private let targetThroughputLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    /// Called after the popup is dismissed. Advances IOP to Security & Encryption.
    var onContinueThroughputSuite: (() -> Void)?
    private static let autoDismissSeconds: TimeInterval = 10
    private var autoDismissTimer: Timer?
    private var hasDismissed = false

    init(speedKbps: Double, maxSpeedKbps: Double, averageSpeedKbps: Double, targetSpeedKbps: Double, mtuSize: Int, bufferSize: Int, isCompleted: Bool) {
        self.speedKbps = speedKbps
        self.maxSpeedKbps = maxSpeedKbps
        self.averageSpeedKbps = averageSpeedKbps
        self.targetSpeedKbps = targetSpeedKbps
        self.mtuSize = mtuSize
        self.bufferSize = bufferSize
        self.isCompleted = isCompleted
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        let dimTap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        dimView.addGestureRecognizer(dimTap)
        view.addSubview(dimView)

        cardView.backgroundColor = UIColor.sil_background()
        
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        titleLabel.text = "Throughput"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = UIColor(white: 0.2, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        gaugeView.backgroundColor = UIColor.sil_background()
        gaugeView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(gaugeView)

        mtuLabel.font = .systemFont(ofSize: 14, weight: .regular)
        mtuLabel.textColor = UIColor(white: 0.35, alpha: 1)
        mtuLabel.textAlignment = .center
        mtuLabel.numberOfLines = 0
        mtuLabel.text = "MTU size: \(mtuSize) bytes"
        mtuLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(mtuLabel)

        bufferLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bufferLabel.textColor = UIColor(white: 0.35, alpha: 1)
        bufferLabel.textAlignment = .center
        bufferLabel.numberOfLines = 0
        bufferLabel.text = "Buffer size: \(bufferSize) bytes"
        bufferLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(bufferLabel)
        
        for label in [maxThroughputLabel, averageThroughputLabel, targetThroughputLabel] {
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = UIColor(white: 0.2, alpha: 1)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(label)
        }

        closeButton.setTitle("Done", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        closeButton.tintColor = .systemRed
        closeButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            cardView.widthAnchor.constraint(equalToConstant: min(340, UIScreen.main.bounds.width - 48)),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            gaugeView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            gaugeView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            gaugeView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            gaugeView.heightAnchor.constraint(equalToConstant: 320),

            mtuLabel.topAnchor.constraint(equalTo: gaugeView.bottomAnchor, constant: 10),
            mtuLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mtuLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            bufferLabel.topAnchor.constraint(equalTo: mtuLabel.bottomAnchor, constant: 4),
            bufferLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            bufferLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            maxThroughputLabel.topAnchor.constraint(equalTo: bufferLabel.bottomAnchor, constant: 12),
            maxThroughputLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            maxThroughputLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            averageThroughputLabel.topAnchor.constraint(equalTo: maxThroughputLabel.bottomAnchor, constant: 4),
            averageThroughputLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            averageThroughputLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            targetThroughputLabel.topAnchor.constraint(equalTo: averageThroughputLabel.bottomAnchor, constant: 4),
            targetThroughputLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            targetThroughputLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            closeButton.topAnchor.constraint(equalTo: targetThroughputLabel.bottomAnchor, constant: 16),
            closeButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])

        applyCurrentState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyCurrentState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }

    func update(speedKbps: Double, maxSpeedKbps: Double, averageSpeedKbps: Double, targetSpeedKbps: Double, isCompleted: Bool) {
        self.speedKbps = speedKbps
        self.maxSpeedKbps = maxSpeedKbps
        self.averageSpeedKbps = averageSpeedKbps
        self.targetSpeedKbps = targetSpeedKbps
        self.isCompleted = isCompleted
        if isViewLoaded {
            applyCurrentState()
        }
    }

    private func applyCurrentState() {
        guard isViewLoaded else { return }
        gaugeView.layoutIfNeeded()
        let bitsPerSecond = Int(max(0, speedKbps * 1000.0))
        let result = SILThroughputResult(
            sender: .EFRToPhone,
            testType: .notifications,
            valueInBits: bitsPerSecond
        )
        gaugeView.updateView(throughputResult: result)
        maxThroughputLabel.text = "Peak throughput: \(formattedThroughput(maxSpeedKbps))"
        averageThroughputLabel.text = "Average throughput: \(formattedThroughput(averageSpeedKbps))"
        targetThroughputLabel.text = "Target throughput threshold: \(formattedThroughput(targetSpeedKbps))"
        maxThroughputLabel.isHidden = !isCompleted
        averageThroughputLabel.isHidden = !isCompleted
        targetThroughputLabel.isHidden = !isCompleted
        closeButton.isHidden = !isCompleted
        closeButton.isEnabled = isCompleted
        
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        //if isCompleted {
            autoDismissTimer = Timer.scheduledTimer(withTimeInterval: Self.autoDismissSeconds, repeats: false) { [weak self] _ in
                self?.dismissTapped()
            //}
        }
    }
    
    private func formattedThroughput(_ valueKbps: Double) -> String {
        if valueKbps >= 1000.0 {
            return String(format: "%.2f Mbps", valueKbps / 1000.0)
        } else {
            return String(format: "%.1f kbps", valueKbps)
        }
    }

    @objc private func dismissTapped() {
        guard !hasDismissed else { return }
        hasDismissed = true
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let continuation = self.onContinueThroughputSuite
            self.onContinueThroughputSuite = nil
            continuation?()
        }
    }
}
