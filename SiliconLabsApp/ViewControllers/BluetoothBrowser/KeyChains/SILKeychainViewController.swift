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
    
    let tableInset: CGFloat = 16.0
    
    @IBOutlet weak var segments: SILBrowserSegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableLeftInset: NSLayoutConstraint!
    @IBOutlet weak var tableRightInset: NSLayoutConstraint!
    
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
        setupTableViewInsets()
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
    
    private func setupTableViewInsets() {
        if #available(iOS 13, *) {
            tableLeftInset.constant = 0
            tableRightInset.constant = 0
        } else {
            tableLeftInset.constant = tableInset
            tableRightInset.constant = -tableInset
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func segmentChanged(_ sender: SILBrowserSegmentedControl) {
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
