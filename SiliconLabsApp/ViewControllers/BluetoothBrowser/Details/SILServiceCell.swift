//
//  SILServiceCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@objcMembers
@IBDesignable
class SILServiceCell: SILCell, SILMapCellProtocol {
    
    @IBOutlet weak var serviceNameLabel: UILabel!
    @IBOutlet weak var serviceUuidLabel: UILabel!
    @IBOutlet weak var moreInfoButton: UIButton!
    @IBOutlet weak var nameEditButton: UIButton!
    @IBOutlet weak var affordanceImage: UIImageView!
    @IBOutlet weak var dividerView: UIView!
    
    @objc weak var delegate: SILMapCellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addGestureRecognizerForServiceNameLabel()
    }
    
    override func prepareForReuse() {
        serviceNameLabel.text = ""
        serviceUuidLabel.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func addGestureRecognizerForServiceNameLabel() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(serviceNameLabelWasTapped))
        self.serviceNameLabel.isUserInteractionEnabled = true
        self.serviceNameLabel.addGestureRecognizer(tap)
    }

    @IBAction func moreInfo(_ sender: UIButton) {
        if let delegate = self.delegate as? SILServiceCellDelegate {
            delegate.showMoreInfoForCell(self)
        }
    }
    
    @objc
    func configureAsExpandanble(_ canExpand: Bool) {
        self.moreInfoButton.isHidden = !canExpand
        self.affordanceImage.isHidden = !canExpand
        self.dividerView.isHidden = !canExpand
    }
    
    @objc
    func expandIfAllowed(_ isExpanding: Bool) {
        customizeMoreInfoText(isExpanding)
        customizeArrow(isExpanding)
    }
    
    @IBAction func editName(_ sender: UIButton) {
        delegate.editName(cell: self)
    }
    
    @objc func serviceNameLabelWasTapped() {
        if !nameEditButton.isHidden {
            delegate.editName(cell: self)
        }
    }
    
    internal func customizeMoreInfoText(_ isExpanding: Bool) {
        if isExpanding {
            moreInfoButton.setTitle("Less Info", for: .normal)
        } else {
            moreInfoButton.setTitle("More Info", for: .normal)
        }
    }
    
    internal func customizeArrow(_ isExpanding: Bool) {
        if isExpanding {
            affordanceImage.image = UIImage(named: "chevron_expanded")
        } else {
            affordanceImage.image = UIImage(named: "chevron_collapsed")
        }
    }
}

@objc
protocol SILServiceCellDelegate: SILMapCellDelegate {
    @objc
    func showMoreInfoForCell(_ cell:SILServiceCell)
}
