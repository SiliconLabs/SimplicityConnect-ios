//
//  SILFilterBarViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 10.12.2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILFilterBarViewController: UIViewController {
    @IBOutlet weak var filterParametersLabel: UILabel!
    private var viewModel = SILFilterBarViewModel()
    private var tokensBag = SILObservableTokenBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestureRecognizer()
        observeViewModel()
    }

    private func setupGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        filterParametersLabel.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleTap() {
        self.viewModel.handleTap()
    }
    
    private func observeViewModel() {
        tokensBag.add(token: self.viewModel.state.observe { [weak self] expanded in
            self?.updateLabel(expanded: expanded)
        })
        
        tokensBag.add(token: self.viewModel.filterParamters.observe { [weak self]  filterParameters in
            self?.updateLabelText(text: filterParameters)
        })
    }
    
    func updateCurrentFilter(filter: SILBrowserFilterViewModel?) {
        self.viewModel.updateCurrentFilter(filter: filter)
    }
    
    func restore() {
        self.filterParametersLabel.text = self.viewModel.filterParamters.value
    }
    
    func isEmpty() -> Bool {
        return self.filterParametersLabel.text == ""
    }
        
    private func updateLabelText(text: String) {
        self.filterParametersLabel.text = text
    }
    
    private func updateLabel(expanded: Bool) {
        self.filterParametersLabel.numberOfLines = expanded ? 0 : 1
    }
}
