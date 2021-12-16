//
//  String+VersionCompare.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 10/12/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

extension String {
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        return self.compare(otherVersion, options: .numeric)
    }
}
