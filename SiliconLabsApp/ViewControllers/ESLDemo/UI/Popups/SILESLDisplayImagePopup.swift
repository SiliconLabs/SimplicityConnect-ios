//
//  SILESLDisplayImagePopup.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 30.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import UIKit

class SILESLDisplayImagePopup: UIViewController {
    @IBOutlet weak var displayButton: UIButton!
    @IBOutlet weak var slot0ImageView: UIImageView!
    @IBOutlet weak var slot1ImageView: UIImageView!
    var viewModel: SILESLDisplayImagePopupViewModel!
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 350, height: 400)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let tapSlot0 = UITapGestureRecognizer(target: self, action: #selector(slot0WasTapped))
        slot0ImageView.addGestureRecognizer(tapSlot0)
        let tapSlot1 = UITapGestureRecognizer(target: self, action: #selector(slot1WasTapped))
        slot1ImageView.addGestureRecognizer(tapSlot1)
        slot0ImageView.layer.borderColor = UIColor.sil_regularBlue().cgColor
        slot0ImageView.layer.masksToBounds = true
        slot0ImageView.contentMode = .scaleToFill
        
        if viewModel.maxImageIndex == 1 {
            slot1ImageView.layer.borderColor = UIColor.sil_regularBlue().cgColor
            slot1ImageView.layer.masksToBounds = true
            slot1ImageView.contentMode = .scaleToFill
        }
        
        showAvailableImages()
        setSelectedImage()
    }
    
    @objc func slot0WasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        viewModel.selectedImageIndex = 0
        setSelectedImage()
    }
    
    @objc func slot1WasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        viewModel.selectedImageIndex = 1
        setSelectedImage()
    }
    
    @IBAction func cancelButtonWasTapped(_ sender: Any) {
        viewModel.onCancel()
    }
    
    @IBAction func displayButtonWasTapped(_ sender: Any) {
        viewModel.onDisplayImage(viewModel.selectedImageIndex)
    }
    
    private func showAvailableImages() {
        if viewModel.maxImageIndex == 0 {
            slot1ImageView.isHidden = true
            
            if let imageSlot0 = viewModel.imageSlot0, let data = try? Data(contentsOf: imageSlot0) {
                slot0ImageView.image = UIImage(data: data)
            }
        } else {
            if let imageSlot0 = viewModel.imageSlot0, let data = try? Data(contentsOf: imageSlot0) {
                slot0ImageView.image = UIImage(data: data)
            }
            
            if let imageSlot1 = viewModel.imageSlot1, let data = try? Data(contentsOf: imageSlot1) {
                slot1ImageView.image = UIImage(data: data)
            }
        }
    }
    
    private func setSelectedImage() {
        if viewModel.selectedImageIndex == 0 {
            slot0ImageView.layer.borderWidth = 5
            slot1ImageView.layer.borderWidth = 0
        } else {
            slot1ImageView.layer.borderWidth = 5
            slot0ImageView.layer.borderWidth = 0
        }
    }
}
