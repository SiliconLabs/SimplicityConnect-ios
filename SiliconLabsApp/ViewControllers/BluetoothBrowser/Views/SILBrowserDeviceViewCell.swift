//
//  SILBrowserDeviceViewCellTableViewCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
@objcMembers
class SILBrowserDeviceViewCell: SILCell, SILConfigurableCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var favouritesButton: UIButton?
    @IBOutlet weak var connectButton: SILBrowserButton!
    @IBOutlet weak var btImageView: UIImageView!
    @IBOutlet weak var wifiImageView: UIImageView!
    @IBOutlet weak var beaconImageView: UIImageView!
    @IBOutlet weak var connectableLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var beaconLabel: UILabel!
    @IBOutlet weak var connectingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var advertisingIntervalLabel: UILabel!
    @IBOutlet weak var affordanceImage: UIImageView?
    
    weak var delegate: SILBrowserDeviceViewCellDelegate?
    var viewModel : SILDiscoveredPeripheralDisplayDataViewModel? 
    
    override func awakeFromNib() {
        super.awakeFromNib()
        connectingIndicator.isHidden = true
        setAppearanceForConnectButton(connected: false, connectable: false)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        viewModel = nil
    }
    
    private func configureExpandedArrow(_ isExpanded: Bool) {
        let imageName = isExpanded ? "chevron.up" : "chevron.down"
        affordanceImage?.image = UIImage(systemName: imageName)
    }
    
    @IBAction func favourite(_ sender: UIButton) {
        self.delegate?.favouriteButtonTappedInCell(self)
    }
    
    @IBAction func connect(_ sender: SILBrowserButton) {
        self.delegate?.connectButtonTappedInCell(self)
    }
    
    private func setAppearanceForConnectButton(connected : Bool, connectable: Bool) {
        connectButton.isHidden = !connectable
        connectButton.setTitle(!connected ? "Connect" : "Disconnect", for: .normal)
        connectButton.backgroundColor = !connected ? .sil_regularBlue() : .sil_siliconLabsRed()
    }
    
    func configure() {
        guard let discoveredPeripheral = viewModel?.discoveredPeripheral else { return }
        
        configureLabels(discoveredPeripheral)
        configureButtons(discoveredPeripheral)
        configureExpandedArrow(viewModel?.isExpanded ?? false)
        configureConnectingIndicator()
    }
    
    fileprivate func configureConnectingIndicator() {
        connectingIndicator.isHidden = viewModel?.isConnecting != true
        if viewModel?.isConnecting == true {
            connectingIndicator.startAnimating()
        } else {
            connectingIndicator.stopAnimating()
        }
    }
    
    fileprivate func configureLabels(_ discoveredPeripheral: SILDiscoveredPeripheral) {
        let deviceName = discoveredPeripheral.advertisedLocalName
        let advertisingIntervalsInMS = discoveredPeripheral.advertisingInterval * 1000;
        
        advertisingIntervalLabel.text = "\(advertisingIntervalsInMS.rounded()) ms"
        rssiLabel.text = discoveredPeripheral.rssiDescription()
        beaconLabel.text = discoveredPeripheral.beacon.name
        title.text = deviceName?.isEmpty == false ? deviceName : DefaultDeviceName
        connectableLabel.text = discoveredPeripheral.isConnectable ? SILDiscoveredPeripheralConnectableDevice : SILDiscoveredPeripheralNonConnectableDevice
    }
    
    fileprivate func configureButtons(_ discoveredPeripheral: SILDiscoveredPeripheral) {
        let isConnected = SILBrowserConnectionsViewModel.sharedInstance().isConnectedPeripheral(discoveredPeripheral.peripheral)
        favouritesButton?.isSelected = discoveredPeripheral.isFavourite
        setAppearanceForConnectButton(connected: isConnected, connectable: discoveredPeripheral.isConnectable && !discoveredPeripheral.hasTimedOut)
    }
}
