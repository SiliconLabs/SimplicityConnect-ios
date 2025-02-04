//
//  SILGraphView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 18/02/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import UIKit
import Charts
import RxSwift
import RxRelay

class SILGraphView: UIView {
    
    private var referenceDate = Date()
    
    var refresh: PublishRelay<Void> = PublishRelay()
    var input: PublishRelay<[SILRSSIGraphDiscoveredPeripheralData]> = PublishRelay()

    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var chartView: RSSIGraphLineChartView!
    
    private let rightArrowButton = SILBigButton()
    private let leftArrowButton = SILBigButton()

    private var minimumYValue: Double = RSSIConstants.startYAxisMinimum
    private var maximumYValue: Double = RSSIConstants.startYAxisMaximum
    
    deinit {
        debugPrint("SILGraphView deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("SILGraphView", owner: self, options: nil)
        addSubview(contentView)
        contentView.backgroundColor = .clear
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupInput()
        setupLeftArrowButton()
        setupRightArrowButton()
    }
    // GRAPH DATA //
    private func setupInput() {
        input.asObservable()
            .flatMap { Observable.from($0) }
            .bind(with: self) { _self, cellData in
                if let dataSet = _self.chartView.lineData?.dataSets.first(where: { $0.label == cellData.uuid }) as? LineChartDataSet {
                    dataSet.setColor(cellData.color)
                    dataSet.lineWidth = cellData.isSelected ? RSSIConstants.selectedLineWidth : RSSIConstants.unselectedLineWidth
                    if cellData.isSelected {
                        // set selected dataSet to be drawn on the top
                        _self.chartView.lineData?.removeDataSet(dataSet)
                        _self.chartView.lineData?.append(dataSet)
                    }
                }
            }
            .disposed(by: disposeBag)
        
        input.asObservable().observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .flatMap { Observable.from($0) }
            .filter { [weak self] (dataSet) in
                guard let self = self else { return false }
                return self.chartView.checkIfDataSetExist(withLabel: dataSet.uuid)
            }
            .flatMap { data -> Observable<(String, SILRSSIMeasurement, UIColor)> in
                return Observable.from(data.peripheral.rssiMeasurementTable.rssiMeasurements.value).map { (data.peripheral.identityKey, $0, data.color) }.concat(Observable.combineLatest(
                    Observable.just(data.peripheral.identityKey),
                    data.peripheral.rssiMeasurementTable.lastMeasurement.asObservable(),
                    Observable.just(data.color)
                ))
            }
            .map { (id: $0, measurement: $1, color: $2) }
            .bind(with: self) { _self, val in
                let (id, measurement, color) = val
                _self.addOrUpdateDataForPeripheral(id, measurement: measurement, withColor: color)
            }
            .disposed(by: disposeBag)
        
        refresh.asObservable()
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(with: self) { _self, _ in
                _self.refreshGraph()
            }
            .disposed(by: disposeBag)
    }
    
    func startChart() {
        DispatchQueue.main.async {
            self.chartView.resetChart()
        }
    }
    
    func redrawChart() {
        self.chartView.resetChart()
        self.disposeBag = DisposeBag()
        self.setupInput()
    }
    
    func setStartTime(time : Date) {
        self.referenceDate = time
    }
    
    func refreshGraph() {
        let now = Double(Date().timeIntervalSince(referenceDate))
        
        chartView.xAxis.axisMinimum = RSSIConstants.startXAxisMinimum
        chartView.xAxis.axisMaximum = max(now, RSSIConstants.maxNumberOfVisibleXValues)
        
        chartView.leftAxis.axisMinimum = minimumYValue
        chartView.leftAxis.axisMaximum = maximumYValue
        chartView.setVisibleXRangeMinimum(RSSIConstants.minNumberOfVisibleXValues)
        chartView.setVisibleXRangeMaximum(RSSIConstants.maxNumberOfVisibleXValues)
        chartView.setVisibleYRangeMinimum(RSSIConstants.minNumberOfVisibleYValues, axis: .left)
        chartView.setVisibleYRangeMaximum(RSSIConstants.maxNumberOfVisibleYValues, axis: .left)

        chartView.updateXAxisGridLines()
        chartView.updateViewPosition()

        let axisMaximum = chartView.xAxis.axisMaximum
        
        rightArrowButton.isHidden = !(chartView.highestVisibleX + RSSIConstants.approximationError  < axisMaximum)
        leftArrowButton.isHidden = chartView.lowestVisibleX == chartView.xAxis.axisMinimum
        
        chartView.lineData?.notifyDataChanged()
        chartView.notifyDataSetChanged()
    }
    
    private func setupRightArrowButton() {
        addSubview(rightArrowButton)
        let arrowSystemImage = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        rightArrowButton.isHidden = true
        rightArrowButton.setImage(arrowSystemImage, for: .normal)
        rightArrowButton.tintColor = .black
        rightArrowButton.translatesAutoresizingMaskIntoConstraints = false
        rightArrowButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12).isActive = true
        rightArrowButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        
        rightArrowButton.extendLeft = RSSIConstants.extendedButtonOffset
    
        rightArrowButton.addTarget(self, action: #selector(backToCurrentPosition), for: .touchUpInside)
    }
    
    private func setupLeftArrowButton() {
        addSubview(leftArrowButton)
        let arrowSystemImage = UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysTemplate)
        leftArrowButton.isHidden = true
        leftArrowButton.setImage(arrowSystemImage, for: .normal)
        leftArrowButton.tintColor = .black
        leftArrowButton.translatesAutoresizingMaskIntoConstraints = false
        leftArrowButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 56).isActive = true
        leftArrowButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        
        leftArrowButton.extendRight = RSSIConstants.extendedButtonOffset

        leftArrowButton.addTarget(self, action: #selector(backToOriginPosition), for: .touchUpInside)
    }
    
    @objc private func backToCurrentPosition() {
        let now = Double(Date().timeIntervalSince(referenceDate))
        chartView.moveViewToX(now)
    }
    
    @objc private func backToOriginPosition() {
        chartView.moveViewToX(0.0)
    }
    
    func addOrUpdateDataForPeripheral(_ identifier: String, measurement: SILRSSIMeasurement, withColor color: UIColor) {
        let yValue = measurement.rssi.doubleValue
        let entry = ChartDataEntry(x: measurement.date.timeIntervalSince(referenceDate), y: yValue )
        
        self.maximumYValue = yValue > maximumYValue ? yValue : maximumYValue
        self.minimumYValue = yValue < minimumYValue ? yValue : minimumYValue
        if let dataSet = chartView.lineData?.dataSets.first(where: { $0.label == identifier }) as? LineChartDataSet {
            
            print(" dataSet ==== \(dataSet)")
            
            dataSet.append(entry)
        } else {
            chartView.addDataSetFor([entry], identifier: identifier, color: color)
        }
    }
}

struct RSSIConstants {
    static let axisBlack = UIColor.black
    
    static let graphLineDisabled = UIColor.lightGray
    
    static func randomColor() -> UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
    
    static let minNumberOfVisibleXValues: Double = xAxisGranularity
    static let maxNumberOfVisibleXValues: Double = 30
    static let maxNumberOfVisibleXValuesInt: Int = Int(maxNumberOfVisibleXValues)
    
    static let minNumberOfVisibleYValues: Double = 20
    static let maxNumberOfVisibleYValues: Double = 100

    static let unselectedLineWidth = 1.0
    static let selectedLineWidth = 3.0
    
    static let startYAxisMinimum = -100.0
    static let startYAxisMaximum = 0.0
    static let yAxisGranularity = 20.0
    
    static let startXAxisMinimum = 0.0
    static let startXAxisMaximum = 30.0
    static let xAxisGranularity = 5.0
    static let xAxisGranularityInt = Int(yAxisGranularity)
    
    static let approximationError: Double = 2.0
    static let extendedButtonOffset: Double = 15
}
