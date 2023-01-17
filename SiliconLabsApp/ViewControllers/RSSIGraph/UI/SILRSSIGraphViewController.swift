//
//  SILRSSIGraphViewController.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 11/02/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

class SILRSSIGraphViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    weak var floatingButtonSettings: FloatingButtonSettings?
    
    @IBOutlet weak var chartContainerView: UIView!
    
    private let TitleForScanningButtonDuringScanning = "Stop Scanning"
    private let TitleForScanningButtonWhenIsNotScanning = "Start Scanning"
    
    private let viewModel = SILRSSGraphViewModel()
    
    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var chartView: SILGraphView!
    
    private let cornerRadius: CGFloat = 16.0
    
    deinit {
        debugPrint("SILRSSIGraphViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupCollectionView()
        subscribeChartToViewModel()
        setupScanningAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.applyFiltersButtonWasTapped(SILBrowserFilterViewModel.sharedInstance())
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.isScanning.accept(false)
    }
    
    private func setupCollectionView() {
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        viewModel.peripherals.asDriver(onErrorJustReturn: [])
            .throttle(.milliseconds(300))
            .drive(collectionView.rx.items(cellIdentifier: "rssiGraphPeripheralCell",
                                           cellType: SILRSSIGraphDiscoveredDeviceCellCollectionViewCell.self)) { _, data, cell in
                cell.color = data.color
                cell.deviceNameLabel.text = data.name
                cell.uuidLabel.text = data.uuid
            }
            .disposed(by: disposeBag)
        
        collectionView.rx.modelSelected(SILRSSIGraphDiscoveredPeripheralData.self)
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .scan([SILRSSIGraphDiscoveredPeripheralData]()) { prev, current in
                if prev.contains(where: { $0.uuid == current.uuid }) {
                    return []
                }
                return [current]
            }
            .bind(to: viewModel.selected)
            .disposed(by: disposeBag)
    }
    
    private func setupAppearance() {
        chartContainerView.addShadow()
        chartContainerView.layer.cornerRadius = cornerRadius
    }
    
    private func subscribeChartToViewModel() {
        viewModel.refresh.asObservable()
            .bind(to: chartView.refresh)
            .disposed(by: disposeBag)
        
        viewModel.peripherals.asObservable()
            .bind(to: chartView.input)
            .disposed(by: disposeBag)
    }
    
    func scanningButtonTapped() {
        viewModel.isScanning.accept(!viewModel.isScanning.value)
    }
    
    func sortButtonTapped() {
        print("Sort button tapped in RSSI")
        viewModel.sortByRSSI()
    }
    
    func filterButtonTapped() {
        let storyboard = UIStoryboard(name: SILAppBluetoothBrowserHome, bundle: nil)
        let filterVC = storyboard.instantiateViewController(withIdentifier: SILSceneFilter) as! SILBrowserFilterViewController
        
        filterVC.delegate = self
        
        self.present(filterVC, animated: true)
    }
    
    fileprivate func setupButtonText() {
        if self.viewModel.isScanning.value {
            floatingButtonSettings?.setButtonText(TitleForScanningButtonDuringScanning)
            floatingButtonSettings?.setColor(.sil_siliconLabsRed())
        } else {
            floatingButtonSettings?.setButtonText(TitleForScanningButtonWhenIsNotScanning)
            floatingButtonSettings?.setColor(.sil_regularBlue())
        }
    }
    
    func setFloatingButton(settings: FloatingButtonSettings){
        self.floatingButtonSettings = settings
        setupButtonText()
    }
    
    func exportButtonTapped() {
        self.showProgressView(status: "Exporting")
        self.viewModel.export(onFinish: { [weak self] filesToShare in
            guard let self = self else { return }
            self.hideProgressView()
            self.showSharingExportFiles(filesToShare: filesToShare)
        })
    }
    
    private func setupScanningAction() {
        viewModel.isScanning
            .bind(with: self) { _self, scaninngState in
                if scaninngState {
                    _self.chartView.startChart()
                }
                self.setupButtonText()
            }
            .disposed(by: disposeBag)
        
        viewModel.blutoothDisabled
            .startWith(false)
            .bind(with: self) { _self, isBluetoothDisabled in
                if isBluetoothDisabled {
                    _self.showBluetoothDisabledDialog()
                }
            }
            .disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFilterVC", let filterVC = segue.destination as? SILBrowserFilterViewController {
            filterVC.delegate = self
        }
    }
    
    private func showProgressView(status: String) {
        SVProgressHUD.show(withStatus: status)
    }
    
    private func hideProgressView() {
        SVProgressHUD.dismiss()
    }
    
    private func showSharingExportFiles(filesToShare: [URL]) {
        let filesToShare = filesToShare
        let rssiGraphSubject = "RSSI Graph Export"
        self.showSharingExportFiles(filesToShare: filesToShare,
                                    subject: rssiGraphSubject,
                                    sourceView: self.view,
                                    sourceRect: self.view.bounds,
                                    completionWithItemsHandler: nil)
    }
    
    private func showBluetoothDisabledDialog() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.rssiGraph
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message) { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension SILRSSIGraphViewController: SILBrowserFilterViewControllerDelegate {
    func backButtonWasTapped() {
        self.navigationController?.dismiss(animated: true)
    }
    
    func applyFiltersButtonWasTapped(_ vm: SILBrowserFilterViewModel) {
        self.chartView.redrawChart()
        viewModel.applyFilter(vm)
        self.navigationController?.dismiss(animated: true)
    }
}

extension SILRSSIGraphViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height
        let width = height + 20
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
    }
}
