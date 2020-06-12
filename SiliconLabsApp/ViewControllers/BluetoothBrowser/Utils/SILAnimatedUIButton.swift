//
//  SILAnimatedUIButton.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 01/06/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILAnimatedUIButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
    }

    @objc private func buttonClicked(sender: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {() -> Void in
            sender.imageView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            sender.alpha = 0.5
        }, completion: {(_ finished: Bool) -> Void in
            UIView.animate(withDuration: 0.2, animations: {() -> Void in
                sender.imageView?.transform = CGAffineTransform(scaleX: 1, y: 1)
                sender.alpha = 1.0
            })
        })
    }
}
