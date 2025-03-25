//
//  SILESLImageUpdatePopup.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 30.3.2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import UIKit

class SILESLImageUpdatePopup: UIViewController, UIDocumentPickerDelegate {
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var slot0ImageView: UIImageView!
    @IBOutlet weak var slot1ImageView: UIImageView!
    @IBOutlet weak var showImageAfterUpdateButton: UIButton!
    @IBOutlet weak var notesLabel: UILabel!
    private let selectedImage = UIImage(named: "checkBoxActive")
    private let deselectedImage = UIImage(named: "checkBoxInactive")
    var viewModel: SILESLImageUpdatePopupViewModel!
    var sizeOfImage0: Double = 0.0
    var sizeOfImage1: Double = 0.0
    
    private var msgText = "The selected image exceeds 100 KB, which may result in a longer upload time. Do you want to proceed with the upload?"
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 350, height: 480)
            } else {
                return CGSize(width: 350, height: 450)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    private let notesText = """
Notes: The recommended image size is below 100KB.
Presented image info may be outdated if you controlled ESL Access Point outside of the app (e.g. through Command Line Interface).
"""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notesLabel.text = notesText
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
        setSelectedImage()
        showAvailableImages()
        setImagesForSelectionCheckbox()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cleanUpIfNoContinuationTapped()
        super.viewWillDisappear(animated)
    }
    
    private func cleanUpIfNoContinuationTapped() {
        if !viewModel.wasTapContinuation {
            viewModel.onCancel()
        }
    }
    
    private func setImagesForSelectionCheckbox() {
        showImageAfterUpdateButton.setImage(selectedImage, for: .selected)
        showImageAfterUpdateButton.setImage(deselectedImage, for: .normal)
        showImageAfterUpdateButton.isSelected = viewModel.showImageAfterUpdate
    }
    
    @objc func slot0WasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        viewModel.lastTappedSlot = 0
        showDocumentPicker()
    }
    
    @objc func slot1WasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        viewModel.lastTappedSlot = 1
        showDocumentPicker()
    }
    
    @IBAction func showImageAfterUpdateTapped(_ sender: Any) {
        viewModel.showImageAfterUpdate.toggle()
        showImageAfterUpdateButton.isSelected = viewModel.showImageAfterUpdate
    }
    
    @IBAction func cancelButtonWasTapped(_ sender: Any) {
        viewModel.wasTapContinuation = true
        viewModel.onCancel()
    }
    
    @IBAction func uploadButtonWasTapped(_ sender: Any) {
                        
        var totalUploadImageSize = ((sizeOfImage0) + (sizeOfImage1)).rounded()
        print("totalUploadImageSize:- \(totalUploadImageSize)")
        
        if (totalUploadImageSize > 100) {
            showAlertWithButton(viewModel: viewModel)
        } else {
            viewModel.wasTapContinuation = true
            viewModel.onImageUpdate(viewModel.selectedImageIndex,
                                    viewModel.selectedImageIndex == 0 ? viewModel.imageSlot0 : viewModel.imageSlot1,
                                    viewModel.showImageAfterUpdate)
        }
    }
    
    private func showDocumentPicker() {
        let documentPickerViewController = SILDocumentPickerViewController(documentTypes: ["public.image"], in: .import)
        documentPickerViewController.setupDocumentPickerView()
        documentPickerViewController.delegate = self
        present(documentPickerViewController, animated: false, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        debugPrint("DID PICK")
        if let url = urls.first {
            let fileWriter = SILFileWriter(exportDirName: "EslDemo")
            let filePath = fileWriter.getFilePath(withName: url.lastPathComponent)
            if fileWriter.openFile(filePath: filePath) {
                if fileWriter.write(data: try? Data(contentsOf: url)) {
                    let url = fileWriter.getFileUrl(filePath: filePath)
                    fileWriter.closeFile()
                        
                    if viewModel.lastTappedSlot == 0 {
                        viewModel.imageSlot0 = url
                        sizeOfImage0 = getImageSizeInKB(imgPath: filePath)
                    } else {
                        viewModel.imageSlot1 = url
                        sizeOfImage1 = getImageSizeInKB(imgPath: filePath)
                    }
                    viewModel.selectedImageIndex = viewModel.lastTappedSlot
                    showAvailableImages()
                    setSelectedImage()
                }
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        debugPrint("DID CANCEL")
        controller.dismiss(animated: true, completion: nil)
    }
    
    func getImageSizeInKB(imgPath: String ) -> Double {
        let file = NSData(contentsOfFile: imgPath)
        let byte = ByteCountFormatter()
        byte.allowedUnits = [.useKB]
        byte.countStyle = .file
        let sizeInBytes = Int64(file!.count)
        //let dataSize = byte.string(fromByteCount: Int64(file!.count))
        return (Double(sizeInBytes)/1024.0)
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
        if viewModel.selectedImageIndex == 0, viewModel.isDifferentImageOnSlot0() {
            slot0ImageView.layer.borderWidth = 5
            slot1ImageView.layer.borderWidth = 0
            uploadButton.isEnabled = true
        } else if viewModel.isDifferentImageOnSlot1() {
            slot1ImageView.layer.borderWidth = 5
            slot0ImageView.layer.borderWidth = 0
            uploadButton.isEnabled = true
        } else {
            uploadButton.isEnabled = false
        }
    }
        
    func showAlertWithButton(viewModel: SILESLImageUpdatePopupViewModel) {
        let alertView = UIAlertController(title: "Alert!", message: msgText, preferredStyle: UIAlertController.Style.alert)
        
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("DismissPopup")
        }))
        alertView.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            viewModel.wasTapContinuation = true
            viewModel.onImageUpdate(viewModel.selectedImageIndex,
                                    viewModel.selectedImageIndex == 0 ? viewModel.imageSlot0 : viewModel.imageSlot1,
                                    viewModel.showImageAfterUpdate)
        }))
        present(alertView, animated: true, completion: nil)
    }
}
