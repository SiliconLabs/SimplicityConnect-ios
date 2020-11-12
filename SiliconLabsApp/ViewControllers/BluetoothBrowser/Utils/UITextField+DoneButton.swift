//
//  UITextField+DoneButton.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 05/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

@objc extension UITextField {
    func addDoneButton() {
        let onDone = (target: self, action: #selector(doneButtonTapped))

        let toolbar: UIToolbar = UIToolbar()
        let doneButtonItem = UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        doneButtonItem.setTitleTextAttributes([.foregroundColor: UIColor.sil_regularBlue()], for: .normal)
        
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            doneButtonItem
        ]
        toolbar.sizeToFit()

        self.inputAccessoryView = toolbar
    }

    @objc func doneButtonTapped() {
        self.resignFirstResponder()
    }
}
