//
//  String+Subscript.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 19/11/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

extension String {
  subscript(_ i: Int) -> String {
    let idx1 = index(startIndex, offsetBy: i)
    let idx2 = index(idx1, offsetBy: 1)
    return String(self[idx1..<idx2])
  }

  subscript (r: Range<Int>) -> String {
    let start = index(startIndex, offsetBy: r.lowerBound)
    let end = index(startIndex, offsetBy: r.upperBound)
    return String(self[start ..< end])
  }

  subscript (r: CountableClosedRange<Int>) -> String {
    let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
    let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
    return String(self[startIndex...endIndex])
  }
}
