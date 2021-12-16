//
//  SILLocalGattServer.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 14/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

import Foundation

@objcMembers
class SILLocalGattServerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBPeripheralDelegate, UIScrollViewDelegate, SILDebugPopoverViewControllerDelegate, WYPopoverControllerDelegate, SILCharacteristicEditEnablerDelegate, SILOTAUICoordinatorDelegate, SILDebugCharacteristicCellDelegate, SILServiceCellDelegate, SILBrowserLogViewControllerDelegate, SILBrowserConnectionsViewControllerDelegate, SILDebugServicesMenuViewControllerDelegate, SILDebugCharacteristicEncodingFieldTableViewCellDelegate, SILErrorDetailsViewControllerDelegate, SILDescriptorTableViewCellDelegate {
    
    private let kSpacerCellIdentifieer = "spacer"
    private let kCornersCellIdentifieer = "corners"
    private let kOTAButtonTitle = "OTA"
    private let kScanningForPeripheralsMessage = "Loading..."
    private let kTableRefreshInterval: Double = 1.0
    
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    var peripheral: CBPeripheral!
    var centralManager: SILCentralManager!
    
    let tokenBag = SILObservableTokenBag()
    var gattConfiguratorService = SILGattConfiguratorService.shared
    private var runningConfiguration: SILGattConfigurationEntity?
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var rssiImageView: UIImageView!
    
    var allServiceModels: [SILServiceTableModel] = []
    var modelsToDisplay: [AnyHashable] = []
    var isUpdatingFirmware = false {
        didSet {
            if !isUpdatingFirmware {
                addObserverForDisplayToastResponse()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SILNotificationDisplayToastRequest), object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: SILNotificationDisplayToastResponse), object: nil)
            }
        }
    }
    var rssiTimer: Timer?
    var otaUICoordinator: SILOTAUICoordinator?
    @IBOutlet weak var discoveredDevicesView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var popoverController: WYPopoverController?
    @IBOutlet weak var presentationView: UIView!
    var headerView: SILDebugHeaderView?
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var aboveSpaceSaveAreaView: UIView!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var connectionsButton: UIButton!
    @IBOutlet weak var logButton: UIButton!
    @IBOutlet weak var expandableControllerView: UIView!
    @IBOutlet weak var expandableControllerHeight: NSLayoutConstraint!
    var connectionsViewModel: SILBrowserConnectionsViewModel!
    var browserExpandableViewManager: SILBluetoothBrowserExpandableViewManager!
    @IBOutlet weak var menuContainer: UIView!
    @IBOutlet weak var menuOptionHeight: NSLayoutConstraint!
    @IBOutlet weak var topRefreshImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var refreshImageView: SILRefreshImageView!
    @IBOutlet weak var topButtonsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuButton.isHidden = true
        menuContainer.isHidden = true
        registerNibsAndSetUpSizing()
        setupNavigationBar()
        setupBrowserExpandableViewManager()
        setupButtonsTabBar()
        setupConnectionsViewModel()
        updateConnectionsButtonTitle()
        hideRSSIView()
        isUpdatingFirmware = false
        setupRefreshImageView()
        topButtonsView.addShadow()
        peripheral.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deviceNameLabel.text = peripheral.name
        registerForNotifications()
        addObserverForUpdateConnectionsButtonTitle()
        installRSSITimer()
        observeLocalGattServer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissPopoverIfExist()
        browserExpandableViewManager?.removeExpandingControllerIfNeeded()
        removeUnfiredTimers()
        tokenBag.invalidateTokens()
        NotificationCenter.default.removeObserver(self)
    }

    func dismissPopoverIfExist() {
        if let popoverController = popoverController {
            popoverController.dismissPopover(animated: true)
        }
    }
    
    private func removeUnfiredTimers() {
        if let timer = rssiTimer {
            timer.invalidate()
            self.rssiTimer = nil
        }
    }

    @IBAction func backButtonWasTapped(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    func performOTAAction() {
        isUpdatingFirmware = true
        otaUICoordinator = SILOTAUICoordinator(peripheral: peripheral, centralManager: centralManager, presenting: self)
        otaUICoordinator!.delegate = self
        otaUICoordinator!.initiateOTAFlow()
    }
    
    func setupNavigationBar() {
        aboveSpaceSaveAreaView.backgroundColor = UIColor.sil_siliconLabsRed()
        navigationBarView.backgroundColor = UIColor.sil_siliconLabsRed()
    }
    
    func setupBrowserExpandableViewManager() {
        cornerRadius = CornerRadiusStandardValue
        browserExpandableViewManager = SILBluetoothBrowserExpandableViewManager(withOwnerViewController: self)
        browserExpandableViewManager?.setReferenceFor(presentationView: presentationView, andDiscoveredDevicesView: discoveredDevicesView)
        browserExpandableViewManager?.setReferenceForExpandableControllerView(expandableControllerView, andExpandableControllerHeight: expandableControllerHeight)
        browserExpandableViewManager?.setValueFor(cornerRadius: cornerRadius)
    }

    func setupButtonsTabBar() {
        browserExpandableViewManager?.setupButtonsTabBar(log: logButton, connections: connectionsButton)
    }
    
    func setupRefreshImageView() {
        refreshImageView.model = SILRefreshImageModel(
            constraint: topRefreshImageConstraint,
            withEmpty: presentationView,
            with: tableView,
            andWithReloadAction: { [self] in
                refreshTable()
            })
        refreshImageView.setup()
    }

    // MARK: - setup
    
    func registerNibsAndSetUpSizing() {
        let characteristicValueFieldCellClassString = NSStringFromClass(SILDebugCharacteristicValueFieldTableViewCell.self)
        tableView.register(UINib(nibName: characteristicValueFieldCellClassString, bundle: nil), forCellReuseIdentifier: characteristicValueFieldCellClassString)

        let characteristicToggleFieldCellClassString = NSStringFromClass(SILDebugCharacteristicToggleFieldTableViewCell.self)
        tableView.register(UINib(nibName: characteristicToggleFieldCellClassString, bundle: nil), forCellReuseIdentifier: characteristicToggleFieldCellClassString)

        let characteristicEnumerationFieldCellClassString = NSStringFromClass(SILDebugCharacteristicEnumerationFieldTableViewCell.self)
        tableView.register(UINib(nibName: characteristicEnumerationFieldCellClassString, bundle: nil), forCellReuseIdentifier: characteristicEnumerationFieldCellClassString)

        let characteristicEncodingFieldCellClassString = NSStringFromClass(SILDebugCharacteristicEncodingFieldTableViewCell.self)
        tableView.register(UINib(nibName: characteristicEncodingFieldCellClassString, bundle: nil), forCellReuseIdentifier: characteristicEncodingFieldCellClassString)

        let spacerCellClassString = NSStringFromClass(SILDebugSpacerTableViewCell.self)
        tableView.register(UINib(nibName: spacerCellClassString, bundle: nil), forCellReuseIdentifier: spacerCellClassString)
    }
    
    func observeLocalGattServer() {
        self.gattConfiguratorService.runningGattConfiguration.observe { gattConfiguration in
            self.runningConfiguration = gattConfiguration
            self.buildAllServiceModels()
            self.refreshTable()
        }.putIn(bag: tokenBag)
    }

    func setupConnectionsViewModel() {
        connectionsViewModel = SILBrowserConnectionsViewModel.sharedInstance()
    }

    func hideRSSIView() {
        rssiLabel.isHidden = true
        rssiImageView.isHidden = true
    }
    
    // MARK: - Menu
    
    @IBAction func menuButtonWasTapped(_ sender: Any) {
        showMenu()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenMenuFromLocalSegue", let menuVC = segue.destination as? SILDebugServicesMenuViewController {
            menuVC.delegate = self
            menuVC.addMenuOption(title: "OTA DFU") { [self] in
                performOTAAction()
                browserExpandableViewManager?.removeExpandingControllerIfNeeded()
            }
            menuOptionHeight.constant = menuVC.getMenuOptionHeight()
        }
    }
    
    func performActionForMenuOption(using completion: () -> ()) {
        hideMenu()
        completion()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        hideMenu()
    }

    func showMenu() {
        menuContainer.isHidden = false
        tableView.isUserInteractionEnabled = false
    }

    func hideMenu() {
        menuContainer.isHidden = true
    }
    
    // MARK: - Swipe Actions
    
    @IBAction func swipeToClient(_ sender: UISwipeGestureRecognizer) {
        let silTabBarController = tabBarController as! SILTabBarController
        let silTabBar = silTabBarController.tabBar as! SILTabBar
        
        silTabBar.setMuliplierForSelectedIndex(0)
        silTabBarController.defaultIndex = 0
    }
    
    // MARK: - Expandable Controllers
    
    @IBAction func connectionsButtonTapped(_ sender: Any) {
        let connectionsVC = browserExpandableViewManager?.connectionsButtonWasTappedAction()
        if connectionsVC?.delegate == nil {
            connectionsVC?.delegate = self
        }
    }
    
    @IBAction func logButtonWasTapped(_ sender: Any) {
        let logVC = browserExpandableViewManager?.logButtonWasTappedAction()
        if logVC?.delegate == nil {
            logVC?.delegate = self
        }
    }
    
    // MARK: - SILOTAUICoordinatorDelegate
    
    func otaUICoordinatorDidFishishOTAFlow(_ coordinator: SILOTAUICoordinator?) {
        navigationController?.popViewController(animated: true)
        isUpdatingFirmware = false
    }

    func otaUICoordinatorDidCancelOTAFlow(_ coordinator: SILOTAUICoordinator?) {
        isUpdatingFirmware = false
    }
    
    // MARK: - Notifications
    
    func registerForNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didDisconnectPeripheralNotifcation(_:)),
            name: NSNotification.Name.SILCentralManagerDidDisconnectPeripheral,
            object: centralManager)
    }
    
    func addObserverForUpdateConnectionsButtonTitle() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateConnectionsButtonTitle), name: NSNotification.Name(rawValue: SILNotificationReloadConnectionsTableView), object: nil)
    }

    func addObserverForDisplayToastResponse() {
        NotificationCenter.default.addObserver(self, selector: #selector(displayToast(_:)), name: NSNotification.Name(rawValue: SILNotificationDisplayToastResponse), object: nil)
    }
    
    // MARK: - Notification Methods
    
    @objc func displayToast(_ notification: Notification?) {
        if let errorMessage = notification?.userInfo?[SILNotificationKeyDescription] as? String {
            showToast(message: errorMessage, toastType: .disconnectionError) {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SILNotificationDisplayToastRequest), object: nil)
            }
        }
    }
    
    @objc func didDisconnectPeripheralNotifcation(_ notification: Notification?) {
        let uuid = notification?.userInfo?[SILNotificationKeyUUID] as? String
        debugPrint("disconnect peripheral in local")
        if uuid == peripheral.identifier.uuidString {
            if !isUpdatingFirmware {
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc func updateConnectionsButtonTitle() {
        let connections = connectionsViewModel.peripherals.count
        browserExpandableViewManager.updateConnectionsButtonTitle(UInt(connections))
    }
    
    // MARK: - Timers
    
    func installRSSITimer() {
        weak var blocksafeSelf = self
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            blocksafeSelf?.peripheral.readRSSI()
        })
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelsToDisplay.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let identifier = modelsToDisplay[indexPath.row] as? String,
           identifier == kSpacerCellIdentifieer,
           let spacerCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SILDebugSpacerTableViewCell.self)) as? SILDebugSpacerTableViewCell {
            return spacerCell
        }
        let model = modelsToDisplay[indexPath.row]
        if let model = model as? SILServiceTableModel {
            return serviceCell(with: model, forTable: tableView)
        }
        if let model = model as? SILCharacteristicTableModel {
            return characteristicCell(with: model, forTable: tableView)
        } else {
            let fieldModel = modelsToDisplay[indexPath.row] as? SILCharacteristicFieldRow
            if let fieldModel = fieldModel as? SILEnumerationFieldRowModel {
                return enumerationFieldCell(with: fieldModel, forTable: tableView)
            }
            if let fieldModel = fieldModel as? SILBitRowModel {
                return toggleFieldCell(with: fieldModel, forTable: tableView)
            }
            if let fieldModel = fieldModel as? SILEncodingPseudoFieldRowModel {
                return encodingFieldCell(with: fieldModel, forTable: tableView)
            }
            if let fieldModel = fieldModel as? SILValueFieldRowModel {
                return valueFieldCell(with: fieldModel, forTable: tableView)
            }
        }
        return UITableViewCell()
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? SILDebugCharacteristicTableViewCell,
           let characteristicModel = modelsToDisplay[indexPath.row] as? SILCharacteristicTableModel, characteristicModel.isUnknown {
                characteristicModel.toggleExpansionIfAllowed()
                cell.expandIfAllowed(characteristicModel.isExpanded)
                refreshTable()
                return
            }
        if let model = modelsToDisplay[indexPath.row] as? SILGenericAttributeTableModel {
            if model.canExpand() {
                model.toggleExpansionIfAllowed()
                if let cell = tableView.cellForRow(at: indexPath) as? SILGenericAttributeTableCell {
                    cell.expandIfAllowed(model.isExpanded)
                }
            }
            refreshTable()
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRow(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRow(at: indexPath)
    }
    
    func heightForRow(at indexPath: IndexPath) -> CGFloat {
        if let identifier = modelsToDisplay[indexPath.row] as? String{
            if identifier == kSpacerCellIdentifieer {
                return 24.0
            }
            if identifier == kCornersCellIdentifieer {
                return 16.0
            }
        }

        let model = modelsToDisplay[indexPath.row]
        if model is SILServiceTableModel {
            return 104.0
        }
        if let modelCharacteristic = model as? SILCharacteristicTableModel {
            let descriptors = modelCharacteristic.descriptorModels?.count
            if descriptors == 0 {
                return 107.0;
            } else {
                var tableHeight: CGFloat = 0.0

                for model in modelCharacteristic.descriptorModels as? [SILDescriptorTableModel] ?? [] {
                    let size = CGSize(width: tableView.bounds.size.width - 120, height: CGFloat.greatestFiniteMagnitude)
                    let rect = model.getAttributedDescriptor().boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
                    tableHeight += ceil(rect.size.height)
                }

                return 130 + tableHeight
            }
        } else {
            if model is SILEncodingPseudoFieldRowModel {
                return 132.0
            }
            return 81.0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.indexPathsForVisibleRows?[0] == indexPath {
            tableView.bringSubviewToFront(cell)
        }
        if let identifier = modelsToDisplay[indexPath.row] as? String,
           identifier == kSpacerCellIdentifieer {
                cell.backgroundColor = UIColor.clear
                cell.contentView.backgroundColor = UIColor.clear
                return
        }
        if let model = modelsToDisplay[indexPath.row] as? SILServiceTableModel {
            if model.isExpanded {
                cell.roundCornersTop()
                cell.addShadowWhenAtTop()
            } else {
                cell.roundCornersAll()
                cell.addShadowWhenAlone()
            }
        } else {
            if let identifier = modelsToDisplay[indexPath.row + 1] as? String,
            identifier == kSpacerCellIdentifieer {
                cell.roundCornersBottom()
                cell.addShadowWhenAtBottom()
            } else {
                cell.roundCornersNone()
                cell.addShadowWhenInMid()
            }
        }
        cell.contentView.backgroundColor = UIColor.white
        cell.clipsToBounds = false
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let size = CGRect(x: tableView.bounds.origin.x, y: tableView.bounds.origin.y, width: tableView.bounds.size.width, height: 20)
        let view = UIView(frame: size)
        view.backgroundColor = UIColor.clear
        return view
    }
    
    // MARK: - SILServiceCellDelegate
    
    func showMoreInfoForCell(_ cell: SILServiceCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            tableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Fix for SLMAIN-124. Header jumps on plus sized iPhones when opening services sometimes.
        var rect = CGRect()
        rect.origin = headerView?.frame.origin ?? .zero
        rect.size = headerView?.frame.size ?? .zero
        rect.origin.y = max(0, -(scrollView.contentOffset.y + rect.size.height))
        headerView?.frame = rect
        if scrollView.contentOffset.y < 0 {
            scrollView.contentOffset = CGPoint.zero
        } else {
            tableView.isScrollEnabled = true
        }
    }
    
    // MARK: - Configure Cells
    
    func serviceCell(with serviceTableModel: SILServiceTableModel, forTable tableView: UITableView) -> SILServiceCell {
        let serviceCell = tableView.dequeueReusableCell(withIdentifier: "SILServiceCell") as! SILServiceCell
        serviceCell.delegate = self
        serviceCell.nameEditButton.isHidden = !serviceTableModel.isMappable
        serviceCell.serviceNameLabel.text = serviceTableModel.name()
        serviceCell.serviceUuidLabel.text = serviceTableModel.hexUuidString() ?? ""
        serviceCell.configureAsExpandanble(serviceTableModel.canExpand())
        serviceCell.customizeMoreInfoText(serviceTableModel.isExpanded)
        serviceCell.layoutIfNeeded()
        return serviceCell
    }
    
    func characteristicCell(with characteristicTableModel: SILCharacteristicTableModel, forTable tableView: UITableView) -> SILDebugCharacteristicTableViewCell {
        let characteristicCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SILDebugCharacteristicTableViewCell.self)) as! SILDebugCharacteristicTableViewCell
        characteristicCell.delegate = self
        characteristicCell.descriptorDelegate = self
        characteristicCell.configure(withCharacteristicModel: characteristicTableModel)
        characteristicCell.nameEditButton.isHidden = !characteristicTableModel.isMappable
        return characteristicCell
    }
    
    func enumerationFieldCell(with enumerationFieldModel: SILEnumerationFieldRowModel, forTable tableView: UITableView) -> SILDebugCharacteristicEnumerationFieldTableViewCell {
        let enumerationFieldCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SILDebugCharacteristicEnumerationFieldTableViewCell.self)) as! SILDebugCharacteristicEnumerationFieldTableViewCell
        enumerationFieldCell.configure(withEnumerationModel:  enumerationFieldModel)
        enumerationFieldCell.writeChevronImageView.isHidden = true
        return enumerationFieldCell
    }
    
    func encodingFieldCell(with encodingFieldModel: SILEncodingPseudoFieldRowModel, forTable tableView: UITableView) -> SILDebugCharacteristicEncodingFieldTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SILDebugCharacteristicEncodingFieldTableViewCell.self)) as! SILDebugCharacteristicEncodingFieldTableViewCell
        let subjectData = try? encodingFieldModel.dataForField()
        
        //Hidden is set to YES in the Bluetooth Browser feature after adding button properties SLMAIN-276. Hidden state was left conditional in HomeKit feature
        cell.delegate = self
        cell.hexView.valueLabel?.text = SILCharacteristicFieldValueResolver.shared()?.hexString(for: subjectData, decimalExponent: 0)
        cell.asciiView.valueLabel?.text = SILCharacteristicFieldValueResolver.shared().asciiString(for: subjectData).replacingOccurrences(of: "\0", with: "")
        cell.decimalView.valueLabel?.text = SILCharacteristicFieldValueResolver.shared().decimalString(for: subjectData)
        
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    func toggleFieldCell(with toggleFieldModel: SILBitRowModel, forTable tableView: UITableView) -> SILDebugCharacteristicToggleFieldTableViewCell {
        let toggleFieldCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SILDebugCharacteristicToggleFieldTableViewCell.self)) as! SILDebugCharacteristicToggleFieldTableViewCell
        toggleFieldCell.configure(with: toggleFieldModel)
        return toggleFieldCell
    }
    
    func valueFieldCell(with valueFieldModel: SILValueFieldRowModel, forTable tableView: UITableView) -> SILDebugCharacteristicValueFieldTableViewCell {
        let valueFieldCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SILDebugCharacteristicValueFieldTableViewCell.self)) as! SILDebugCharacteristicValueFieldTableViewCell
        valueFieldCell.configure(withValueModel: valueFieldModel)
        //Hidden is set to YES in the Bluetooth Browser feature after adding button properties SLMAIN-276. Hidden state was left conditional in HomeKit feature.
        valueFieldCell.editButton.isHidden = true
        valueFieldCell.editDelegate = self
        return valueFieldCell
    }
    
    // MARK: - SILPopoverViewControllerDelegate
    
    func didClose(_ popoverViewController: SILDebugPopoverViewController?) {
        closePopover({ [self] in
            popoverController = nil
            tableView.reloadData()
        })
    }
    
    // MARK: - SILCharacteristicEditEnablerDelegate
    
    func write(toLocalCharacteristic characteristicModel: SILCharacteristicTableModel!, asLocalIndicate: Bool) throws {
        do {
            let data = try characteristicModel.getDataToWritingToLocalCharacteristic()
            if let characteristic = characteristicModel.characteristic {
                let service = characteristic.service
                if !asLocalIndicate {
                    debugPrint("set local")
                    gattConfiguratorService.writeToLocalCharacteristic(data: data, service: service, characteristic: characteristic)
                } else {
                    debugPrint("update local")
                    gattConfiguratorService.updateLocalCharacteristicValue(data: data, service: service, characteristic: characteristic)
                }
                addOrUpdateModel(characteristic: characteristic, service: service)
                refreshTable()
            }
        } catch let error as NSError {
            throw NSError(domain: error.domain, code: error.code, userInfo: [
                NSUnderlyingErrorKey: error,
                NSLocalizedDescriptionKey: prepareErrorDescription(error)
            ])
        }
    }
    
    func beginValueEdit(withValue valueModel: SILValueFieldRowModel?) { }
    
    func saveCharacteristic(_ characteristicModel: SILCharacteristicTableModel!, with writeType: CBCharacteristicWriteType) throws { }

    func prepareErrorDescription(_ error: Error) -> String {
        let error = error as NSError
        if let errorKind = error.userInfo["errorKind"] as? String {
            if "Parse" == errorKind {
                return prepareParseErrorDescription(error)
            } else if "Range" == errorKind {
                return prepareRangeErrorDescription(error)
            }
        }
        return "Unknown error"
    }
    
    func prepareParseErrorDescription(_ error: Error) -> String {
        return "Input parsing error"
    }
    
    func prepareRangeErrorDescription(_ error: Error) -> String {
        let error = error as NSError
        
        var minRange = error.userInfo["minRange"] as! NSNumber
        var maxRange = error.userInfo["maxRange"] as! NSNumber
        if let valueExponent = error.userInfo["minRange"] as? NSNumber,
           valueExponent != 0 {
            let minDecNumber = NSDecimalNumber(decimal: minRange.decimalValue)
            minRange = minDecNumber.multiplying(byPowerOf10: valueExponent.int16Value)
            
            let maxDecNumber = NSDecimalNumber(decimal: maxRange.decimalValue)
            maxRange = maxDecNumber.multiplying(byPowerOf10: valueExponent.int16Value)
        }
        
        return "Value out of range (\("\(minRange)"), \("\(maxRange)"))"
    }
    
    // MARK: - WYPopoverControllerDelegate
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        closePopover({ [self] in
            self.popoverController = nil
        })
    }
    
    // MARK: - SILMapCellDelegate
    
    func editName(cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let model = modelsToDisplay[indexPath.row]
            if let model = model as? SILServiceTableModel {
                editName(forService: model)
            } else if let model = model as? SILCharacteristicTableModel {
                editName(forCharacteristic: model)
            }
        }
        
    }
    
    func editName(forService model: SILServiceTableModel) {
        let nameEditor = SILMapNameEditorViewController()
        
        var serviceModel = SILServiceMap.get(with: model.uuidString())
        if serviceModel == nil {
            serviceModel = SILServiceMap.create(with: model.name(), uuid: model.uuidString())
        }
        nameEditor.model = serviceModel
        nameEditor.popoverDelegate = self
        popoverController = WYPopoverController.sil_presentCenterPopover(
            withContentViewController: nameEditor,
            presenting: self,
            delegate: self,
            animated: true)
    }
    
    func editName(forCharacteristic model: SILCharacteristicTableModel) {
        let nameEditor = SILMapNameEditorViewController()
        var characteristicModel = SILCharacteristicMap.get(with: model.uuidString())
        if characteristicModel == nil {
            characteristicModel = SILCharacteristicMap.create(with: model.name(), uuid: model.uuidString())
        }
        nameEditor.model = characteristicModel
        nameEditor.popoverDelegate = self
        popoverController = WYPopoverController.sil_presentCenterPopover(
            withContentViewController: nameEditor,
            presenting: self,
            delegate: self,
            animated: true)
    }
    
    // MARK: - SILDebugCharacteristicCellDelegate

    func cell(_ cell: SILDebugCharacteristicTableViewCell!, didRequestReadFor characteristic: CBCharacteristic!) {
        debugPrint("read request")
        let isPerformed = cell.characteristicTableModel.clear()
        if !isPerformed {
            performManualClearingValues(intoEncodingFieldTableViewCell: characteristic)
        } else {
            refreshTable()
        }
        if let characteristic = characteristic {
            addOrUpdateModel(characteristic: characteristic, service: characteristic.service)
            refreshTable()
        }
    }
    
    func performManualClearingValues(intoEncodingFieldTableViewCell characteristic: CBCharacteristic) {
        for (index, model) in modelsToDisplay.enumerated() {
            if let characteristicModel = model as? SILCharacteristicTableModel,
               characteristicModel.isUnknown,
               characteristicModel.characteristic == characteristic,
               let cell = tableView.cellForRow(at: IndexPath(row: index + 1, section: 0)) as? SILDebugCharacteristicEncodingFieldTableViewCell {
                        cell.clearValues()
            }
        }
    }
    
    func cell(_ cell: SILDebugCharacteristicTableViewCell!, didRequestWriteFor characteristic: CBCharacteristic!) {
        handleWritingRequest(characteristic, asIndicate: false)
    }
    
    func cell(_ cell: SILDebugCharacteristicTableViewCell!, didRequestNotifyFor characteristic: CBCharacteristic!, withValue value: Bool) {
        handleWritingRequest(characteristic, asIndicate: true)
    }

    func cell(_ cell: SILDebugCharacteristicTableViewCell!, didRequestIndicateFor characteristic: CBCharacteristic!, withValue value: Bool) {
        handleWritingRequest(characteristic, asIndicate: true)
    }
    
    private func handleWritingRequest(_ characteristic: CBCharacteristic!, asIndicate: Bool) {
        refreshTable()
        let characteristicWriteViewController = SILCharacteristicWriteViewController(characteristic: characteristic, asLocalIndicate: asIndicate, delegate: self)
        characteristicWriteViewController.popoverDelegate = self
        popoverController = WYPopoverController.sil_presentCenterPopover(
            withContentViewController: characteristicWriteViewController,
            presenting: self,
            delegate: self,
            animated: true)
    }
    
    // MARK: = SILDescriptorsTableViewCellDelegate
    
    func cellDidRequestReadForDescriptor(_ descriptor: CBDescriptor?) {
        if let descriptor = descriptor {
            peripheral.readValue(for: descriptor)
        }
        refreshTable()
    }
    
    // MARK: - CBPeripheralDelegate
    
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            debugPrint(error.localizedDescription)
        }
        rssiLabel.isHidden = false
        rssiImageView.isHidden = false
        var rssiDescription = "\(RSSI)"
        rssiDescription += " dBm"
        rssiLabel.text = rssiDescription
    }
    
    // MARK: - Add or Update Attribute Models
    
    func addOrUpdateModel(service: CBService?) {
        if let serviceModel = findServiceModel(for: service) {
            serviceModel.service = service
        } else {
            if let serviceModel = SILServiceTableModel(service: service) {
                allServiceModels.append(serviceModel)
            }
        }
    }
    
    func addOrUpdateModel(characteristic: CBCharacteristic?, service: CBService?) {
        if let serviceModel = findServiceModel(for: service) {
            if let characteristicModel =  findCharacteristicModel(for: characteristic, forServiceModel: serviceModel) {
                characteristicModel.characteristic = characteristic
                characteristicModel.updateRead(characteristic)
            } else {
                var mutableCharacteristicModels = serviceModel.characteristicModels ?? []
                let characteristicModel = SILCharacteristicTableModel(characteristic: characteristic)!
                characteristicModel.updateRead(characteristic)
                mutableCharacteristicModels.append(characteristicModel)
                serviceModel.characteristicModels = mutableCharacteristicModels
            }
        }
    }
    
    func addOrUpdateModel(descriptor: CBDescriptor?, characteristic: CBCharacteristic?) {
        if let service = characteristic?.service,
           let serviceModel = findServiceModel(for: service),
           let characteristicModel = findCharacteristicModel(for: characteristic, forServiceModel: serviceModel) {
            if let descriptorModel = findDescriptorModel(for: descriptor, forCharacteristicModel: characteristicModel) {
                descriptorModel.descriptor = descriptor
            } else {
                var mutableDescriptorModels = characteristicModel.descriptorModels ?? []
                let descriptorModel = SILDescriptorTableModel(descriptor: descriptor)!
                mutableDescriptorModels.append(descriptorModel)
                characteristicModel.descriptorModels = mutableDescriptorModels
            }
        }
    }
    
    func characteristicModels(forCharacteristics characteristics: [CBCharacteristic]) -> [SILCharacteristicTableModel]? {
        var characteristicModels = [SILCharacteristicTableModel]()
        for characteristic in characteristics {
            if let characteristicModel = SILCharacteristicTableModel(characteristic: characteristic) {
                characteristicModels.append(characteristicModel)
            }
        }
        return characteristicModels
    }
    
    func descriptorModels(forDescriptors descriptors: [CBDescriptor]) -> [SILDescriptorTableModel] {
        var descriptorModels = [SILDescriptorTableModel]()
        for descriptor in descriptors {
            if let attributeModel = SILDescriptorTableModel(descriptor: descriptor) {
                descriptorModels.append(attributeModel)
            }
        }
        return descriptorModels
    }
    
    // MARK: - Find Attribute Models
    
    func findServiceModel(for service: CBService?) -> SILServiceTableModel? {
        return allServiceModels.first { $0.service.uuid == service?.uuid }
    }
    
    func findCharacteristicModel(for characteristic: CBCharacteristic?, forServiceModel serviceModel: SILServiceTableModel?) -> SILCharacteristicTableModel? {
        if let serviceModel = serviceModel, let characteristics = serviceModel.characteristicModels as? [SILCharacteristicTableModel] {
            return characteristics.first { $0.characteristic == characteristic }
        }
        return nil
    }
    
    func findDescriptorModel(for descriptor: CBDescriptor?, forCharacteristicModel characteristicModel: SILCharacteristicTableModel?) -> SILDescriptorTableModel? {
        if let characteristicModel = characteristicModel, let descriptors = characteristicModel.descriptorModels as? [SILDescriptorTableModel] {
            return descriptors.first { $0.descriptor == descriptor }
        }
        return nil
    }
    
    // MARK: - Display Array
    
    func buildAllServiceModels() {
        if let _ = runningConfiguration {
            for service in gattConfiguratorService.helper.services {
                addOrUpdateModel(service: service)
                for characteristic in service.characteristics ?? [] {
                    addOrUpdateModel(characteristic: characteristic, service: service)
                    for descriptor in characteristic.descriptors ?? [] {
                        addOrUpdateModel(descriptor: descriptor, characteristic: characteristic)
                    }
                }
            }
        }
        debugPrint("allservicemodels ", allServiceModels.count)
    }
    
    func buildDisplayArray() -> [AnyHashable] {
        var displayArray: [AnyHashable] = []
        
        if let _ = runningConfiguration {
            var firstService = true
            for serviceModel in allServiceModels {
                serviceModel.hideTopSeparator = firstService
                displayArray.append(serviceModel)
                
                if serviceModel.isExpanded {
                    buildDisplayCharacteristics(&displayArray, forServiceModel: serviceModel)
                }
                firstService = false
                displayArray.append(kSpacerCellIdentifieer)
            }
        }
        
        debugPrint("display array", displayArray.count)
        return displayArray
    }
    
    func buildDisplayCharacteristics(_ displayArray: inout [AnyHashable], forServiceModel serviceModel: SILServiceTableModel) {
        if let characteristicModels = serviceModel.characteristicModels as? [SILCharacteristicTableModel] {
            for characteristicModel in characteristicModels {
                characteristicModel.hideTopSeparator = false
                displayArray.append(characteristicModel)

                if characteristicModel.isExpanded {
                    buildDisplayCharacteristicFields(&displayArray, forCharacteristicModel: characteristicModel)
                }
            }
        }
    }
    
    func buildDisplayCharacteristicFields(_ displayArray: inout [AnyHashable], forCharacteristicModel characteristicModel: SILCharacteristicTableModel) {
        if characteristicModel.isUnknown {
            // We are unknown. But lets display our encoding information as if we were a field.
            displayArray.append(SILEncodingPseudoFieldRowModel(forCharacteristicModel: characteristicModel))
        } else {
            for fieldModel in characteristicModel.fieldTableRowModels {
                if let fieldModel = fieldModel as? SILCharacteristicFieldRow {
                    fieldModel.parentCharacteristicModel = characteristicModel
                    if fieldModel.requirementsSatisfied {
                        fieldModel.hideTopSeparator = false
                        if let bitFieldModel = fieldModel as? SILBitFieldFieldModel {
                            displayArray.append(contentsOf: bitFieldModel.bitRowModels())
                        } else {
                            displayArray.append(fieldModel as! AnyHashable)
                        }
                    } else {
                        debugPrint("Requirements not met for \(characteristicModel.bluetoothModel.name ?? "")")
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers

    func refreshTable() {
        modelsToDisplay = buildDisplayArray()
        tableView.reloadData()
    }
    
    func configureOtaButton(with peripheral: CBPeripheral?) {
        if let peripheral = peripheral, peripheral.hasOTAService() {
            menuButton.isHidden = false
        } else {
            menuButton.isHidden = true
        }
    }

    // MARK: - SILBrowserLogViewControllerDelegate

    func logViewBackButtonPressed() {
        browserExpandableViewManager.removeExpandingControllerIfNeeded()
    }
    
    // MARK: - SILBrowserConnectionViewControllerDelegate
    
    func connectionsViewBackButtonPressed() {
        browserExpandableViewManager.removeExpandingControllerIfNeeded()
    }
    
    func presentDetailsViewController(for index: Int) {
        browserExpandableViewManager.removeExpandingControllerIfNeeded()
        let connectedPeripheral = connectionsViewModel.peripherals[index] as SILConnectedPeripheralDataModel
        peripheral = connectedPeripheral.peripheral
        allServiceModels = []
        viewDidLoad()
        viewWillAppear(true)
        viewDidAppear(true)
        connectionsViewModel.updateConnectionsView(index)
    }
    
    // MARK: - SILDebugCharacteristicEncodingFieldTableViewCellDelegate
    
    func copyButtonWasClicked() {
        showToast(message: "Copied to clipboard!", toastType: .info, shouldHasSizeOfText: true) {
        }
    }

    // MARK: - SILErrorDetailsViewController
    
    func shouldCloseErrorDetailsViewController(_ errorDetailsViewController: SILErrorDetailsViewController) {
        closePopover({ [self] in
            popoverController = nil
        })
    }

    func closePopover(_ completion: @escaping () -> Void) {
        popoverController?.dismissPopover(animated: true, completion: completion)
    }
}
