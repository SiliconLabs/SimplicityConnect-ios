//
//  SettingsNavigationController.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

class SettingsNavigationController : UINavigationController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBarStyle()
    }
    
    private func setupNavigationBarStyle() {
        
        self.navigationBar.isTranslucent = true
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.tintColor = StyleColor.white
        self.navigationBar.backgroundColor = UIColor.sil_siliconLabsRed()

        self.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([
            NSAttributedString.Key.foregroundColor.rawValue: StyleColor.white,
            NSAttributedString.Key.font.rawValue : StyleText.navBarTitle.font
        ])

        let image = UIImage.tb_imageWithColor(StyleColor.vileRed, size: CGSize(width: 1, height: 1))
        self.navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
    }
    
    var settingsViewController: SettingsViewController {
        get { return self.viewControllers[0] as! SettingsViewController }
    }
    
    fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
        guard let input = input else { return nil }
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
    }
    
}
