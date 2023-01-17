//
//  SILBluetoothBrowserExpandableViewManager.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 18/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

@objc
@objcMembers
class SILBluetoothBrowserExpandableViewManager: NSObject {
    
    private var logButton: UIButton?
    private var connectionsButton: UIButton?
    private var filterButton: UIButton?
    private var sortButton: UIButton?
    private var expandableControllerHeight: NSLayoutConstraint?
    private var expandableControllerView: UIView?
    private var expandingViewController: UIViewController?
    private var filterBarHeight: NSLayoutConstraint?
    private var filterBarViewController: SILFilterBarViewController?
    
    private var effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    private var presentationView: UIView?
    private var discoveredDevicesView: UIView?
    private var browserViewController: UIViewController?
    private var cornerRadius: CGFloat = 0 {
        didSet {
            if  cornerRadius != oldValue {
                adjustView()
            }
        }
    }
    
    private var usedButtons: [UIButton] = []
    
    var filterIsSelected = false
    
    init(withOwnerViewController viewController: UIViewController) {
        super.init()
        self.browserViewController = viewController
    }
    
    // MARK: Setup
    
    func setReferenceFor(presentationView: UIView, andDiscoveredDevicesView discoveredDevicesView: UIView) {
        self.presentationView = presentationView
        self.discoveredDevicesView = discoveredDevicesView
    }
    
    
    func setReferenceForExpandableControllerView(_ expandableControllerView: UIView, andExpandableControllerHeight expandableControllerHeight: NSLayoutConstraint) {
        self.expandableControllerView = expandableControllerView
        self.expandableControllerHeight = expandableControllerHeight
    }
    
    func setValueFor(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }
    
    func setupButtonsTabBar(log logButton: UIButton, connections connectionsButton: UIButton) {
        self.logButton = logButton
        self.connectionsButton = connectionsButton
        [logButton, connectionsButton].forEach {
            usedButtons.append($0)
        }
        setupConnectionButton()
    }
    
    func setupButtonsTabBar(log logButton: UIButton, connections connectionsButton: UIButton, filter filterButton: UIButton, andFilterIsActive isActive: Bool, andSortButton sortButton: UIButton) {
        self.logButton = logButton
        self.connectionsButton = connectionsButton
        self.filterButton = filterButton
        self.sortButton = sortButton
        [logButton, connectionsButton, filterButton, sortButton].forEach {
            usedButtons.append($0)
        }
        setupConnectionButton()
        setupFilterButtonWhereIsFilterActive(isActive)
        setupSortButton()
    }

    private func setupConnectionButton() {
        connectionsButton?.setImage(UIImage(named: SILImageConnectOff)!.withRenderingMode(.alwaysOriginal), for: .normal)
        connectionsButton?.setImage(UIImage(named: SILImageConnectOn)!.withRenderingMode(.alwaysOriginal), for: .selected)
    }
    
    private func setupFilterButtonWhereIsFilterActive(_ isFilterActive: Bool) {
        updateFilterIsActiveFilter(isFilterActive)
    }
    
    private func setupSortButton() {
        sortButton?.setImage(UIImage(named: SILImageSortOff)!.withRenderingMode(.alwaysOriginal), for: .normal)
        sortButton?.setImage(UIImage(named: SILImageSortOn)!.withRenderingMode(.alwaysOriginal), for: .selected)
    }
    
    private func setupButton(_ button: UIButton) {
        let titleEdgeInsetsForButton = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 0)
        button.tintColor = .clear
        button.imageView?.contentMode = .scaleAspectFit
        button.titleEdgeInsets = titleEdgeInsetsForButton
        button.titleLabel?.font = UIFont.robotoMedium(size: UIFont.getMiddleFontSize())
        button.setTitleColor(UIColor.sil_primaryText(), for: .normal)
        button.setTitleColor(UIColor.sil_regularBlue(), for: .selected)
    }
    
    func setupFilterBar(filterBarHeight: NSLayoutConstraint?, filterBarViewController: SILFilterBarViewController?) {
        self.filterBarHeight = filterBarHeight
        self.filterBarViewController = filterBarViewController
    }
    
    func updateFilterIsActiveFilter(_ isActiveFilter: Bool) {
        if isActiveFilter {
            setupImagesForActiveFilter()
        } else {
            setupImagesForInactiveFilter()
        }
    }
    
    func updateFilterBar(with filterViewModel: SILBrowserFilterViewModel?) {
        if let filterViewModel = filterViewModel {
            self.filterBarViewController?.updateCurrentFilter(filter: filterViewModel)
            self.filterBarHeight?.isActive = !filterViewModel.isFilterActive()
        } else {
           hideFilterBar()
        }
    }
    
    private func hideFilterBar() {
        self.filterBarHeight?.isActive = true
    }
    
    private func setupImagesForInactiveFilter() {
        filterButton?.setImage(UIImage(named: SILImageFilterOff)!.withRenderingMode(.alwaysOriginal), for: .normal)
        filterButton?.setImage(UIImage(named: SILImageFilterOffSelected)!.withRenderingMode(.alwaysOriginal), for: .selected)
    }

    private func setupImagesForActiveFilter() {
        filterButton?.setImage(UIImage(named: SILImageFilterOn)!.withRenderingMode(.alwaysOriginal), for: .normal)
        filterButton?.setImage(UIImage(named: SILImageFilterOnSelected)!.withRenderingMode(.alwaysOriginal), for: .selected)
    }

    func changeImagesOfSortButtonFor(option: SILSortOption) {
        switch option {
        case .none:
            sortButton?.setImage(UIImage(named: SILImageSortOff)!.withRenderingMode(.alwaysOriginal), for: .normal)
            sortButton?.setImage(UIImage(named: SILImageSortOn)!.withRenderingMode(.alwaysOriginal), for: .selected)
        case .ascendingRSSI:
            sortButton?.setImage(UIImage(named: SILImageSortAscendingOff)!.withRenderingMode(.alwaysOriginal), for: .normal)
            sortButton?.setImage(UIImage(named: SILImageSortAscendingOn)!.withRenderingMode(.alwaysOriginal), for: .selected)
        case .descendingRSSI:
            sortButton?.setImage(UIImage(named: SILImageSortDescendingOff)!.withRenderingMode(.alwaysOriginal), for: .normal)
            sortButton?.setImage(UIImage(named: SILImageSortDescendingOn)!.withRenderingMode(.alwaysOriginal), for: .selected)
        case .AZ:
            sortButton?.setImage(UIImage(named: SILImageSortAZOff)!.withRenderingMode(.alwaysOriginal), for: .normal)
            sortButton?.setImage(UIImage(named: SILImageSortAZOn)!.withRenderingMode(.alwaysOriginal), for: .selected)
        case .ZA:
            sortButton?.setImage(UIImage(named: SILImageSortZAOff)!.withRenderingMode(.alwaysOriginal), for: .normal)
            sortButton?.setImage(UIImage(named: SILImageSortZAOn)!.withRenderingMode(.alwaysOriginal), for: .selected)
        }
    }
    
    // MARK: TappedActions
    
    func logButtonWasTappedAction() -> SILBrowserLogViewController? {
        var logVC: SILBrowserLogViewController? = nil
        
        if !logButton!.isSelected {
            let storyboard = UIStoryboard(name: SILAppBluetoothBrowserHome, bundle: nil)
            logVC = storyboard.instantiateViewController(withIdentifier: SILSceneLog) as? SILBrowserLogViewController
            handleButtonSelect(self.logButton!, andViewController: logVC!)
        } else {
            prepareSceneForRemoveExpandingController()
        }
        
        return logVC
    }
    
    func connectionsButtonWasTappedAction() -> SILBrowserConnectionsViewController? {
        var connectionVC: SILBrowserConnectionsViewController? = nil
        
        if !connectionsButton!.isSelected {
            let storyboard = UIStoryboard(name: SILAppBluetoothBrowserHome, bundle: nil)
            connectionVC = storyboard.instantiateViewController(withIdentifier: SILSceneConnections) as? SILBrowserConnectionsViewController
            handleButtonSelect(self.connectionsButton!, andViewController: connectionVC!)
        } else {
            prepareSceneForRemoveExpandingController()
        }
        
        return connectionVC
    }
    
    func filterButtonWasTappedAction() -> SILBrowserFilterViewController? {
        var filterVC: SILBrowserFilterViewController? = nil
        
        if filterIsSelected {
            let storyboard = UIStoryboard(name: SILAppBluetoothBrowserHome, bundle: nil)
            filterVC = storyboard.instantiateViewController(withIdentifier: SILSceneFilter) as? SILBrowserFilterViewController
            handleButtonSelect(UIButton(), andViewController: filterVC!)
        } else {
            prepareSceneForRemoveExpandingController()
        }

        return filterVC
    }
    
    private func handleButtonSelect(_ button: UIButton, andViewController vc: UIViewController, wasSortButtonSelected: Bool = false) {
        let wasAnyButtonSelected = isAnyButtonSelected()
        let wasSortButtonSelected = sortButton?.isSelected ?? false
        let willBeSortButtonSelected = button.isEqual(self.sortButton)
        deselectAllButtons()
        button.isSelected = true
        prepareSceneDependOnButtonSelection(wasAnyButtonSelected)

        insertIntoContainerExpandableController(vc)
        let isNeededAnimate = wasSortButtonSelected || !wasAnyButtonSelected || willBeSortButtonSelected
        animateExpandableViewController(isNeeded: isNeededAnimate)
        self.expandingViewController = vc
    }
    
    // MARK: Public appearance methods
    
    func updateConnectionsButtonTitle(_ connections: UInt) {
        let connectionText = "\(connections) Connections"
        connectionsButton?.setTitle(connectionText, for: .normal)
        connectionsButton?.setTitle(connectionText, for: .selected)
    }
    
    func removeExpandingControllerIfNeeded() {
        prepareSceneForRemoveExpandingController()
    }
    
    // MARK: Private appearance methods
    
    private func isAnyButtonSelected() -> Bool {
        return usedButtons.reduce(false) { $0 || $1.isSelected }
    }
    
    private func deselectAllButtons() {
        usedButtons.forEach{ $0.isSelected = false }
    }
    
    private func prepareSceneDependOnButtonSelection(_ wasAnyButtonSelected: Bool) {
        if wasAnyButtonSelected {
            prepareSceneForChangeExpandableView()
        } else {
            prepareSceneForExpandableView()
        }
        customizeExpandableViewAppearance()
    }
    
    private func insertIntoContainerExpandableController(_ viewController: UIViewController) {
        browserViewController!.addChild(viewController)
        expandableControllerView!.addSubview(viewController.view)
        viewController.view.frame = self.expandableControllerView!.frame
        viewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        viewController.didMove(toParent: self.browserViewController!)
        browserViewController!.view.setNeedsUpdateConstraints()
    }
    
    private func prepareSceneForChangeExpandableView() {
        removeExpandableViewController()
    }
    
    private func prepareSceneForExpandableView() {
        if let _ = self.expandingViewController {
            prepareSceneForRemoveExpandingController()
        }
        hideFilterBar()
        attachBlurEffectView()
    }
    
    private func customizeExpandableViewAppearance() {
        self.cornerRadius = 20.0
        if sortButton?.isSelected ?? false {
            let sortVM = SILSortViewModel._sharedInstance
            expandableControllerHeight!.constant = sortVM.getViewControllerHeight()
            return
        }
        self.expandableControllerHeight!.constant = self.presentationView!.frame.size.height * 0.9
    }
    
    private func customizeSceneWithoutExpandableViewContoller() {
        self.cornerRadius = 0.0
        self.expandableControllerHeight?.constant = CollapsedViewHeight
    }
    
    private func removeExpandableViewController() {
        browserViewController?.willMove(toParent: nil)
        expandingViewController?.view.removeFromSuperview()
        expandingViewController?.removeFromParent()
        expandingViewController = nil
    }
    
    private func prepareSceneForRemoveExpandingController() {
        deselectAllButtons()
        removeExpandableViewController()
        customizeSceneWithoutExpandableViewContoller()
        animateExpandableViewController()
        removeBlurEffectView()
        restoreFilterBar()
        self.filterIsSelected = false
    }
    
    private func restoreFilterBar() {
        if let filterBarViewController = self.filterBarViewController,
           !filterBarViewController.isEmpty() {
            filterBarViewController.restore()
            self.filterBarHeight?.isActive = false
        }
    }
        
    private func attachBlurEffectView() {
        self.effectView.frame = self.presentationView!.frame
        self.discoveredDevicesView?.addSubview(self.effectView)
    }

    private func removeBlurEffectView() {
        self.effectView.removeFromSuperview()
    }

    private func adjustView() {
        if let expandableView = self.expandableControllerView {
            expandableView.layer.cornerRadius = self.cornerRadius
            expandableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            expandableView.clipsToBounds = true
        }
    }
    
    private func animateExpandableViewController(isNeeded: Bool = true) {
        if isNeeded {
            UIView.animate(withDuration: TimeInterval(AnimationExpandableControllerTime), delay: TimeInterval(AnimationExpandableControllerDelay), options: [.curveLinear], animations: { self.browserViewController?.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
}
