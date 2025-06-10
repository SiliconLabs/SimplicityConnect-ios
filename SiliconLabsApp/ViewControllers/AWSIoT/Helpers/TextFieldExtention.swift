//
//  TextFieldExtention.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 20/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation
extension UITextField {

    func isValid(with word: String) -> Bool {
        guard let text = self.text,
              !text.isEmpty else {
            print("Please fill the field.")
            return false
        }

        guard !text.containsWhiteSpace() else {
            print("Wrong word. Please check again.")
            return false
        }
        return true
    }
}

extension String {

    func containsWhiteSpace() -> Bool {
        // check if there's a range for a whitespace
        let range = self.rangeOfCharacter(from: .whitespacesAndNewlines)
        // returns false when there's no range for whitespace
        if let _ = range {
            return true
        } else {
            return false
        }
    }
}
