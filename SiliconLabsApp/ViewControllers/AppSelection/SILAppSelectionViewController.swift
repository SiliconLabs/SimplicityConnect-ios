//
//  SILAppSelectionViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 22.3.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

@objcMembers
class SILAppSelectionViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SILDeviceSelectionViewControllerDelegate, WYPopoverControllerDelegate, SILAppSelectionInfoViewControllerDelegate, SILIOPPopupDelegate {
    var appsArray: [SILApp] = [SILApp]()
    var isDisconnectedIntentionally: Bool = false

    @IBOutlet var allSpace: UIView!
    @IBOutlet weak var tilesSpace: UIStackView!
    @IBOutlet weak var appsView: UIView!
    @IBOutlet weak var appCollectionView: UICollectionView!
    @IBOutlet weak var infoImage: UIImageView!
    @IBOutlet weak var aboveSafeAreaView: UIView!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var navigationBarTitleLabel: UILabel!
    private var devicePopoverController: WYPopoverController!

    private var peripheralManagerSubscription: SILObservableToken?
    private var disposeBag = SILObservableTokenBag()
    private var peripheralManager: SILThroughputPeripheralManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAppCollectionView()
        self.setupBackground()
        self.setupNavigationBar()
        self.addObserverForNonIntentionallyBackFromThermometer()
        self.isDisconnectedIntentionally = false
        SILBluetoothModelManager.shared()?.populateModels()
        self.allSpace.bringSubviewToFront(self.navigationBarView)
        self.appCollectionView.bounces = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isDisconnectedIntentionally {
            self.showThermometerPopover()
        }
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
    
    private func setupNavigationBar() {
        self.setupNavigationBarBackgroundColor()
        self.setupNavigationBarTitleLabel()
        self.addGestureRecognizerForInfoImage()
    }

    private func setupNavigationBarBackgroundColor() {
        self.aboveSafeAreaView.backgroundColor = UIColor.sil_siliconLabsRed()
        self.navigationBarView.backgroundColor = UIColor.sil_siliconLabsRed()
    }
    
    private func setupNavigationBarTitleLabel() {
        self.navigationBarTitleLabel.font = UIFont.robotoMedium(size: CGFloat(SILNavigationBarTitleFontSize))
        self.navigationBarTitleLabel.textColor = UIColor.sil_background()
    }

    private func addGestureRecognizerForInfoImage() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedInfoImage(_:)))
        self.infoImage.addGestureRecognizer(tap)
    }
    
    @objc private func tappedInfoImage(_ gestureRecognizer: UIGestureRecognizer) {
        self.presentAppSelectionInfoViewController(animated: true)
    }

    private func addObserverForNonIntentionallyBackFromThermometer() {
        NotificationCenter.default.addObserver(self, selector: #selector(setIsDisconnectedIntentionallyFlag), name: NSNotification.Name(rawValue: "NotIntentionallyBackFromThermometer"), object:nil)
    }
    
    private func presentDeviceSelectionViewController(app: SILApp!, filterByName: String? = nil, animated: Bool) {
        var viewModel: SILDeviceSelectionViewModel?
        if let filterByName = filterByName {
            viewModel = SILDeviceSelectionViewModel(appType: app, withFilterByName: filterByName)
        } else {
            viewModel = SILDeviceSelectionViewModel(appType: app)
        }
        let selectionViewController = SILDeviceSelectionViewController(deviceSelectionViewModel: viewModel)
        selectionViewController?.centralManager = SILBrowserConnectionsViewModel.sharedInstance()!.centralManager!
        selectionViewController?.delegate = self
        self.devicePopoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: selectionViewController, presenting: self, delegate: self, animated: true)
    }

    private func presentCalibrationViewController(animated: Bool) {
        debugPrint("Do nothing - app is deprecated")
    }

    private func showRetailBeaconApp(app: SILApp!, animated: Bool) {
        debugPrint("Do nothing - app is deprecated")
    }

    private func showBluetoothBrowser(app: SILApp!, animated: Bool) {
        let storyboard = UIStoryboard(name: "SILAppBluetoothBrowser", bundle: nil)
        if let viewController = storyboard.instantiateInitialViewController() {
            self.navigationController?.pushViewController(viewController, animated: animated)
        }
    }

    private func showAdvertiser(app: SILApp!, animated: Bool) {
        let wireframe: SILAdvertiserHomeWireframeType = SILAdvertiserHomeWireframe()
        self.navigationController?.pushViewController(wireframe.viewController, animated: true)
        wireframe.releaseViewController()
    }

    private func showGattConfigurator(app: SILApp!, animated: Bool) {
        let wireframe : SILGattConfiguratorHomeWireframeType = SILGattConfiguratorHomeWireframe()
        self.navigationController?.pushViewController(wireframe.viewController, animated: animated)
        wireframe.releaseViewController()
    }

    private func showHomeKitDebug(app: SILApp!, animated: Bool) {
        #if ENABLE_HOMEKIT
            let viewController = SILHomeKitDebugDeviceViewController()
            viewController.app = app
            self.navigationController?.pushViewController(viewController!, animated: animated)
        #endif
    }

    private func showRangeTest(app: SILApp!, animated: Bool) {
        let storyboard = UIStoryboard(name: "SILAppTypeRangeTest", bundle: nil)
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
            self.presentDeviceSelectionViewController(app: app, filterByName: "Blinky Example", animated: true)
        
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
            
            self.presentDeviceSelectionViewController(app: app, filterByName: "Throughput Test", animated: true)
            
        case .typeRangeTest:
            self.showRangeTest(app: app, animated: true)
            
        case .typeRetailBeacon:
            self.showRetailBeaconApp(app: app, animated: true)
            
        case .bluetoothBrowser:
            self.showBluetoothBrowser(app: app, animated: true)
            
        case .typeAdvertiser:
            self.showAdvertiser(app: app, animated: true)
            
        case .typeHomeKitDebug:
            self.showHomeKitDebug(app: app, animated: true)

        case .typeGATTConfigurator:
            self.showGattConfigurator(app: app, animated: true)
            
        case .iopTest:
             self.showIOPEnterDeviceNamePopup(app: app, animated: true)
            
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
        
        let height = 182.0
        
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
    
    func deviceSelectionViewController(_ viewController: SILDeviceSelectionViewController!, didSelect peripheral: CBPeripheral!) {
        self.devicePopoverController.dismissPopover(animated: true) { [self] in
            self.devicePopoverController = nil
            let appType = viewController.viewModel.app.appType
            
            switch appType {
            case .typeHealthThermometer:
                self.runHealthThermometer(viewController: viewController, peripheral: peripheral)
            
            case .typeConnectedLighting:
                if let connectedLightingController = UIStoryboard(name: "SILAppTypeConnectedLighting", bundle: nil).instantiateInitialViewController() as? SILConnectedLightingViewController {
                    connectedLightingController.centralManager = viewController.centralManager
                    connectedLightingController.connectedPeripheral = peripheral
                    self.navigationController?.pushViewController(connectedLightingController, animated: true)
                }
        
            case .typeBlinky:
                if let blinkyController = UIStoryboard(name: "SILAppTypeBlinky", bundle: nil).instantiateInitialViewController() as? SILAppTypeBlinkyViewController {
                    blinkyController.centralManager = viewController.centralManager
                    blinkyController.connectedPeripheral = peripheral
                    self.navigationController?.pushViewController(blinkyController, animated: true)
                }
 
            case .typeThroughput:
                if let throughputController = UIStoryboard(name: "SILAppTypeThroughput", bundle: nil).instantiateInitialViewController() as? SILThroughputViewController {
                    throughputController.peripheralManager = peripheralManager
                    throughputController.centralManager = viewController.centralManager
                    throughputController.connectedPeripheral = peripheral
                    self.navigationController?.pushViewController(throughputController, animated: true)
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
        
        self.devicePopoverController.dismissPopover(animated: true)
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
        self.devicePopoverController .dismissPopover(animated: true) {
            self.devicePopoverController = nil
        }
    }
    
    func popoverControllerDidDismissPopover(_ popoverController: WYPopoverController!) {
        self.devicePopoverController .dismissPopover(animated: true)
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
    
    func showIOPEnterDeviceNamePopup(app: SILApp, animated: Bool) {
        let popupVC = SILIOPDeviceNamePopup()
        popupVC.delegate = self
        self.devicePopoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: popupVC,
                                                                                    presenting: self,
                                                                                    delegate: self,
                                                                                    animated: true)
    }
    
    func showIOPTestList(text: String) {
        let storyboard = UIStoryboard(name: "SILIOPTest", bundle: nil)
        if let iopVC = storyboard.instantiateInitialViewController() as? SILIOPTesterViewController {
            iopVC.deviceNameToSearch = text
            self.navigationController?.pushViewController(iopVC, animated: true)
        }
    }
    
    func didTappedOKButton(deviceName text: String, bluetoothState: Bool) {
        self.devicePopoverController.dismissPopover(animated: true)
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
        self.devicePopoverController.dismissPopover(animated: true)
        self.devicePopoverController = nil
    }
}
