//
//  BarView.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 12/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

@IBDesignable
class BarView: UIStackView {
    
    @IBOutlet var bars: [RoundView]!
    
    var level: Int = 0 {
        didSet {
            if self.level > arrangedSubviews.count {
                self.level = arrangedSubviews.count
                return
            }
            for (i, view) in arrangedSubviews.enumerated() {
                if let roundView: RoundView = view as? RoundView {
                    roundView.isOn = (i < self.level)
                }
            }
        }
    }
    
    @IBInspectable var color: UIColor = UIColor.clear {
        didSet {
            bars.forEach { (bar) in
                bar.backgroundColor = self.color
            }
        }
    }

}
