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
    
    @IBOutlet var navigationBar: UIView!
    @IBOutlet weak var bottomBarView: UIView!
    @IBOutlet weak var scanningButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var exportButton: SILPrimaryButton!
    
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
        bottomBarView.addShadow()
        let sortImage = sortButton.currentImage?.withRenderingMode(.alwaysTemplate)
        sortButton.setImage(sortImage, for: .normal)
        let filterImage = filterButton.currentImage?.withRenderingMode(.alwaysTemplate)
        filterButton.setImage(filterImage, for: .normal)
    }
    
    private func subscribeChartToViewModel() {
        viewModel.refresh.asObservable()
            .bind(to: chartView.refresh)
            .disposed(by: disposeBag)
        
        viewModel.peripherals.asObservable()
            .bind(to: chartView.input)
            .disposed(by: disposeBag)
    }
    
    private func setupScanningAction() {
        scanningButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .scan(viewModel.isScanning.value) { lastState, _ in
                return !lastState
            }
            .bind(to: viewModel.isScanning)
            .disposed(by: disposeBag)
        
        exportButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.showProgressView(status: "Exporting")
                self.viewModel.export(onFinish: { [weak self] filesToShare in
                    guard let self = self else { return }
                    self.hideProgressView()
                    self.showSharingExportFiles(filesToShare: filesToShare)
                })
            })
            .disposed(by: disposeBag)
        
        viewModel.isScanning
            .bind(with: self) { _self, scaninngState in
                if scaninngState {
                    _self.setStopScanningButton()
                    _self.chartView.startChart()
                } else {
                    _self.setStartScanningButton()
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.exportEnable
            .bind(with: self) { _self, state in
                _self.exportButton.isEnabled = state
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
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    @IBAction func backButtonTapped() -> Void {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSortVC", let sortVC = segue.destination as? SILSortViewController {
            sortVC.delegate = self
        } else if segue.identifier == "showFilterVC", let filterVC = segue.destination as? SILBrowserFilterViewController {
            filterVC.delegate = self
        }
    }
    
    private func setStopScanningButton() {
        scanningButton.backgroundColor = UIColor.sil_siliconLabsRed()
        scanningButton.setTitle(TitleForScanningButtonDuringScanning, for: .normal)
    }
    
    private func setStartScanningButton() {
        scanningButton.backgroundColor = UIColor.sil_regularBlue()
        scanningButton.setTitle(TitleForScanningButtonWhenIsNotScanning, for: .normal)
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
                                    sourceView: self.exportButton,
                                    sourceRect: self.exportButton.bounds,
                                    completionWithItemsHandler: nil)
    }
    
    private func showBluetoothDisabledDialog() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.rssiGraph
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message) { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension SILRSSIGraphViewController: SILSortViewControllerDelegate {
    func sortOptionWasSelected(with option: SILSortOption) {
        viewModel.sortOption.accept(option)
    }
}

extension SILRSSIGraphViewController: SILBrowserFilterViewControllerDelegate {
    func backButtonWasTapped() {
        self.navigationController?.dismiss(animated: true)
    }
    
    func searchButtonWasTapped(_ vm: SILBrowserFilterViewModel) {
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
