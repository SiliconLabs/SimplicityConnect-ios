//
//  SILRangeTestAppViewController.swift
//  SiliconLabsApp
//
//  Created by Piotr Sarna on 18.05.2018.
//  Copyright © 2018 SiliconLabs. All rights reserved.
//

import UIKit
import ActionSheetPicker_3_0
import ChameleonFramework
import Charts

fileprivate struct Constants {
    static let sliderGrey = UIColor(red:0.85, green:0.84, blue:0.84, alpha:1.00)
    static let sliderRed = UIColor(red:0.84, green:0.14, blue:0.19, alpha:1.00)
    static let sliderBlue = UIColor.sil_regularBlue()!
    
    static let buttonEnabledStopBackgroundColor = UIColor(hexString: "#D0021B")!
    static let buttonEnabledStartBackgroundColor = UIColor.sil_regularBlue()!
    static let buttonDisabledBackgroundColor = UIColor(hexString: "#CCCBCB")!
    
    static let demoName = "Range Test Demo"
    static let modePostfix = "Mode"
    
    static let textColor = UIColor(hexString: "#504E4E")!
    static let disabledBackgroundColor = UIColor(hexString: "#D5D5D5")!
    static let borderColor = UIColor(hexString: "#979797")!
    
    static let maxNumberOfVisibleXValues: Double = 75
}

@objc
@objcMembers
class SILRangeTestAppViewController: UIViewController {
    var app: SILApp!
    var viewModel: SILRangeTestAppViewModel!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet private weak var txViewContainer: UIView!
    @IBOutlet private weak var rxViewContainer: UIView!
    @IBOutlet private weak var chartView: LineChartView!
    @IBOutlet private weak var deviceNameLabel: UILabel!
    @IBOutlet private weak var modelNumberLabel: UILabel!
    @IBOutlet private weak var executeButton: SILPrimaryButton!
    @IBOutlet private weak var txPowerRowView: UIView!
    @IBOutlet weak var packetRepeatSwitch: SILSwitch!
    @IBOutlet weak var uartLogSwitch: SILSwitch!
    
    @IBOutlet private weak var rxLabel: UILabel!
    @IBOutlet private weak var txLabel: UILabel!
    @IBOutlet private weak var rssiLabel: UILabel!
    @IBOutlet private weak var maLabel: UILabel!
    @IBOutlet private weak var perLabel: UILabel!
    
    @IBOutlet private var sliders: [UISlider]!
    @IBOutlet private var valuesButtons: [UIButton]!
    @IBOutlet private var interactableViews: [UIControl]!
    @IBOutlet private var grayLabels: [UILabel]!
    
    private var rxValue: Int = 0
    private var totalRxValue: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.delegate = self
        
        setTabDeviceName()
        prepareUI()
        prepareUIValues()
        prepareUIWithPeripheral()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        if (parent == nil) {
            viewModel.peripheral.clearCallbacks()
            viewModel.peripheral.delegate = nil
            viewModel.peripheral.disconnect()
            
            UIApplication.shared.isIdleTimerDisabled = false;
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setTabDeviceName() {
        let setDeviceName = self.sil_useContext(type: SILSetTabDeviceName.self)
        setDeviceName?.invoke(viewModel.peripheral.discoveredPeripheral()?.advertisedLocalName ?? "Unknown")
    }
    
    private func prepareUI() {
        let isRxMode = viewModel.mode == .RX
        let isTxMode = viewModel.mode == .TX
        
        navigationItem.title = "\(Constants.demoName) - \(stringify(viewModel.mode)) \(Constants.modePostfix)"
        executeButton.setTitle(getTitleForExecuteButton(), for: .normal)
        
        txPowerRowView.isHidden = !isTxMode
        txViewContainer.isHidden = !isTxMode
        rxViewContainer.isHidden = !isRxMode
        
        for slider in sliders {
            slider.minimumTrackTintColor = Constants.sliderBlue
            slider.thumbTintColor = Constants.sliderBlue
        }
        
        for valueButton in valuesButtons {
            valueButton.setTitleColor(Constants.textColor, for: .normal)
            valueButton.layer.cornerRadius = 2
            valueButton.layer.borderWidth = 1
            valueButton.layer.borderColor = Constants.borderColor.cgColor
        }
        
        for grayLabel in grayLabels {
            grayLabel.textColor = Constants.textColor
        }
        
        if isRxMode {
            chartConfigure()
        }
        
        contentView.layer.cornerRadius = 16;
        contentView.layer.shadowColor = UIColor.black.cgColor;
        contentView.layer.shadowOpacity = 0.3;
        contentView.layer.shadowOffset = CGSize.zero;
        contentView.layer.shadowRadius = 2;
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        
        DispatchQueue.main.async {
            self.contentView.layer.shadowPath = UIBezierPath(roundedRect: self.contentView.bounds, cornerRadius: 16.0).cgPath
        }
    }
    
    private func prepareUIValues() {
        updated(isTestStarted: viewModel.isTestStarted)
        updated(isPacketRepeatEnabled: viewModel.isPacketRepeatEnabled)
        updated(isUartLogEnabled: viewModel.isUartLogEnabled)
        setUI(blocked: true)
        
        for setting in viewModel.getAllAvailableSettings() {
            let availableValues = viewModel.getAvailableValues(forSetting: setting)
            let slider = getSlider(forSetting: setting)
            
            slider?.minimumValue = 0
            slider?.maximumValue = Float(availableValues.count - 1)
            
            updateUI(forSetting: setting)
        }
        
        resetUIValues()
    }
    
    private func prepareUIWithPeripheral() {
        self.parse(deviceName: viewModel.boardInfo.deviceName)
        self.parse(modelNumber: viewModel.boardInfo.modelNumber)
    }
    
    private func parse(deviceName: String?) {
        if let deviceNameValue = deviceName {
            self.deviceNameLabel.text = deviceNameValue
        } else {
            self.deviceNameLabel.text = "<unknown device name>"
        }
    }

    private func parse(modelNumber: String?) {
        if let modelNumberValue = modelNumber {
            let regex = try! NSRegularExpression(pattern: "\\[.*?\\]")
            let range = NSMakeRange(0, modelNumberValue.count)
            let modelNumber = regex.stringByReplacingMatches(in: modelNumberValue, options: [], range: range, withTemplate: "")
            self.modelNumberLabel.text = modelNumber.uppercased()
        } else {
            self.modelNumberLabel.text = "<unknown model number>"
        }
    }
    
    private func updateModel(setting: SILRangeTestSetting, withValue value: Double?, shouldUpdatePeripheral: Bool = true) {
        viewModel.set(value: value, forSetting: setting)
        
        if (shouldUpdatePeripheral) {
            viewModel.updatePeripheral(forSetting: setting)
        }
    }
  
    @IBAction func valueButtonTapped(_ sender: UIButton) {
        let setting = SILRangeTestSetting(rawValue: 0x1 << sender.tag)!
        let availableValues = viewModel.getAvailableValues(forSetting: setting)
        let availableStringValues = viewModel.getAvailableStringValues(forSetting: setting)
        
        let options: [ContextMenuOption] = availableStringValues.enumerated().map { (index, value) in
            return ContextMenuOption(title: value) {
                self.updateModel(setting: setting, withValue: availableValues[index])
            }
        }
        
        SILContextMenu.present(owner: self, sourceView: sender, options: options)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        updateValueForSlider(sender, updatePeriperal: false)
    }
    
    @IBAction func sliderDidEndSliding(_ sender: UISlider) {
        updateValueForSlider(sender, updatePeriperal: true)
    }
    
    private func updateValueForSlider(_ sender: UISlider, updatePeriperal: Bool) {
        let setting = SILRangeTestSetting(rawValue: 0x1 << sender.tag)!
        let availableValues = viewModel.getAvailableValues(forSetting: setting)
        let valueIdx = Int(sender.value.rounded())
        
        updateModel(setting: setting, withValue: availableValues[valueIdx], shouldUpdatePeripheral: updatePeriperal)
    }
    
    @IBAction func switchValueChanged(_ sender: SILSwitch) {
        if sender == packetRepeatSwitch {
            viewModel.isPacketRepeatEnabled = packetRepeatSwitch.isOn
        } else if sender == uartLogSwitch {
            viewModel.isUartLogEnabled = uartLogSwitch.isOn
        }
    }
    
    @IBAction func executeButtonPressed(_ sender: UIButton) {
        viewModel.isTestStarted = !viewModel.isTestStarted
        
        if (viewModel.isTestStarted) {
            resetUIValues()
        }
    }
    
    private func updateUI(forSetting setting: SILRangeTestSetting) {
        let value = viewModel.getValue(forSetting: setting)
        let stringValue = viewModel.getStringValue(forSetting: setting)
        let availableValues = viewModel.getAvailableValues(forSetting: setting)
        
        guard let valueIdx = availableValues.index(of: value) else {
            return
        }
        
        let button = getButton(forSetting: setting)
        let slider = getSlider(forSetting: setting)
        
        let sliderMaxValue = Float(availableValues.count - 1)
        
        UIView.setAnimationsEnabled(false)
        
        if slider?.maximumValue != sliderMaxValue { slider?.maximumValue = sliderMaxValue }
        slider?.setValue(Float(valueIdx), animated: false)
        slider?.setNeedsDisplay()
        
        button?.setTitle(stringValue, for: .normal)
        button?.layoutIfNeeded()
        
        UIView.setAnimationsEnabled(true)
    }
}

// MARK: - Helper methods
extension SILRangeTestAppViewController {
    private func stringify(_ mode: SILRangeTestMode) -> String {
        switch mode {
        case .RX:
            return "RX"
        case .TX:
            return "TX"
        }
    }
    
    private func getButton(forSetting setting: SILRangeTestSetting) -> UIButton? {
        return valuesButtons.first { (0x1 << $0.tag) == setting.rawValue }
    }
    
    private func getSlider(forSetting setting: SILRangeTestSetting) -> UISlider? {
        return sliders.first { (0x1 << $0.tag) == setting.rawValue }
    }
    
    private func getTitleForExecuteButton() -> String {
        if viewModel.isTestStarted && viewModel.mode == .RX {
            return "Waiting for device..."
        }
        
        let action = viewModel.isTestStarted ? "Stop" : "Start"
        let mode = stringify(viewModel.mode)
        
        return "\(action) \(mode)"
    }
    
    private func getBackgroundColorForExecuteButton() -> UIColor {
        if viewModel.isTestStarted && viewModel.mode == .RX {
            return Constants.buttonDisabledBackgroundColor
        }
        
        return viewModel.isTestStarted ? Constants.buttonEnabledStopBackgroundColor : Constants.buttonEnabledStartBackgroundColor
    }
    
    private func readOnlySettings() -> [SILRangeTestSetting] {
        var result = [SILRangeTestSetting]()
        
        if viewModel.boardInfo.features?.isChannelNumberReadOnly ?? false {
            result.append(.channelNumber)
        }
        
        return result
    }
    
    private func setUI(blocked: Bool) {
        let readOnlyViews: [SILRangeTestSetting] = readOnlySettings()
        
        for interactableView in interactableViews {
            let isReadOnly = readOnlyViews.contains { $0.rawValue == (0x1 << interactableView.tag) }
            let isInteractable = !isReadOnly && !blocked
            
            interactableView.isEnabled = isInteractable
            
            if interactableView is UIButton {
                interactableView.backgroundColor = isInteractable ? UIColor.clear : Constants.disabledBackgroundColor
            }
            
            if interactableView is UISlider {
                interactableView.setNeedsLayout()
            }
        }
        
        if !blocked {
            updated(isPacketRepeatEnabled: viewModel.isPacketRepeatEnabled)
        }
        executeButton.setTitle(getTitleForExecuteButton(), for: .normal)
        
        let isExecuteButtonEnabled = (viewModel.mode == .TX && viewModel.isTestStarted) || !blocked
        executeButton.isEnabled = isExecuteButtonEnabled
        if isExecuteButtonEnabled {
            executeButton.backgroundColor = getBackgroundColorForExecuteButton()
        }
        view.layoutIfNeeded()
    }
    
    private func resetUIValues() {
        if viewModel.mode == .RX {
            updateLabel(rx: nil, ofTotalRx: nil)
            updateLabel(rssi: nil)
            updateLabel(ma: nil)
            updateLabel(per: nil)
            chartClear()
        } else if viewModel.mode == .TX {
            updateLabel(totalTx: nil)
        }
    }
}

// MARK: - SILRangeTestAppViewModelDelegate
extension SILRangeTestAppViewController : SILRangeTestAppViewModelDelegate {
    func didReceiveAllPeripheralValues() {
        let uiBlocked = viewModel.isTestStarted || !viewModel.didReceivedAllPeripheralValues
        
        setUI(blocked: uiBlocked)
    }
    
    func updated(setting: SILRangeTestSetting) {
        self.updateUI(forSetting: setting)
    }
    
    func updated(isTestStarted: Bool) {
        let uiBlocked = isTestStarted || !viewModel.didReceivedAllPeripheralValues
        
        setUI(blocked: uiBlocked)
        UIApplication.shared.isIdleTimerDisabled = isTestStarted
    }
    
    func updated(isPacketRepeatEnabled: Bool) {
        let isButtonEnabled = !isPacketRepeatEnabled && !viewModel.isTestStarted && viewModel.didReceivedAllPeripheralValues
        let button = getButton(forSetting: .packetCount)
        
        packetRepeatSwitch.isOn = isPacketRepeatEnabled
        button?.isEnabled = isButtonEnabled
        button?.backgroundColor = isButtonEnabled ? UIColor.clear : Constants.disabledBackgroundColor
    }
    
    func updated(isUartLogEnabled: Bool) {
        uartLogSwitch.isOn = isUartLogEnabled
    }
    
    func updated(rssi: Int) {
        guard viewModel.mode == .RX else { return }
        
        updateLabel(rssi: rssi)
        chartAdd(value: Double(rssi))
    }
    
    func updated(rx: Int, totalRx: Int, per: Float, ma: Float) {
        guard viewModel.mode == .RX else { return }
        
        if rx < self.rxValue {
            chartClear()
        }
        
        updateLabel(rx: rx, ofTotalRx: totalRx)
        updateLabel(per: per)
        updateLabel(ma: ma)
    }
    
    func updated(rx: Int) {
        guard viewModel.mode == .RX else { return }
        
        updateLabel(rx: rx)
    }
    
    func updated(totalRx: Int) {
        guard viewModel.mode == .RX else { return }
        
        updateLabel(totalRx: totalRx)
    }
    
    func updated(totalTx: Int) {
        guard viewModel.mode == .TX else { return }
        
        updateLabel(totalTx: totalTx)
    }
    
    func updated(ma: Float) {
        guard viewModel.mode == .RX else { return }
        
        updateLabel(ma: ma)
    }
    
    func updated(per: Float) {
        guard viewModel.mode == .RX else { return }
        
        updateLabel(per: per)
    }
    
    func bluetoothIsDisabled() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.rangeTest
        self.alertWithOKButton(title: bluetoothDisabledAlert.title,
                               message: bluetoothDisabledAlert.message,
                               completion: { [weak self] _ in self?.navigationController?.popToRootViewController(animated: true)
                               })
    }
}

// MARK: - Update label
extension SILRangeTestAppViewController {
    private func updateLabel(rssi: Int?) {
        if let rssiValue = rssi {
            if rssiValue > 0 {
                rssiLabel.text = String(format: "+%d dBm", rssiValue)
            } else {
                rssiLabel.text = String(format: "%d dBm", rssiValue)
            }
        } else {
            rssiLabel.text = "0 dBm"
        }
    }
    
    private func updateLabel(rx: Int?) {
        guard let rxValue = rx else { return }
        
        updateLabel(rx: rxValue, ofTotalRx: totalRxValue)
    }
    
    private func updateLabel(totalRx: Int?) {
        guard let totalRxValue = totalRx else { return }
        
        updateLabel(rx: rxValue, ofTotalRx: totalRxValue)
    }
    
    private func updateLabel(totalTx: Int?) {
        if let totalTxValue = totalTx {
            txLabel.text = String(totalTxValue)
        } else {
            txLabel.text = "0"
        }
    }
    
    private func updateLabel(rx: Int?, ofTotalRx totalRx: Int?) {
        if let rxValue = rx, let totalRxValue = totalRx {
            self.rxValue = rxValue
            self.totalRxValue = totalRxValue
            rxLabel.text = String(format: "%d/%d", rxValue, totalRxValue)
        } else {
            rxLabel.text = "0/0"
        }
    }
    
    private func updateLabel(ma: Float?) {
        if let maValue = ma {
            maLabel.text = String(format: "%.1f%%", maValue)
        } else {
            maLabel.text = "0%"
        }
    }
    
    private func updateLabel(per: Float?) {
        if let perValue = per {
            perLabel.text = String(format: "%.1f%%", perValue)
        } else {
            perLabel.text = "0%"
        }
    }
}

// MARK: - Chart configuration
extension SILRangeTestAppViewController {
    fileprivate func chartAdd(value: Double) {
        let x = Double((chartView.lineData?.dataSets.first?.entryCount)!)
        let entry = ChartDataEntry(x: x, y: value)
        
        _ = chartView.lineData?.dataSets.first?.addEntry(entry)
        
        chartView.xAxis.axisMinimum = 0
        chartView.xAxis.axisMaximum = Double(max(Constants.maxNumberOfVisibleXValues, x))
        chartView.setVisibleXRangeMinimum(Constants.maxNumberOfVisibleXValues)
        chartView.setVisibleXRangeMaximum(Constants.maxNumberOfVisibleXValues)
        chartView.moveViewToX(Double(x))
        
        chartView.lineData?.notifyDataChanged()
        chartView.notifyDataSetChanged()
    }
    
    fileprivate func chartClear() {
        chartView.lineData?.dataSets.first?.clear()
    }
    
    fileprivate func chartConfigure() {
        let dataSet = prepareDataSet()
        let chartData = prepareChartData(withDataSet: dataSet)
        
        configureChartView(withChartData: chartData)
    }
    
    private func prepareDataSet() -> LineChartDataSet {
        let dataSet = LineChartDataSet(entries: [], label: nil)
        
        dataSet.mode = .cubicBezier
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 0
        dataSet.drawFilledEnabled = true
        dataSet.fillColor = Constants.sliderBlue
        dataSet.fillAlpha = 1
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.drawVerticalHighlightIndicatorEnabled = false
        dataSet.fillFormatter = CubicLineSampleFillFormatter()
        
        return dataSet
    }
    
    private func prepareChartData(withDataSet dataSet: LineChartDataSet) -> LineChartData {
        let chartData = LineChartData(dataSet: dataSet)
        
        chartData.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 9)!)
        chartData.setDrawValues(false)
        
        return chartData
    }
    
    private func configureChartView(withChartData chartData: LineChartData) {
        chartView.chartDescription?.enabled = false
        chartView.legend.enabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.setVisibleXRangeMinimum(Constants.maxNumberOfVisibleXValues)
        chartView.setVisibleXRangeMaximum(Constants.maxNumberOfVisibleXValues)
        chartView.highlightPerTapEnabled = false
        chartView.highlightPerDragEnabled = false
        chartView.rightAxis.enabled = false
        chartView.leftAxis.valueFormatter = YAxisValueFormatter()
        chartView.leftAxis.axisMinimum = -100
        chartView.leftAxis.axisMaximum = 25
        chartView.leftAxis.granularity = 25
        chartView.leftAxis.drawGridLinesEnabled = false
        chartView.leftAxis.drawAxisLineEnabled = false
        chartView.leftYAxisRenderer = RangeTestYAxisRenderer(viewPortHandler: chartView.leftYAxisRenderer.viewPortHandler,
                                                             yAxis: chartView.leftAxis,
                                                             transformer: chartView.leftYAxisRenderer.transformer)
        chartView.xAxis.valueFormatter = XAxisValueFormatter()
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxisRenderer = RangeTestXAxisRenderer(viewPortHandler: chartView.xAxisRenderer.viewPortHandler,
                                                         xAxis: chartView.xAxis,
                                                         transformer: chartView.xAxisRenderer.transformer)
        chartView.minOffset = 0
        chartView.extraTopOffset = -10
        chartView.extraLeftOffset = -5
        chartView.extraBottomOffset = 13
        chartView.extraRightOffset = 0
        
        addChartLines(withColor: chartData.dataSets[0].valueTextColor)
        
        chartView.data = chartData
    }
    
    private func addChartLines(withColor color: UIColor) {
        let axisLine = createAxisLine(withColor: color)
        
        chartView.leftAxis.addLimitLine(axisLine)
        chartView.xAxis.addLimitLine(axisLine)
        
        for i in stride(from: chartView.leftAxis.axisMinimum, through: chartView.leftAxis.axisMaximum, by: chartView.leftAxis.granularity) {
            guard i != 0 else { continue }
            
            let gridLine = createGridLine(withColor: color, andPosition: i)
            
            chartView.leftAxis.addLimitLine(gridLine)
        }
    }
    
    private func createAxisLine(withColor color: UIColor) -> ChartLimitLine {
        let axisLine = ChartLimitLine(limit: 0, label: "")
        
        axisLine.lineColor = color
        axisLine.lineWidth = 1
        
        return axisLine
    }
    
    private func createGridLine(withColor color: UIColor, andPosition position: Double) -> ChartLimitLine {
        let gridLine = ChartLimitLine(limit: position, label: "")
        
        gridLine.lineColor = color
        gridLine.lineWidth = 1
        gridLine.lineDashPhase = 5
        gridLine.lineDashLengths = [3]
        
        return gridLine
    }
    
    private class CubicLineSampleFillFormatter: IFillFormatter {
        func getFillLinePosition(dataSet: ILineChartDataSet, dataProvider: LineChartDataProvider) -> CGFloat {
            return -100
        }
    }
    
    private class YAxisValueFormatter: IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let sign = value > 0 ? "+" : ""
            return String(format: "%@%g.0 dBm", sign, value)
        }
    }
    
    private class XAxisValueFormatter: IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return ""
        }
    }
    
    private class RangeTestXAxisRenderer : XAxisRenderer {
        private var initialPosition: CGPoint?
        
        override init(viewPortHandler: ViewPortHandler, xAxis: XAxis?, transformer: Transformer?) {
            super.init(viewPortHandler: viewPortHandler, xAxis: xAxis, transformer: transformer)
        }
        
        override func renderLimitLineLine(context: CGContext, limitLine: ChartLimitLine, position: CGPoint) {
            if initialPosition == nil {
                initialPosition = position
            }
            
            let linePosition = initialPosition!
            
            super.renderLimitLineLine(context: context, limitLine: limitLine, position: linePosition)
            
            let arrowWidth = CGFloat(6)
            let arrowHeight = CGFloat(7)
            
            var newClippingRect = viewPortHandler.contentRect
            newClippingRect.origin.x -= arrowWidth/2
            newClippingRect.size.width += arrowWidth
            newClippingRect.origin.y -= arrowHeight/2
            newClippingRect.size.height += arrowHeight
            context.resetClip()
            context.clip(to: newClippingRect)
            
            context.beginPath()
            context.move(to: CGPoint(x: linePosition.x - arrowWidth/2, y: viewPortHandler.contentTop + arrowHeight/2))
            context.addLine(to: CGPoint(x: linePosition.x + arrowWidth/2, y: viewPortHandler.contentTop + arrowHeight/2))
            context.addLine(to: CGPoint(x: linePosition.x, y: viewPortHandler.contentTop - arrowHeight/2))
            context.closePath()

            context.setFillColor(limitLine.lineColor.cgColor)
            context.fillPath()
        }
    }
    
    private class RangeTestYAxisRenderer : YAxisRenderer {
        private let arrowWidth = CGFloat(6)
        private let arrowHeight = CGFloat(7)
        
        override init(viewPortHandler: ViewPortHandler, yAxis: YAxis?, transformer: Transformer?) {
            super.init(viewPortHandler: viewPortHandler, yAxis: yAxis, transformer: transformer)
        }
        
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
                drawArrow(forLimitLine: limitLine, inContext: context, onPosition: position)
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
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight + (limitLine.limit != 0 ? 0 : -arrowHeight), y: position.y))
            
            context.setStrokeColor(limitLine.lineColor.cgColor)
            context.setLineWidth(limitLine.lineWidth)
            
            if limitLine.lineDashLengths != nil {
                context.setLineDash(phase: limitLine.lineDashPhase, lengths: limitLine.lineDashLengths!)
            } else {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            context.strokePath()
        }
        
        private func drawArrow(forLimitLine limitLine: ChartLimitLine, inContext context: CGContext, onPosition position: CGPoint) {
            guard limitLine.limit == 0 else { return }
            
            var clippingRect = viewPortHandler.contentRect
            clippingRect.origin.y -= arrowWidth/2
            clippingRect.size.height += arrowWidth
            context.resetClip()
            context.clip(to: clippingRect)
            
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentRight - arrowHeight, y: position.y - arrowWidth/2))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight - arrowHeight, y: position.y + arrowWidth/2))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
            context.closePath()
            
            context.setFillColor(limitLine.lineColor.cgColor)
            context.fillPath()
        }
    }
}
