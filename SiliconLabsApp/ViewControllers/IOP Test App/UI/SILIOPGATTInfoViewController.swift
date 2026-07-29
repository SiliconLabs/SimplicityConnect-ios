//
//  SILIOPGATTInfoViewController.swift
//  BlueGecko
//
//  Created by Cursor on 07/07/26.
//

import UIKit
import CoreBluetooth

final class SILIOPGATTInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Discovered model
    
    private struct DiscoveredCharacteristic {
        let name: String
        let uuid: String
        let properties: CBCharacteristicProperties
    }
    
    private struct DiscoveredService {
        let name: String
        let uuid: String
        var characteristics: [DiscoveredCharacteristic]
    }
    
    // MARK: - UI
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let statusContainer = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let cellReuseIdentifier = "SILIOPGATTInfoCell"
    private let headerReuseIdentifier = "SILIOPGATTInfoHeader"
    
    // MARK: - Bluetooth
    
    // Reuse the IOP tester's central manager so we connect to the exact same device
    // selected for the IOP test (matched by `deviceUUIDToConnect`).
    private let iopCentralManager = SILIOPTesterCentralManager()
    private var connectionStatusToken: SILObservableToken?
    private var discoveredPeripheralsToken: SILObservableToken?
    private var peripheral: CBPeripheral?
    private var pendingCharacteristicDiscoveries = 0
    private var didStartScanning = false
    private var didStartConnecting = false
    private var didFinishLoading = false
    private var scanTimeoutTimer: Timer?
    private static let scanTimeout: TimeInterval = 15
    
    // MARK: - Data
    
    private var services: [DiscoveredService] = []
    private let deviceName: String?
    
    // MARK: - Init
    
    init(deviceName: String?) {
        self.deviceName = deviceName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let trimmedName = deviceName?.trimmingCharacters(in: .whitespacesAndNewlines)
        title = (trimmedName?.isEmpty == false) ? trimmedName : "GATT Table"
        view.backgroundColor = UIColor.appBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(closeTapped))
        setupTableView()
        setupStatusView()
        showStatus("Connecting to device\u{2026}", loading: true)
        beginConnectionFlow()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || (navigationController?.isBeingDismissed ?? false) || isMovingFromParent {
            teardownConnection()
        }
    }
    
    deinit {
        teardownConnection()
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 72
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 64
        tableView.register(SILIOPGATTCharacteristicCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.register(SILIOPGATTServiceHeaderView.self, forHeaderFooterViewReuseIdentifier: headerReuseIdentifier)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupStatusView() {
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.axis = .vertical
        statusContainer.alignment = .center
        statusContainer.spacing = 12
        
        activityIndicator.hidesWhenStopped = true
        
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.textColor = UIColor.sil_subtitleText()
        statusLabel.font = UIFont(name: "Stolzl-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        
        statusContainer.addArrangedSubview(activityIndicator)
        statusContainer.addArrangedSubview(statusLabel)
        view.addSubview(statusContainer)
        
        NSLayoutConstraint.activate([
            statusContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            statusContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Connection lifecycle
    
    private func beginConnectionFlow() {
        guard UserDefaults.standard.string(forKey: "deviceUUIDToConnect") != nil else {
            showStatus("No device selected for the IOP test.", loading: false)
            return
        }
        
        connectionStatusToken = iopCentralManager.newPublishConnectionStatus().observe(sendInitial: false) { [weak self] status in
            self?.handleConnectionStatus(status)
        }
        discoveredPeripheralsToken = iopCentralManager.newPublishDiscoveredPeripherals().observe(sendInitial: false) { [weak self] peripherals in
            self?.handleDiscoveredPeripherals(peripherals)
        }
        
        // The tester central only starts scanning while Bluetooth is powered on. If it is
        // already on, start now; otherwise the connection-status observer starts it on power-on.
        if iopCentralManager.bluetoothState {
            startScanningIfNeeded()
        }
    }
    
    private func startScanningIfNeeded() {
        guard !didStartScanning else { return }
        didStartScanning = true
        showStatus("Searching for device\u{2026}", loading: true)
        iopCentralManager.startScanning()
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = Timer.scheduledTimer(withTimeInterval: Self.scanTimeout, repeats: false) { [weak self] _ in
            self?.handleScanTimeout()
        }
    }
    
    private func handleScanTimeout() {
        guard !didStartConnecting, !didFinishLoading else { return }
        iopCentralManager.stopScanning()
        showStatus("Couldn\u{2019}t find the device.\nMake sure it is powered on and nearby, then try again.", loading: false)
    }
    
    private func handleConnectionStatus(_ status: SILIOPTesterCentralManagerConnectionStatus) {
        switch status {
        case .bluetoothEnabled(let enabled):
            if enabled {
                startScanningIfNeeded()
            } else {
                showStatus("Bluetooth is turned off.", loading: false)
            }
        case .connected(let peripheral):
            self.peripheral = peripheral
            peripheral.delegate = self
            showStatus("Discovering services\u{2026}", loading: true)
            peripheral.discoverServices(nil)
        case .failToConnect:
            showStatus("Failed to connect to device.", loading: false)
        case .disconnected:
            if !didFinishLoading {
                showStatus("Device disconnected.", loading: false)
            }
        case .unknown:
            break
        }
    }
    
    private func handleDiscoveredPeripherals(_ peripherals: [SILDiscoveredPeripheral]) {
        guard !didStartConnecting else { return }
        let uuidString = UserDefaults.standard.string(forKey: "deviceUUIDToConnect")
        let target = peripherals.first { $0.peripheral?.identifier.uuidString == uuidString } ?? peripherals.first
        guard let target = target else { return }
        didStartConnecting = true
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
        iopCentralManager.stopScanning()
        showStatus("Connecting to device\u{2026}", loading: true)
        iopCentralManager.connect(to: target)
    }
    
    private func teardownConnection() {
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
        connectionStatusToken?.invalidate()
        connectionStatusToken = nil
        discoveredPeripheralsToken?.invalidate()
        discoveredPeripheralsToken = nil
        iopCentralManager.stopScanning()
        if let peripheral = peripheral {
            iopCentralManager.disconnect(peripheral: peripheral)
        }
        peripheral = nil
    }
    
    // MARK: - Status helpers
    
    private func showStatus(_ text: String, loading: Bool) {
        statusContainer.isHidden = false
        statusLabel.text = text
        if loading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func hideStatus() {
        activityIndicator.stopAnimating()
        statusContainer.isHidden = true
    }
    
    private func finishLoadingIfNeeded() {
        guard pendingCharacteristicDiscoveries == 0, !didFinishLoading else { return }
        didFinishLoading = true
        if services.contains(where: { !$0.characteristics.isEmpty }) || !services.isEmpty {
            hideStatus()
        } else {
            showStatus("No services found on this device.", loading: false)
        }
        tableView.reloadData()
    }
    
    // MARK: - Name resolution
    
    private func serviceName(for uuid: CBUUID) -> String {
        if let name = SILIOPGATTSpecCatalog.service(for: uuid)?.name {
            return name
        }
        if let name = SILUUIDProvider.shared().predefinedName(forServiceUUID: uuid.uuidString) {
            return name
        }
        return uuid.description
    }
    
    private func characteristicName(for uuid: CBUUID) -> String {
        if let name = SILIOPGATTSpecCatalog.characteristic(for: uuid)?.name {
            return name
        }
        if let name = SILUUIDProvider.shared().predefinedName(forCharacteristicUUID: uuid.uuidString) {
            return name
        }
        return uuid.description
    }
    
    // MARK: - UITableViewDataSource / Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        services.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        services[section].characteristics.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier) as? SILIOPGATTServiceHeaderView
        let service = services[section]
        header?.configure(name: service.name, uuid: service.uuid)
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! SILIOPGATTCharacteristicCell
        let characteristic = services[indexPath.section].characteristics[indexPath.row]
        cell.configure(name: characteristic.name,
                       uuid: characteristic.uuid,
                       properties: SILIOPGATTProperty.detected(in: characteristic.properties))
        return cell
    }
}

// MARK: - CBPeripheralDelegate

extension SILIOPGATTInfoViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            showStatus("Failed to discover services.\n\(error.localizedDescription)", loading: false)
            return
        }
        let discovered = peripheral.services ?? []
        services = discovered.map {
            DiscoveredService(name: serviceName(for: $0.uuid), uuid: $0.uuid.uuidString, characteristics: [])
        }
        pendingCharacteristicDiscoveries = discovered.count
        tableView.reloadData()
        
        guard !discovered.isEmpty else {
            finishLoadingIfNeeded()
            return
        }
        for service in discovered {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let index = services.firstIndex(where: { $0.uuid == service.uuid.uuidString }) {
            let characteristics = (service.characteristics ?? []).map {
                DiscoveredCharacteristic(name: characteristicName(for: $0.uuid),
                                         uuid: $0.uuid.uuidString,
                                         properties: $0.properties)
            }
            services[index].characteristics = characteristics
        }
        if pendingCharacteristicDiscoveries > 0 {
            pendingCharacteristicDiscoveries -= 1
        }
        tableView.reloadData()
        finishLoadingIfNeeded()
    }
}

// MARK: - Property badges

private enum SILIOPGATTProperty {
    case read
    case write
    case notify
    
    var title: String {
        switch self {
        case .read: return "READ"
        case .write: return "WRITE"
        case .notify: return "NOTIFY"
        }
    }
    
    var color: UIColor {
        switch self {
        case .read: return UIColor(named: "sil_regularBlueColor") ?? .systemBlue
        case .write: return UIColor(named: "sil_yellowColor") ?? .systemOrange
        case .notify: return UIColor(named: "sil_regularGreenColor") ?? .systemGreen
        }
    }
    
    /// Maps CoreBluetooth properties onto the three headline properties.
    static func detected(in properties: CBCharacteristicProperties) -> [SILIOPGATTProperty] {
        var result: [SILIOPGATTProperty] = []
        if properties.contains(.read) { result.append(.read) }
        if properties.contains(.write) || properties.contains(.writeWithoutResponse) { result.append(.write) }
        if properties.contains(.notify) || properties.contains(.indicate) { result.append(.notify) }
        return result
    }
}

private final class SILIOPGATTBadgeView: UIView {
    private let label = UILabel()
    
    init(property: SILIOPGATTProperty) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4
        layer.masksToBounds = true
        backgroundColor = property.color.withAlphaComponent(0.16)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = property.title
        label.textColor = property.color
        label.font = UIFont(name: "Stolzl-Medium", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .semibold)
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Service header

private final class SILIOPGATTServiceHeaderView: UITableViewHeaderFooterView {
    private let nameLabel = UILabel()
    private let uuidLabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = .clear
        self.backgroundView = backgroundView
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.numberOfLines = 0
        nameLabel.textColor = UIColor.sil_primaryText()
        nameLabel.font = UIFont(name: "Stolzl-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15, weight: .semibold)
        
        uuidLabel.translatesAutoresizingMaskIntoConstraints = false
        uuidLabel.numberOfLines = 0
        uuidLabel.textColor = UIColor.sil_subtitleText()
        uuidLabel.font = UIFont(name: "Stolzl-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(uuidLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            uuidLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            uuidLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            uuidLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            uuidLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(name: String, uuid: String) {
        nameLabel.text = name
        uuidLabel.text = uuid
    }
}

// MARK: - Characteristic cell

private final class SILIOPGATTCharacteristicCell: UITableViewCell {
    private let container = UIView()
    private let nameLabel = UILabel()
    private let uuidLabel = UILabel()
    private let badgeStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 8
        contentView.addSubview(container)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.numberOfLines = 0
        nameLabel.textColor = UIColor.sil_primaryText()
        nameLabel.font = UIFont(name: "Stolzl-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
        
        uuidLabel.translatesAutoresizingMaskIntoConstraints = false
        uuidLabel.numberOfLines = 0
        uuidLabel.textColor = UIColor.sil_subtitleText()
        uuidLabel.font = UIFont(name: "Stolzl-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
        
        badgeStack.translatesAutoresizingMaskIntoConstraints = false
        badgeStack.axis = .horizontal
        badgeStack.spacing = 6
        badgeStack.alignment = .center
        
        container.addSubview(nameLabel)
        container.addSubview(uuidLabel)
        container.addSubview(badgeStack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            
            uuidLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            uuidLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            uuidLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            
            badgeStack.topAnchor.constraint(equalTo: uuidLabel.bottomAnchor, constant: 8),
            badgeStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            badgeStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12),
            badgeStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(name: String, uuid: String, properties: [SILIOPGATTProperty]) {
        nameLabel.text = name
        uuidLabel.text = uuid
        
        badgeStack.arrangedSubviews.forEach {
            badgeStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if properties.isEmpty {
            let placeholder = UILabel()
            placeholder.text = "\u{2014}"
            placeholder.textColor = UIColor.sil_subtitleText()
            placeholder.font = UIFont(name: "Stolzl-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
            badgeStack.addArrangedSubview(placeholder)
        } else {
            properties.forEach {
                badgeStack.addArrangedSubview(SILIOPGATTBadgeView(property: $0))
            }
        }
    }
}
