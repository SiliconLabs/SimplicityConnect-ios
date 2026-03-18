import Foundation
import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

class SILEnergyHarvestingViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var chartView: SILEHGraphView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var voltageLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var timeDifferanceLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
        
    private let viewModel = SILEHGraphViewModel()
    private var disposeBag = DisposeBag()
        
    private var voltageTimer: Timer?
    var energyHarvestingViewModelOBj: SILEnergyHarvestingViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        setLeftAlignedTitle("Energy Harvesting")

        energyHarvestingViewModelOBj = SILEnergyHarvestingViewModel(delegate: self)
        subscribeChartToViewModel()
        setupScanningAction()
        resetGraphState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.tabBarController?.hideTabBarAndUpdateFrames()
        // Full reset each appearance
        resetGraphState()
        viewModel.isScanning.accept(true)
       // startVoltageSimulation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.isScanning.accept(false)
        stopVoltageSimulation()
        chartView.resetGraphCompletely()
        energyHarvestingViewModelOBj = nil
    }
    
    // Removed duplicate logic from viewDidDisappear
    // override func viewDidDisappear(_ animated: Bool) { super.viewDidDisappear(animated) }
    
    private func resetGraphState() {
        viewModel.clearData()
        chartView.resetGraphCompletely()
        chartView.setStartTime(time: Date()) // single authoritative referenceDate
    }
    
    // MARK: Voltage Simulation
    
    private func startVoltageSimulation() {
        guard voltageTimer == nil else { return } // prevent duplicates
        // Immediate first sample at t = 0
//        chartView.addRandomVoltagePoint(voltageValue: 0.0)
        voltageTimer = Timer.scheduledTimer(timeInterval: 4.0,
                                            target: self,
                                            selector: #selector(generateVoltagePoint),
                                            userInfo: nil,
                                            repeats: true)
        if let t = voltageTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }
    
    @objc private func generateVoltagePoint() {
        let voltageValue = Double.random(in: 2000...3000)
        chartView.addRandomVoltagePoint(voltageValue: voltageValue)
    }
    
    private func stopVoltageSimulation() {
        voltageTimer?.invalidate()
        voltageTimer = nil
    }
    
//    private func subscribeChartToViewModel() {
//        // Bindings can be restored when RSSI data wiring is ready
//        // viewModel.refresh.bind(to: chartView.refresh).disposed(by: disposeBag)
//        // viewModel.peripherals.bind(to: chartView.input).disposed(by: disposeBag)
//    }
    
    private func subscribeChartToViewModel() {
        viewModel.refresh.asObservable()
            .bind(to: chartView.refresh)
            .disposed(by: disposeBag)
        
//        viewModel.peripherals.asObservable()
//            .bind(to: chartView.input)
//            .disposed(by: disposeBag)
    }
    
    private func setupScanningAction() {
        viewModel.isScanning
            .bind(with: self) { _self, scanning in
                if scanning {
                    _self.chartView.startChart()
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.blutoothDisabled
            .startWith(false)
            .bind(with: self) { _self, disabled in
                if disabled {
                    _self.showBluetoothDisabledDialog()
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func showProgressView(status: String) { SVProgressHUD.show(withStatus: status) }
    private func hideProgressView() { SVProgressHUD.dismiss() }
    
    private func showSharingExportFiles(filesToShare: [URL]) {
        let rssiGraphSubject = "RSSI Graph Export"
        showSharingExportFiles(filesToShare: filesToShare,
                               subject: rssiGraphSubject,
                               sourceView: view,
                               sourceRect: view.bounds,
                               completionWithItemsHandler: nil)
    }
    
    private func showBluetoothDisabledDialog() {
        let alert = SILBluetoothDisabledAlert.rssiGraph
        alertWithOKButton(title: alert.title, message: alert.message) { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
}
//MARK: SILEnergyHarvestingViewModelDelegate

extension SILEnergyHarvestingViewController: SILEnergyHarvestingViewModelDelegate {
    func energyHarvestingViewModel(didReceiveVoltage value: Int,
                                   RSSI: NSNumber,
                                   peripheralName: String,
                                   peripheralUUID: String,
                                   timeStamp: String,
                                   advertisingInterval: Double) {
        let timeVal = advertisingInterval * 1000
        DispatchQueue.main.async {
            self.deviceName.text = peripheralName
            self.uuidLabel.text = peripheralUUID
            self.voltageLabel.text = "\(value) mV"
            //self.timeDifferanceLabel.text = "\(advertisingInterval * 1000) ms"
            self.timeDifferanceLabel.text = "\(String(format: "%.2f", timeVal)) ms"
            self.currentTimeLabel.text = timeStamp
            self.rssiLabel.text = "\(RSSI) RSSI"
        }
        // If you want real voltage points, uncomment:
        chartView.addRandomVoltagePoint(voltageValue: Double(value))
        
    }
}
