//
//  SILTabBarController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 11/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

@objcMembers
class SILTabBarController: UITabBarController, UITabBarControllerDelegate {
    let VerticalOffsetForText: CGFloat = -12.0
    let HorizontalOffsetForText: CGFloat = 0.0
    let SystemVersion: Int = 13
    var defaultIndex: Int! {
        didSet {
            selectedIndex = defaultIndex
            if let silTabBar = tabBarController?.tabBar as? SILTabBar {
                silTabBar.setMuliplierForSelectedIndex(defaultIndex)
                silTabBar.layoutIfNeeded()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabsAppearance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate = self
        setupNavigationItem()
    }
    
    private func setupNavigationItem() {
        guard let selectedViewController else { return }
        self.title = selectedViewController.title
        self.navigationItem.rightBarButtonItems  = selectedViewController.navigationItem.rightBarButtonItems
        self.navigationItem.leftBarButtonItems  = selectedViewController.navigationItem.leftBarButtonItems
        self.navigationItem.hidesBackButton = selectedViewController.navigationItem.hidesBackButton
        self.navigationItem.leftItemsSupplementBackButton = selectedViewController.navigationItem.leftItemsSupplementBackButton
    }

    func setupTabsAppearance() {
        tabBar.barTintColor = UIColor.sil_cardBackground()
        setupTabBarItemFont()
        setupTabBarTextPosition()
    }
    
    func setupTabBarItemFont() {
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [
                NSAttributedString.Key.foregroundColor: UIColor.sil_background(),
                NSAttributedString.Key.font: UIFont.robotoRegular(size: UIFont.getMiddleFontSize())!
            ],
            for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [
                NSAttributedString.Key.foregroundColor: UIColor.sil_regularBlue(),
                NSAttributedString.Key.font: UIFont.robotoRegular(size: UIFont.getMiddleFontSize())!
            ],
            for: .selected)
    }
    
    func setupTabBarTextPosition() {
        if isIPadOS12() == false {
            UITabBarItem.appearance().titlePositionAdjustment = UIOffset(horizontal: HorizontalOffsetForText, vertical: VerticalOffsetForText)
        }
    }

    func isIPadOS12() -> Bool {
        if let systemVersion = Float(UIDevice.current.systemVersion) {
            return systemVersion < Float(SystemVersion) && UIDevice.current.userInterfaceIdiom == .pad
        }
        return false
    }
    
    // MARK: - UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBar = tabBarController.tabBar
        let item = tabBarController.tabBar.selectedItem
        var index: Int? = nil
        if let item = item {
            index = tabBar.items?.firstIndex(of: item) ?? NSNotFound
        }
        let silTabBar = tabBar as? SILTabBar
        silTabBar?.setMuliplierForSelectedIndex(index!)
        setupNavigationItem()
    }
    
    func selectItem(index: Int) {
        self.selectedViewController = viewControllers![index]
        self.delegate?.tabBarController?(self, didSelect: selectedViewController!)
    }
}
