//
//  SILESLDemoTagCell.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 27.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import UIKit
import WYPopoverController

class SILESLDemoTagCell: UITableViewCell, SILCellView {
    @IBOutlet weak var btAddressLabel: UILabel!
    @IBOutlet weak var eslIdLabel: UILabel!
    @IBOutlet weak var pingButton: UIButton!
    @IBOutlet weak var ledButton: UIButton!
    @IBOutlet weak var imageUpdateButton: UIButton!
    @IBOutlet weak var displayImageButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var chevronButton: UIButton!
    weak var hostingViewController: SILESLDemoViewController?
    
    var viewModel: SILESLDemoTagViewModel? {
        didSet {
            configure()
        }
    }

    override func prepareForReuse() {
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        self.viewModel = viewModel as? SILESLDemoTagViewModel
    }
    
    private func configure() {
        if let viewModel = viewModel {
            btAddressLabel.text = viewModel.btAddress.address
            eslIdLabel.text = "ESL ID: \(viewModel.elsId.rawValue)"
            pingButton.imageView?.tintColor = UIColor.black
            ledButton.imageView?.tintColor = viewModel.isOnLed ? UIColor.sil_regularBlue() : UIColor.black
            imageUpdateButton.imageView?.tintColor = UIColor.black
            displayImageButton.imageView?.tintColor = UIColor.black
            deleteButton.imageView?.tintColor = UIColor.black
            setImageForChevron()
        }
    }
    
    private func setImageForChevron() {
        if viewModel!.isExpanded {
            chevronButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        } else {
            chevronButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        }
    }
    
    @IBAction func pingButtonWasTapped(_ sender: Any) {
        if let viewModel = viewModel {
            viewModel.onTapPingButton()
        }
    }
    
    @IBAction func ledButtonWasTapped(_ sender: Any) {
        if let viewModel = viewModel {
            viewModel.onTapLedButton(!viewModel.isOnLed ? .on : .off)
        }
    }
    
    @IBAction func updateImageButtonWasTapped(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        let imageUpdatePopup = SILESLImageUpdatePopup()
        let imageUpdateViewModel = SILESLImageUpdatePopupViewModel(maxImageIndex: viewModel.maxImageIndex,
                                                                   imageSlot0: viewModel.knownImages[0],
                                                                   imageSlot1: viewModel.knownImages[1],
                                                                   onCancel: { [weak self] in
            guard let self = self else { return }
            self.hostingViewController?.popover?.dismissPopover(animated: true)
        },
                                                                   onImageUpdate: { [weak self] imageIndex, url, showImageAfterUpdate in
            guard let self = self else { return }
            self.viewModel?.onTapImageUpdateButton(imageIndex, url, showImageAfterUpdate)
            self.hostingViewController?.popover?.dismissPopover(animated: true)
        })
        
        imageUpdatePopup.viewModel = imageUpdateViewModel
        
        if let hostingViewController = hostingViewController {
            hostingViewController.popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: imageUpdatePopup,
                                                                                         presenting: hostingViewController,
                                                                                         delegate: hostingViewController,
                                                                                         animated: true)
        }
    }
    
    @IBAction func displayImageButtonWasTapped(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        let displayImagePopup = SILESLDisplayImagePopup()
        let displayImageViewModel = SILESLDisplayImagePopupViewModel(maxImageIndex: viewModel.maxImageIndex,
                                                                     imageSlot0: viewModel.knownImages[0],
                                                                     imageSlot1: viewModel.knownImages[1],
                                                                     onCancel: { [weak self] in
            guard let self = self else { return }
            self.hostingViewController?.popover?.dismissPopover(animated: true)
        },
                                                                     onDisplayImage: { [weak self] index in
            guard let self = self else { return }
            self.viewModel?.onTapDisplayImageButton(index)
            self.hostingViewController?.popover?.dismissPopover(animated: true)
        })
        
        displayImagePopup.viewModel = displayImageViewModel
        
        if let hostingViewController = hostingViewController {
            hostingViewController.popover = WYPopoverController.sil_presentCenterPopover(withContentViewController: displayImagePopup,
                                                                                         presenting: hostingViewController,
                                                                                         delegate: hostingViewController,
                                                                                         animated: true)
        }
    }
    
    @IBAction func deleteButtonWasTapepd(_ sender: Any) {
        viewModel?.onTapDeleteButton()
    }
}
