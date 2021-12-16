//
//  IODemoViewController.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

@IBDesignable
class IoDemoViewController: DemoViewController, IoDemoInteractionOutput, ConnectedDeviceDelegate,
                            SILThunderboardConnectedDeviceBar {

    var connectedDeviceView: ConnectedDeviceBarView?
    var connectedDeviceBarHeight: CGFloat = 70.0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var navigationBar: UIView!
    
    @IBOutlet weak var colorSlider: UISlider?
    @IBOutlet weak var brightnessSlider: UISlider?
    
    @IBOutlet weak var tableLeftInset: NSLayoutConstraint!
    @IBOutlet weak var tableRightInset: NSLayoutConstraint!
    
    let tableInset: CGFloat = 16.0
    
    let onString         = "ON"
    let offString        = "OFF"
    let colorString      = "COLOR"
    let brightnessString = "BRIGHTNESS"
    let switchesString   = "SWITCHES"
    let lightsString     = "LIGHTS"

    
    let rgbLEDPositionNo = 2
    let switchMaxNo = 2

    var interaction: IoDemoInteraction?
    var deviceConnector: DeviceConnection?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        interaction?.updateView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if showRGB {
            interaction?.toggleLed(2)
        }
        showRGB = false
        deviceConnector?.disconnectAllDevices()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        interaction?.turnOffLed(0)
        interaction?.turnOffLed(1)
        interaction?.turnOffLed(2)
        tableView.reloadData()
        let cell: LightsCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! LightsCell
        cell.lights[0].isOn = false
        cell.lights[1].isOn = false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    func setupTableView() {
        if #available(iOS 13, *) {
            tableView.separatorStyle = .none;
        } else {
            tableLeftInset.constant = tableInset;
            tableRightInset.constant = tableInset;
        }
    }
    
    //MARK: - Actions
    @IBAction func lightsSwitched(_ sender: UISwitch) {
        self.interaction?.toggleLed(sender.tag)
    }
    
    var showRGB: Bool = false
    
    @IBAction func showRGB(_ sender: UISwitch) {
        interaction?.toggleLed(2)
        showRGB = sender.isOn
        tableView.reloadData()
    }
    
    @IBAction func colorSliderChanged(_ sender: UISlider) {
        guard let color = colorForSliderValues() else {
            return
        }
        
        interaction?.setColor(2, color: color)
    }
    
    @IBAction func brightnessSliderChanged(_ sender: UISlider) {
        guard let color = colorForSliderValues(   ) else {
            return
        }
        
        interaction?.setColor(2, color: color)
    }
    
    @IBAction func backButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - IoDemoInteractionOutput
    
    func showButtonState(_ button: Int, pressed: Bool) {
        
        if let cell: SwitchStatusCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SwitchStatusCell {
            if let switchView: SwitchView = cell.switches?[button] {
                switchView.switchStatus = pressed ? .on : .off
            }
        }
    }
    
    func showLedState(_ led: Int, state: LedState) {
        
        switch state {
        case .digital(let on, let color):
            showDigital(led, on: on, color: color)
        case .rgb(let on, let color):
            showRgbState(on, color: color)
        }
    }
    
    fileprivate func showDigital(_ index: Int, on: Bool, color: LedStaticColor? = nil) {
        log.debug("showLedState \(index) \(on)")
    }
    
    fileprivate func showRgbState(_ on: Bool, color: LedRgb) {
        let color = color.uiColor
        var brightness: CGFloat = 0.0
        var hue: CGFloat = 0.0
        color.getHue(&hue, saturation: nil, brightness: &brightness, alpha: nil)
        let imageColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: brightness)
        guard let cell: StrengthCell = tableView.cellForRow(at: IndexPath(row: 1, section: 2)) as? StrengthCell else { return }
        cell.barView.color = on ? imageColor : StyleColor.gray
    }
    
    var rgbEnabled = true
    
    func disableRgb() {
        rgbEnabled = false
        self.tableView.reloadData()
    }
    
    var ledOn: Bool = true
    var ledNo: Int = 0
    
    func enable(_ enable: Bool, led ledNo: Int) {
        self.ledOn = enable
        self.ledNo = ledNo
    }
    
    var switchOn: Bool = true
    var switchNo: Int = 0
    
    func enable(_ enable: Bool, switch switchNo: Int) {
        self.switchOn = enable
        self.switchNo = switchNo
    }

    //MARK: - Internal
    
    fileprivate func colorForSliderValues() -> LedRgb? {
        guard let colorCell: ColorCell = tableView?.cellForRow(at: IndexPath(row: 2, section: 2)) as? ColorCell else { return  nil}
        guard let brightnessCell: BrightnessCell = tableView?.cellForRow(at: IndexPath(row: 3, section: 2)) as? BrightnessCell else { return nil }
        guard let hue = colorCell.colorSlider?.value, let brightness = brightnessCell.slider?.value else { return nil }
        
        let color = UIColor(hue: CGFloat(hue), saturation: 1.0, brightness: CGFloat(brightness), alpha: 1.0)
        var r = CGFloat(0)
        var g = CGFloat(0)
        var b = CGFloat(0)
        
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        
        return LedRgb(red: Float(r), green: Float(g), blue: Float(b))
    }
    
    @objc @IBAction func brightnessSliderTapped(_ recognizer: UITapGestureRecognizer) {
        brightnessSlider?.tb_updateSliderValueWithTap(recognizer)
    }
    
    @objc @IBAction func colorSliderTapped(_ recognizer: UITapGestureRecognizer) {
        colorSlider?.tb_updateSliderValueWithTap(recognizer)
    }
}

extension LedRgb {
    var uiColor: UIColor {
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
}

extension UISlider {
    @IBAction func tb_updateSliderValueWithTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        self.value = Float(point.x / self.frame.size.width)
        self.sendActions(for: UIControl.Event.valueChanged)
    }
}

extension IoDemoViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if rgbEnabled {
            return 3
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 4
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell: SwitchStatusCell = tableView.dequeueReusableCell(withIdentifier: "SwitchStatusCell", for: indexPath) as! SwitchStatusCell
                for switchView in cell.switches {
                    switchView.isHidden = true
                }
                if switchNo == 0 {
                    cell.switches[0].isHidden = false
                    cell.switches[1].removeFromSuperview()
                    cell.switchConstraint.constant = 27.0
                } else {
                    for switchView in cell.switches {
                        switchView.isHidden = false
                    }
                }
                return cell
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                let cell: LightsCell = tableView.dequeueReusableCell(withIdentifier: "LightsCell", for: indexPath) as! LightsCell
                cell.titleLabel.text = NSLocalizedString("led", comment: "")
                for led in cell.lights {
                    led.isHidden = true
                }
                if ledNo == 0 {
                    cell.lights[0].isHidden = false
                    cell.lights[0].tag = 0
                } else {
                    for led in cell.lights {
                        led.isHidden = false
                    }
                    cell.titleLabel.text = NSLocalizedString("leds", comment: "")
                }
                return cell
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                let cell: RGBCell = tableView.dequeueReusableCell(withIdentifier: "RGBCell", for: indexPath) as! RGBCell
                cell.titleLabel.text = NSLocalizedString("rgb_leds", comment: "")
                cell.lightSwitch.isOn = showRGB
                cell.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
                return cell
            case 1:
                let cell: StrengthCell = tableView.dequeueReusableCell(withIdentifier: "StrengthCell", for: indexPath) as! StrengthCell
                cell.barView.isUserInteractionEnabled = showRGB
                return cell
            case 2:
                let cell: ColorCell = tableView.dequeueReusableCell(withIdentifier: "ColorCell", for: indexPath) as! ColorCell
                cell.colorSlider.isEnabled = showRGB
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.colorSliderChanged(cell.colorSlider)
                }
                return cell
            case 3:
                let cell: BrightnessCell = tableView.dequeueReusableCell(withIdentifier: "BrightnessCell", for: indexPath) as! BrightnessCell
                cell.slider.isEnabled = showRGB
                cell.layer.maskedCorners = [.layerMinXMaxYCorner,.layerMaxXMaxYCorner]
                return cell
            default:
                break
            }
        default:
            break
        }
        return tableView.dequeueReusableCell(withIdentifier: "BlankCell", for: indexPath)
    }
}

extension IoDemoViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 85
        case 1:
            return 64
        case 2:
            switch indexPath.row {
            case 0:
                return 64
            case 1:
                return 64
            case 2:
                return 70
            case 3:
                return 90
            default:
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
      }
}
