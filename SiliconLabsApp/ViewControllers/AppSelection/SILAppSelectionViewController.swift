//
//  SILAppSelectionViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 22.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import SVProgressHUD

@objcMembers
class SILAppSelectionViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SILDeviceSelectionViewControllerDelegate, WYPopoverControllerDelegate, SILAppSelectionInfoViewControllerDelegate, SILThunderboardDeviceSelectionViewControllerDelegate {
    var appsArray: [SILApp] = SILApp.demoApps()
    var isDisconnectedIntentionally: Bool = false

    @IBOutlet var allSpace: UIView!
    @IBOutlet weak var tilesSpace: UIStackView!
    @IBOutlet weak var appsView: UIView!
    @IBOutlet weak var appCollectionView: UICollectionView!
    private var devicePopoverController: WYPopoverController?

    private var peripheralManagerSubscription: SILObservableToken?
    private var disposeBag = SILObservableTokenBag()
    private var peripheralManager: SILThroughputPeripheralManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAppCollectionView()
        self.setupBackground()
        self.addObserverForNonIntentionallyBackFromThermometer()
        self.isDisconnectedIntentionally = false
        SILBluetoothModelManager.shared()?.populateModels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isDisconnectedIntentionally {
            self.showThermometerPopover()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.appCollectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupAppCollectionView() {
        self.registerNibs()
        self.setupAppCollectionViewDelegates()
        self.setupAppCollectionViewAppearance()
    }
    
    private func registerNibs() {
        self.appCollectionView.register(UINib(nibName: String(describing: SILAppSelectionCollectionViewCell.self), bundle:nil), forCellWithReuseIdentifier:String(describing: SILAppSelectionCollectionViewCell.self))
    }
    
    private func setupAppCollectionViewDelegates() {
        self.appCollectionView.dataSource = self
        self.appCollectionView.delegate = self
    }
    
    private func setupAppCollectionViewAppearance() {
        self.appCollectionView.backgroundColor = UIColor.sil_background()
        self.appCollectionView.alwaysBounceVertical = true
    }
    
    private func setupBackground() {
        self.allSpace.backgroundColor = UIColor.sil_background()
        self.appsView.backgroundColor = UIColor.sil_background()
    }

    private func addObserverForNonIntentionallyBackFromThermometer() {
        NotificationCenter.default.addObserver(self, selector: #selector(setIsDisconnectedIntentionallyFlag), name: NSNotification.Name(rawValue: "NotIntentionallyBackFromThermometer"), object:nil)
    }
    
    private func presentDeviceSelectionViewController(app: SILApp!, shouldConnectWithPeripheral shouldConnect: Bool = true, animated: Bool,
                                                      filter: DiscoveredPeripheralFilter? = nil) {
        var viewModel: SILDeviceSelectionViewModel?
        if let filter = filter {
            viewModel = SILDeviceSelectionViewModel(appType: app, withFilter: filter)
        }
        else {
            viewModel = SILDeviceSelectionViewModel(appType: app)
        }
        let selectionViewController = SILDeviceSelectionViewController(deviceSelectionViewModel: viewModel!, shouldConnect: shouldConnect)
        selectionViewController.centralManager = SILBrowserConnectionsViewModel.sharedInstance()!.centralManager!
        selectionViewController.delegate = self
        self.devicePopoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: selectionViewController, presenting: self,
                                                                                    delegate: self, animated: true)
    }
    
    private func presentThunderboardDeviceSelection(app: SILApp!, animated: Bool, filter: ((Device) -> Bool)? = nil) {
        let thunderboardCentralManager = BleManager()
        let interaction = DeviceSelectionInteraction(scanner: thunderboardCentralManager, connector: thunderboardCentralManager, appType: app.appType, filter: filter)
        let selectionViewController = SILThunderboardDeviceSelectionViewController(interaction: interaction, appType: app.appType)
        selectionViewController.delegate = self
        
        self.devicePopoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: selectionViewController, presenting: self, delegate: self, animated: true)
    }

    private func showRangeTest(app: SILApp!, animated: Bool) {
        let storyboard = UIStoryboard(name: "SILAppTypeRangeTest", bundle: nil)
        if let viewController = storyboard.instantiateInitialViewController() {
            self.navigationController?.pushViewController(viewController, animated: animated)
        }

    }
    
    private func showRSSIGraph(app: SILApp!, animated: Bool) {
        let storyboard = UIStoryboard(name: "SILAppRSSIGraph", bundle: nil)
        if let viewController = storyboard.instantiateInitialViewController() {
            self.navigationController?.pushViewController(viewController, animated: animated)
        }
    }
    
    private func didSelectApp(app: SILApp!) {
        debugPrint("didSelectItem \(String(describing: app.title))")
        switch app.appType {
        case .typeConnectedLighting,
             .typeHealthThermometer:
            self.presentDeviceSelectionViewController(app: app, animated: true)
        
        case .typeBlinky:
            self.presentThunderboardDeviceSelection(app: app, animated: true) { $0.isThunderboardDevice() || $0.name!.hasPrefix("Blinky") }
        
        case .typeMotion:
            self.presentThunderboardDeviceSelection(app: app, animated: true) { $0.isThunderboardDevice() }
            
        case .typeEnvironment:
            self.presentThunderboardDeviceSelection(app: app, animated: true) { $0.isThunderboardDevice() }
            
        case .typeThroughput:
            peripheralManager = SILThroughputPeripheralManager()
            
            weak var weakSelf = self
            peripheralManagerSubscription = peripheralManager.state.observe({ state in
                guard let weakSelf = weakSelf else { return }
                switch state {
                case .poweredOn:
                    weakSelf.peripheralManager.startAdveritising()
                    weakSelf.peripheralManagerSubscription?.invalidate()
                    
                default:
                    break
                }
            })
            self.disposeBag.add(token: peripheralManagerSubscription!)
            
            self.presentDeviceSelectionViewController(app: app, animated: true) { $0!.advertisedLocalName == "Throughput Test" }
            
        case .typeRangeTest:
            self.showRangeTest(app: app, animated: true)

        case .iopTest:
            self.presentDeviceSelectionViewController(app: app, shouldConnectWithPeripheral: false, animated: true) { $0!.advertisedLocalName?.contains("IOP") ?? false }
            
        case .typeWifiCommissioning:
            self.presentDeviceSelectionViewController(app: app, animated: true) { $0!.advertisedLocalName == "BLE_CONFIGURATOR" }
            
        default:
            return
        }
    }

    private func infoButtonTapped(recognizer: UITapGestureRecognizer) {
        self.presentAppSelectionInfoViewController(animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.appsArray.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SILAppSelectionCollectionViewCell.self), for: indexPath) as? SILAppSelectionCollectionViewCell
        let app = self.appsArray[indexPath.row]
        cell?.setFieldsIn(app)
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellsInRow = 2.0
        let minimumLineSpacing = 16.0
        let width = floor(Double((self.appCollectionView.frame.size.width - self.appCollectionView.contentInset.left - self.appCollectionView.contentInset.right - self.appCollectionView.alignmentRectInsets.left - self.appCollectionView.alignmentRectInsets.right)) / cellsInRow) - minimumLineSpacing
        
        let height = 168.0
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let app = self.appsArray[indexPath.row]
        self.didSelectApp(app: app)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    func deviceSelectionViewController(_ viewController: SILDeviceSelectionViewController!, didSelect peripheral: SILDiscoveredPeripheral!) {
        self.devicePopoverController?.dismissPopover(animated: true) { [self] in
            self.devicePopoverController = nil
            let appType = viewController.viewModel.app.appType
            
            switch appType {
            case .typeHealthThermometer:
                guard let peripheral = peripheral.peripheral else { return }
                self.runHealthThermometer(viewController: viewController, peripheral: peripheral)
            
            case .typeConnectedLighting:
                if let connectedLightingController = UIStoryboard(name: "SILAppTypeConnectedLighting", bundle: nil).instantiateInitialViewController() as? SILConnectedLightingViewController {
                    connectedLightingController.centralManager = viewController.centralManager
                    connectedLightingController.connectedPeripheral = peripheral.peripheral
                    self.navigationController?.pushViewController(connectedLightingController, animated: true)
                }
 
            case .typeThroughput:
                if let throughputController = UIStoryboard(name: "SILAppTypeThroughput", bundle: nil).instantiateInitialViewController() as? SILThroughputViewController {
                    throughputController.peripheralManager = peripheralManager
                    throughputController.centralManager = viewController.centralManager
                    throughputController.connectedPeripheral = peripheral.peripheral
                    self.navigationController?.pushViewController(throughputController, animated: true)
                }
                
            case .typeWifiCommissioning:
                if let wifiCommissioningController = UIStoryboard(name: "SILAppTypeWifiCommissioning", bundle: nil).instantiateInitialViewController() as? SILWifiCommissioningViewController {
                    wifiCommissioningController.centralManager = viewController.centralManager
                    wifiCommissioningController.connectedPeripheral = peripheral.peripheral
                    self.navigationController?.pushViewController(wifiCommissioningController, animated: true)
                }
                
            case .iopTest:
                let storyboard = UIStoryboard(name: "SILIOPTest", bundle: nil)
                if let iopVC = storyboard.instantiateInitialViewController() as? SILIOPTesterViewController {
                    iopVC.deviceNameToSearch = peripheral.advertisedLocalName
                    self.navigationController?.pushViewController(iopVC, animated: true)

                }
                
            default:
                break
            }
        }
    }
    
    func didDismissDeviceSelectionViewController() {
        if let peripheralManager = peripheralManager {
            peripheralManager.stopAdvertising()
        }
        
        self.devicePopoverController?.dismissPopover(animated: true)
    }

    func runHealthThermometer(viewController: SILDeviceSelectionViewController, peripheral: CBPeripheral) {
        let storyboard = UIStoryboard(name: "SILAppTypeHealthThermometer", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()
        if let healthThermometerController = controller as? SILHealthThermometerAppViewController {
            healthThermometerController.centralManager = viewController.centralManager
            healthThermometerController.app = viewController.viewModel.app
            healthThermometerController.connectedPeripheral = peripheral
            self.navigationController?.pushViewController(healthThermometerController, animated: true)
        }
    }

    func presentAppSelectionInfoViewController(animated: Bool) {
        let infoViewController = SILAppSelectionInfoViewController()
        infoViewController.delegate = self
        self.devicePopoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: infoViewController, presenting: self, delegate: self, animated: true)
    }
    
    func didFinishInfo(with infoViewController: SILAppSelectionInfoViewController!) {
        self.devicePopoverController?.dismissPopover(animated: true) {
            self.devicePopoverController = nil
        }
    }
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        self.devicePopoverController?.dismissPopover(animated: true)
        self.devicePopoverController = nil
    }
    
    @objc func setIsDisconnectedIntentionallyFlag() {
        self.isDisconnectedIntentionally = true
    }

    func showThermometerPopover() {
        let apps = SILApp.demoApps() as! [SILApp]
        self.presentDeviceSelectionViewController(app: apps[0], animated: true)
        self.isDisconnectedIntentionally = false
    }
    
    func showIOPTestList(text: String) {
        let storyboard = UIStoryboard(name: "SILIOPTest", bundle: nil)
        if let iopVC = storyboard.instantiateInitialViewController() as? SILIOPTesterViewController {
            iopVC.deviceNameToSearch = text
            self.navigationController?.pushViewController(iopVC, animated: true)
        }
    }
    
    func didTappedOKButton(deviceName text: String, bluetoothState: Bool) {
        self.devicePopoverController?.dismissPopover(animated: true)
        self.devicePopoverController = nil
        if bluetoothState {
            self.showIOPTestList(text: text)
        } else {
            let bluetoothDisabledAlert = SILBluetoothDisabledAlert.interoperabilityTest
            self.alertWithOKButton(title: bluetoothDisabledAlert.title,
                                   message: bluetoothDisabledAlert.message,
                                   completion: nil)
        }
    }
    
    func didTappedCancelButton() {
        self.devicePopoverController?.dismissPopover(animated: true)
        self.devicePopoverController = nil
    }
    
    // MARK: SILThunderboardDeviceSelectionViewControllerDelegate
    
    func deviceSelectionViewControllerDidFinishThunderboardDeviceConfiguration(connection: DemoConnection, deviceConnector: DeviceConnection, appType: SILAppType) {
        SVProgressHUD.dismiss()
        self.devicePopoverController?.dismissPopover(animated: true) {
            switch appType {
            case .typeMotion:
                if let motionConnection = connection as? MotionDemoConnection, motionConnection.device.model == .sense || motionConnection.device.model == .bobcat {
                    self.displayMotion(connection: motionConnection, deviceConnector: deviceConnector)
                }
            case .typeEnvironment:
                if let environmentConnection = connection as? EnvironmentDemoConnection {
                    self.displayEnvironment(connection: environmentConnection, deviceConnector: deviceConnector)
                }
            case .typeBlinky:
                if let ioConnection = connection as? IoDemoConnection {
                    self.displayIO(connection: ioConnection, deviceConnector: deviceConnector)
                }
            default:
                return
            }
        }
    }
    
    func deviceSelectionViewControllerDidConnectWithBlinkyDevice(device: Device, deviceConnector: DeviceConnection, isThunderboard: Bool) {
        self.devicePopoverController?.dismissPopover(animated: true) {
            self.displayBlinky(device: device, deviceConnector: deviceConnector, shouldDisplayPower: isThunderboard)
        }
    }
    
    private func displayBlinky(device: Device, deviceConnector: DeviceConnection, shouldDisplayPower: Bool) {
        if let blinkyController = UIStoryboard(name: "SILAppTypeBlinky", bundle: nil).instantiateInitialViewController() as? SILAppTypeBlinkyViewController, let device = device as? BleDevice {
            blinkyController.deviceConnector = deviceConnector
            blinkyController.connectedPeripheral = device.cbPeripheral
            blinkyController.deviceName = device.name!
            if shouldDisplayPower {
                blinkyController.addConnectedDeviceBar(bottomNotchHeight: 0.0)
            }
            self.navigationController?.pushViewController(blinkyController, animated: true)
        }
    }
    
    private func displayMotion(connection: MotionDemoConnection, deviceConnector: DeviceConnection) {
        if let demoViewController = UIStoryboard(name: "MotionSenseBoardDemoViewController", bundle: nil).instantiateViewController(withIdentifier: "MotionSenseBoardDemoViewController") as? MotionSenseBoardDemoViewController {
            
            let interaction = MotionDemoInteraction(output: demoViewController, demoConnection: connection)
            demoViewController.interaction = interaction
            demoViewController.deviceConnector = deviceConnector
            demoViewController.deviceModelName = connection.device.modelName
            demoViewController.addConnectedDeviceBar(bottomNotchHeight: 0.0)
            connection.device.connectedDelegate = demoViewController
            self.navigationController?.pushViewController(demoViewController, animated: true)
        }
    }
    
    private func displayEnvironment(connection: EnvironmentDemoConnection, deviceConnector: DeviceConnection) {
        if let demoViewController = UIStoryboard(name: "EnvironmentDemoViewController", bundle: nil).instantiateViewController(withIdentifier: "EnvironmentDemoViewController") as? EnvironmentDemoViewController {
            let interaction = EnvironmentDemoInteraction(output: demoViewController, demoConnection: connection)
            demoViewController.interaction = interaction
            demoViewController.deviceConnector = deviceConnector
            demoViewController.addConnectedDeviceBar(bottomNotchHeight: 0.0)
            connection.device.connectedDelegate = demoViewController
            self.navigationController?.pushViewController(demoViewController, animated: true)
            
        }
    }
    
    private func displayIO(connection: IoDemoConnection, deviceConnector: DeviceConnection) {
        if let demoViewController = UIStoryboard(name: "IoDemoViewController", bundle: nil).instantiateViewController(withIdentifier: "IoDemoViewController") as? IoDemoViewController {
            
            let interaction = IoDemoInteraction(output: demoViewController, demoConnection: connection)
            demoViewController.interaction = interaction
            
            demoViewController.deviceConnector = deviceConnector
            demoViewController.addConnectedDeviceBar(bottomNotchHeight: 0.0)
            connection.device.connectedDelegate = demoViewController
            self.navigationController?.pushViewController(demoViewController, animated: true)
        }
    }
}
