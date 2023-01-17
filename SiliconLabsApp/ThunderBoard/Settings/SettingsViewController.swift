//
//  SettingsViewController.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, SILAppSelectionHelpViewControllerDelegate, WYPopoverControllerDelegate {
    
    fileprivate enum Sections: Int {
        case preferences
    }

    @IBOutlet weak var measurementsLabel: StyledLabel!
    @IBOutlet weak var measurementsControl: UISegmentedControl!
    
    @IBOutlet weak var temperatureLabel: StyledLabel!
    @IBOutlet weak var temperatureControl: UISegmentedControl!
    
    @IBOutlet weak var motionModelLabel: StyledLabel!
    @IBOutlet weak var motionModelControl: UISegmentedControl!
    
    weak var popoverController: WYPopoverController!
    
    fileprivate let settings = ThunderboardSettings()
    fileprivate let preferencesTitleText         = "PREFERENCES"
    fileprivate let temperatureLabelText         = "Temperature"

    override func viewDidLoad() {
        setupAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateTemperatureControl()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let cell = cell as? SettingsViewCell else {
            fatalError("settings table cell subclass should be used")
        }
        
        cell.backgroundColor = StyleColor.white
        
        if tableView.tb_isLastCell(indexPath) {
            cell.drawBottomSeparator = false
            cell.tb_applyCommonDropShadow()
        }
        else {
            cell.drawBottomSeparator = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 54
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UITableViewHeaderFooterView()
        let contentView = headerView.contentView
        
        contentView.backgroundColor = StyleColor.lightGray

        setupSectionTitle(preferencesTitleText, contentView: contentView)
        
        return headerView
    }
    
    fileprivate func setupSectionTitle(_ title: String, contentView: UIView) {
        let titleView = StyledLabel()
        contentView.addSubview(titleView)
        titleView.tb_setText(title, style: StyleText.header)
        
        titleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraint(NSLayoutConstraint(
            item: titleView,
            attribute: .top,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .top,
            multiplier: 1,
            constant: 18)
        )
        contentView.addConstraint(NSLayoutConstraint(
            item: titleView,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .bottom,
            multiplier: 1,
            constant: -10)
        )
        contentView.addConstraint(NSLayoutConstraint(
            item: titleView,
            attribute: .leading,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .leading,
            multiplier: 1,
            constant: 15)
        )
    }
   
    // MARK: SILAppSelectionHelpViewControllerDelegate
    
    func didFinishHelp(with helpViewController: SILAppSelectionHelpViewController!) {
        self.dismiss(animated: true) {
            
        }
    }
    
    // MARK: WYPopoverControllerDelegate
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        self.popoverController.dismissPopover(animated: true, completion: nil)
        self.popoverController = nil
    }
    
    //MARK: action handlers
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    static let temperatureSettingUpdated = NSNotification.Name("temperatureSettingUpdated")
    
    @IBAction func temperatureDidChange(_ sender: UISegmentedControl) {
        var newTemperatureUnits: TemperatureUnits!
        switch temperatureControl.selectedSegmentIndex {
        case 0:
            newTemperatureUnits = .celsius
        case 1:
            newTemperatureUnits = .fahrenheit
        default:
            fatalError("Unsupported segment selected")
        }
        settings.temperature = newTemperatureUnits
        NotificationCenter.default.post(name: SettingsViewController.temperatureSettingUpdated, object: nil)
    }
    
    // Private
    
    fileprivate func setupAppearance() {
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = 42
        
        tableView.contentInsetAdjustmentBehavior = .automatic
        view.backgroundColor = StyleColor.lightGray
        tableView?.backgroundColor = StyleColor.lightGray

        temperatureLabel.tb_setText(temperatureLabelText, style: StyleText.main1)
    }
    
    fileprivate func updateTemperatureControl() {
        let temperatureUnits = settings.temperature
        switch temperatureUnits {
        case .celsius:
            temperatureControl.selectedSegmentIndex = 0
        case .fahrenheit:
            temperatureControl.selectedSegmentIndex = 1
        }
    }
    
}
