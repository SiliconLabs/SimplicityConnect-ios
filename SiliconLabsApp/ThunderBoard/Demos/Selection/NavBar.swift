//
//  NavBar.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 17/03/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

class NavBar: UIView {
    
    override func draw(_ rect: CGRect) {
           super.draw(rect)
           setupNavigationBarShadow()
       }
       
       private func setupNavigationBarShadow() {
           self.superview?.bringSubviewToFront(self)
           self.addShadow()
       }

}
