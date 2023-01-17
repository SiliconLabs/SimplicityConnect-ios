//
//  EnvironmentDemoViewController.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

class EnvironmentDemoViewController: DemoViewController, EnvironmentDemoInteractionOutput, UICollectionViewDelegate, SILThunderboardConnectedDeviceBar, ConnectedDeviceDelegate {
    
    var connectedDeviceView: ConnectedDeviceBarView?
    var connectedDeviceBarHeight: CGFloat = 70.0

    @IBOutlet var collectionView: UICollectionView!
    var interaction: EnvironmentDemoInteraction?
    var deviceConnector: DeviceConnection?
    
    fileprivate var dataSource = EnvironmentDemoCollectionViewDataSource()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        
        setupNavigationBar()
        
        dataSource.activeViewModels.debounce(.milliseconds(500), scheduler: MainScheduler.instance).bind(to: collectionView.rx.items(cellIdentifier: EnvironmentCollectionViewCell.cellIdentifier, cellType: EnvironmentCollectionViewCell.self)){(_, element, cell) in
            cell.configureCell(with: element)
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected.withLatestFrom(dataSource.activeViewModels).debug().subscribe(onNext: { [weak self] viewModels in
            guard let strongSelf = self,
                let indexPath = strongSelf.collectionView.indexPathsForSelectedItems?.first,
                indexPath.item < viewModels.count else {
                    return
            }
            let viewModel = viewModels[indexPath.item]
            if viewModel.capability == .hallEffectState {
                if strongSelf.dataSource.currentHallEffectState == .tamper {
                    strongSelf.interaction?.resetTamperState()
                } else {
                    print("Current state is not tamper")
                }
            }
        }).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(forName: SettingsViewController.temperatureSettingUpdated, object: nil, queue: nil) { (notification) in
            self.dataSource.update()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.interaction?.checkMissingSensors()
        self.interaction?.updateView()
        self.navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deviceConnector?.disconnectAllDevices()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.tabBarController?.showTabBarAndUpdateFrames()
    }
    
    private func setupNavigationBar() {
        setLeftAlignedTitle("Environment")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "developOff"),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(settingsButtonPressed))
    }
    
    // MARK: - EnvironmentDemoInteractionOutput

    func updatedEnvironmentData(_ data: EnvironmentData, capabilities: Set<DeviceCapability>) {
        dataSource.updateData(data, capabilities: capabilities)
    }
    
    func displayInfoAbout(missingCapabilities: Set<DeviceCapability>, activeCapabilities: Set<DeviceCapability>) {
        if activeCapabilities.count == 0 {
            let alertMessage = "No active sensors, you will be redirected to the home screen."
            self.alertWithOKButton(title: "Broken sensors", message: alertMessage) { _ in
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            let alertMessage = "The device has broken sensors: \(missingCapabilities.map { $0.name }.joined(separator: ", "))"
            self.alertWithOKButton(title: "Broken sensors", message: alertMessage)
        }
    }
    
    @objc private  func settingsButtonPressed(_sender: UIButton) {
        let settings = UIStoryboard(name: "SettingsViewController", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsNavigationController
        self.navigationController?.present(settings, animated: true, completion: nil)
    }
}
