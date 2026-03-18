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

extension UITextView {
    func isValid(with text: String) -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func isValidAWSEndpoint(_ endpoint: String) -> Bool {
        // Basic URL validation
        guard let url = URL(string: endpoint), url.scheme == "https" || url.scheme == "wss" else {
            return false
        }
        // Optional: Regex for AWS IoT endpoint pattern
        let pattern = #"^[a-zA-Z0-9\-]+\.iot\.[a-z0-9\-]+\.amazonaws\.com(\.cn)?$"#
        let host = url.host ?? ""
        return host.range(of: pattern, options: .regularExpression) != nil
    }
}
