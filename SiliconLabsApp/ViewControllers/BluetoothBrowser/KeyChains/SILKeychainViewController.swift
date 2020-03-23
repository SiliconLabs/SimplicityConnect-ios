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
            if segments.segmentType == .characteristics {
                if let characteristics: Results<SILCharacteristicMap> = self.characteristics {
                    return Array(characteristics)
                }
            } else if segments.segmentType == .services {
                if let services: Results<SILServiceMap> = self.services {
                    return Array(services)
                }
            }
            return Array<SILMap>()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristics = self.characteristics {
            realmCharacteristicsNotificationToken = characteristics.observe { [weak self] (changes: RealmCollectionChange) in
                if self?.segments.segmentType == .characteristics {
                    switch changes {
                    case .initial(_):
                        self?.tableView.reloadData()
                    case .update(_, _, _, _):
                    self?.tableView.reloadData()
                    case .error(let error):
                        self?.tableView.reloadData()
                        fatalError("\(error)")
                    }
                }
            }
        }
        if let services = self.services {
            realmServicesNotificationToken = services.observe { [weak self] (changes: RealmCollectionChange) in
                if self?.segments.segmentType == .services {
                    switch changes {
                    case .initial(_):
                        self?.tableView.reloadData()
                    case .update(_, _, _, _):
                        self?.tableView.reloadData()
                    case .error(let error):
                        self?.tableView.reloadData()
                        fatalError("\(error)")
                    }
                }
            }
        }
        if #available(iOS 13, *) {
            tableLeftInset.constant = 0
            tableRightInset.constant = 0
        } else {
            tableLeftInset.constant = tableInset
            tableRightInset.constant = -tableInset
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true) {
            
        }
    }
    
    @IBAction func segmentChanged(_ sender: SILBrowserSegmentedControl) {
        tableView.reloadData()
    }
}

extension SILKeychainViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if segments.segmentType == .characteristics {
            return characteristics?.count ?? 0
        } else if segments.segmentType == .services {
            return services?.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SILMapCell = tableView.dequeueReusableCell(withIdentifier: "MapCell", for: indexPath) as! SILMapCell
        let map: SILMap = maps[indexPath.section]
        cell.nameLabel.text = map.name
        cell.uuidLabel.text = map.uuid
        return cell
    }
}

extension SILKeychainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction: UITableViewRowAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            if self.segments.segmentType == .characteristics {
                if let map: SILCharacteristicMap = self.characteristics?[indexPath.section] {
                    _ = SILCharacteristicMap.remove(map: map.uuid)
                }
            }
            if self.segments.segmentType == .services {
                if let map: SILServiceMap = self.services?[indexPath.section] {
                    _ = SILServiceMap.remove(map: map.uuid)
                }
            }
        }
        deleteAction.backgroundColor = .vileRed
        return [deleteAction]
    }
}
