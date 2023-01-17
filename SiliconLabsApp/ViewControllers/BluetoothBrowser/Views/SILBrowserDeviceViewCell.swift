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
class SILBrowserDeviceViewCell: SILCell {
    
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
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var advertisingIntervalLabel: UILabel!
    @IBOutlet weak var connectButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var disconnectButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var hiddenButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var affordanceImage: UIImageView?
    
    weak var delegate: SILBrowserDeviceViewCellDelegate!
    var cellIdentifier: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        connectingIndicator.isHidden = true
        setHiddenButtonAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setExpanded(false)
        title.text = ""
        favouritesButton?.isHighlighted = false
        favouritesButton?.isSelected = false
        connectButton.isHighlighted = false
        connectButton.isSelected = false
        connectButton.isHidden = false
        connectableLabel.text = ""
        rssiLabel.text = ""
        beaconLabel.text = ""
        uuidLabel.text = ""
        advertisingIntervalLabel.text = "0 ms"
        connectingIndicator.isHidden = true
        connectButton.isHidden = false
        setHiddenButtonAppearance()
        cellIdentifier = nil
        delegate = nil
    }
    
    func setExpanded(_ isExpanded: Bool) {
        if isExpanded {
            affordanceImage?.image = UIImage(systemName: "chevron.up")
        } else {
            affordanceImage?.image = UIImage(systemName: "chevron.down")
        }
    }
    
    @IBAction func favourite(_ sender: UIButton) {
        self.delegate?.favouriteButtonTappedInCell(self)
    }
    
    @IBAction func connect(_ sender: SILBrowserButton) {
        self.delegate?.connectButtonTappedInCell(self)
    }
    
    internal func setDisconnectButtonAppearance() {
        setConstraintsForDisconnectButton()
        connectButton.isHidden = false
        connectButton.setTitle("Disconnect", for: .normal)
        connectButton.backgroundColor = UIColor.sil_siliconLabsRed()
        self.contentView.setNeedsUpdateConstraints()
    }
    
    private func setConstraintsForDisconnectButton() {
        NSLayoutConstraint.deactivate([connectButtonWidth, hiddenButtonWidth])
        NSLayoutConstraint.activate([disconnectButtonWidth])
    }
    
    internal func setConnectButtonAppearance() {
        setConstraintsForConnectButton()
        connectButton.isHidden = false
        connectButton.setTitle("Connect", for: .normal)
        connectButton.backgroundColor = UIColor.sil_regularBlue()
        self.contentView.setNeedsUpdateConstraints()
    }
    
    private func setConstraintsForConnectButton() {
        NSLayoutConstraint.deactivate([disconnectButtonWidth, hiddenButtonWidth])
        NSLayoutConstraint.activate([connectButtonWidth])
    }
    
    internal func setHiddenButtonAppearance() {
        connectButton.isHidden = true
        NSLayoutConstraint.deactivate([connectButtonWidth, disconnectButtonWidth])
        NSLayoutConstraint.activate([hiddenButtonWidth])
        self.contentView.setNeedsUpdateConstraints()
    }
}
