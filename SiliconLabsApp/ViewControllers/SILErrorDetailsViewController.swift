//
//  SILErrorDetailsViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 08/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILErrorDetailsViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var errorGeneralNameLabel: UILabel!
    @IBOutlet weak var errorDescriptionLabel: UILabel!
    
    var delegate: SILErrorDetailsViewControllerDelegate!
    private var viewModel: SILErrorDetailsViewModel!
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 400, height: 400)
            } else {
                return CGSize(width: 300, height: 350)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    @objc init(error: NSError,
               delegate: SILErrorDetailsViewControllerDelegate) {
        self.delegate = delegate
        self.viewModel = SILErrorDetailsViewModel(error: error)
        super.init(nibName: "SILErrorDetailsViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleLabelText()
        setupErrorGeneralNameLabelText()
        setupDescriptionLabelText()
    }
    
    private func setupTitleLabelText() {
        let text = "Error \(viewModel.errorCode)"
        titleLabel.text = text
    }
    
    private func setupErrorGeneralNameLabelText() {
        let attributedText = prerareAttributedText(boldText: "Error: ", normalText: viewModel.errorName)
        errorGeneralNameLabel.attributedText = attributedText
    }
    
    private func setupDescriptionLabelText() {
        let attributedText = prerareAttributedText(boldText: "Description: ", normalText: viewModel.errorDescription)
        errorDescriptionLabel.attributedText = attributedText
    }
    
    private func prerareAttributedText(boldText: String, normalText: String) -> NSMutableAttributedString {
        let attrs = [NSAttributedString.Key.font : UIFont.robotoBold(size: 16)! ]
        let attributedString = NSMutableAttributedString(string:boldText, attributes: attrs)
        let normalString = NSMutableAttributedString(string:normalText)
        attributedString.append(normalString)
        return attributedString
    }
    
    @IBAction func didTapOkButton(_ sender: UIButton) {
        delegate.shouldCloseErrorDetailsViewController(self)
    }
}
