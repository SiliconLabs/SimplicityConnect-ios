//
//  SILKeychainViewController.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 02/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class SILKeychainViewController: UIViewController {
    
    @IBOutlet weak var segments: SILBrowserMappingsSegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoImage: UIImageView!
    
    var popoverController: WYPopoverController?
    var realmCharacteristicsNotificationToken: NotificationToken? = nil
    var realmServicesNotificationToken: NotificationToken? = nil
    
    var characteristics: Results<SILCharacteristicMap>? {
        get {
            return SILCharacteristicMap.get()
        }
    }
    
    var services: Results<SILServiceMap>? {
        get {
            return SILServiceMap.get()
        }
    }
    
    var maps: Array<SILMap> {
        get {
            switch segments.segmentType {
            case .characteristics:
                if let characteristics: Results<SILCharacteristicMap> = self.characteristics {
                    return Array(characteristics)
                }
            case .services:
                if let services: Results<SILServiceMap> = self.services {
                    return Array(services)
                }
            }
            return Array<SILMap>()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationToken()
        setupInfoImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObserverForDisplayToastResponse()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
        
    private func setupNotificationToken() {
        if self.characteristics != nil {
            setupCharacteristicsNotificationTokenIfNeeded()
        }
        if self.services != nil {
            setupServicesNotificationTokenIfNeeded()
        }
    }
    
    fileprivate func setupCharacteristicsNotificationTokenIfNeeded() {
        realmCharacteristicsNotificationToken = self.characteristics!.observe { [weak self] (changes: RealmCollectionChange) in
            if self?.segments.segmentType == .characteristics {
                switch changes {
                case .error(let error):
                    self?.tableView.reloadData()
                    fatalError("\(error)")
                default:
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    fileprivate func setupServicesNotificationTokenIfNeeded() {
        realmServicesNotificationToken = self.services!.observe { [weak self] (changes: RealmCollectionChange) in
            if self?.segments.segmentType == .services {
                switch changes {
                case .error(let error):
                    self?.tableView.reloadData()
                    fatalError("\(error)")
                default:
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func setupInfoImage() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedInfoImage(_:)))
        self.infoImage.addGestureRecognizer(tapGesture)
    }
    
    @objc private func tappedInfoImage(_ regognizer: UIGestureRecognizer) {
        let storyboard = UIStoryboard(name: "SILKeychain", bundle: nil)
        if let infoViewController = storyboard.instantiateViewController(withIdentifier: "KeychainInfo") as? SILKeychainInfoViewController {
            infoViewController.delegate = self
            self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: infoViewController, presenting:self, delegate:self as? WYPopoverControllerDelegate, animated:true)
        }
    }
    
    private func addObserverForDisplayToastResponse() {
        NotificationCenter.default.addObserver(self, selector:#selector(displayToast(_:)), name: NSNotification.Name(rawValue: SILNotificationDisplayToastResponse), object: nil)
    }
    
    @objc private func displayToast(_ notification: Notification) {
        let ErrorMessage = notification.userInfo?[SILNotificationKeyDescription] as? String ?? ""
        self.showToast(message: ErrorMessage, toastType: .disconnectionError) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: SILNotificationDisplayToastRequest), object: nil)
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func segmentChanged(_ sender: SILBrowserMappingsSegmentedControl) {
        tableView.reloadData()
    }
}

extension SILKeychainViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch segments.segmentType {
        case .characteristics:
            return characteristics?.count ?? 0
        case .services:
            return services?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SILMapCell = tableView.dequeueReusableCell(withIdentifier: "MapCell", for: indexPath) as! SILMapCell
        let map: SILMap = maps[indexPath.section]
        cell.nameLabel.text = map.name
        cell.uuidLabel.text = map.uuid
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }
}

extension SILKeychainViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let silCell = cell as! SILCell
        silCell.addShadowWhenAlone()
        silCell.roundCornersAll()
    }
}

extension SILKeychainViewController : SILMapCellDelegate {
    @objc func delete(cell: UITableViewCell) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            deleteItem(for: indexPath)
        }
    }
    
    private func deleteItem(for indexPath: IndexPath) {
        switch self.segments.segmentType {
        case .characteristics:
            self.removeFromCharacterticsMap(for: indexPath)
        case .services:
            self.removeFromServicesMap(for: indexPath)
        }
    }
    
    fileprivate func removeFromCharacterticsMap(for indexPath: IndexPath) {
        if let map: SILCharacteristicMap = self.characteristics?[indexPath.section] {
            _ = SILCharacteristicMap.remove(map: map.uuid)
        }
    }
    
    fileprivate func removeFromServicesMap(for indexPath: IndexPath) {
        if let map: SILServiceMap = self.services?[indexPath.section] {
            _ = SILServiceMap.remove(map: map.uuid)
        }
    }
}

extension SILKeychainViewController : SILDebugPopoverViewControllerDelegate {
    func didClose(_ popoverViewController: SILDebugPopoverViewController!) {
        self.popoverController?.dismissPopover(animated: true) {
            self.popoverController = nil
            self.tableView.reloadData()
        }
    }

    @objc func editName(cell: UITableViewCell) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            editItem(for: indexPath)
        }
    }

    private func editItem(for indexPath: IndexPath) {
        switch self.segments.segmentType {
        case .characteristics:
            self.editFromCharacterticsMap(for: indexPath)
        case .services:
            self.editFromServicesMap(for: indexPath)
        }
    }

    fileprivate func editFromCharacterticsMap(for indexPath: IndexPath) {
        if let realmModel = self.characteristics?[indexPath.section] {
            let nameEditor = SILMapNameEditorViewController()
            nameEditor.model = realmModel
            nameEditor.popoverDelegate = self
            self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: nameEditor, presenting:self, delegate:self as? WYPopoverControllerDelegate, animated:true)
        }
    }

    fileprivate func editFromServicesMap(for indexPath: IndexPath) {
        if let realmModel = self.services?[indexPath.section] {
            let nameEditor = SILMapNameEditorViewController()
            nameEditor.model = realmModel
            nameEditor.popoverDelegate = self
            self.popoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: nameEditor, presenting:self, delegate:self as? WYPopoverControllerDelegate, animated:true)
        }
    }
}

extension SILKeychainViewController : SILKeychainInfoViewContollerDelegate {
    func shouldCloseInfoViewController(_ infoViewController: SILKeychainInfoViewController) {
        self.popoverController?.dismissPopover(animated: true) {
            self.popoverController = nil
        }
    }
}
