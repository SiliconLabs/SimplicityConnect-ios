//
//  SILDebugServicesMenuViewController.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 19/05/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import Foundation

class SILDebugServicesMenuViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var menuOptionTableView: UITableView!
    @objc var delegate: SILDebugServicesMenuViewControllerDelegate!
    var menuOption = [Int : [String : () -> ()]]()
    
    let ReuseIdentifier = "DebugServicesMenuCell"
    let NibName = "SILDebugServicesMenuTableViewCell"
    let ServicesMenuCellHeight: CGFloat = 30.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMenuOptionTableView()
    }
    
    @objc func addMenuOption(title: String, completion: @escaping () -> ()) {
        menuOption[menuOption.count] = [title : completion]
    }
    
    @objc func getMenuOptionHeight() -> CGFloat {
        return CGFloat(menuOption.count) * ServicesMenuCellHeight
    }
    
    private func setupMenuOptionTableView() {
        self.menuOptionTableView.delegate = self
        self.menuOptionTableView.dataSource = self
        self.menuOptionTableView.register(UINib(nibName: NibName, bundle: nil), forCellReuseIdentifier: ReuseIdentifier)
        self.menuOptionTableView.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuOption.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier, for: indexPath) as! SILDebugServicesMenuTableViewCell
        cell.menuOptionLabel.text = menuOption[indexPath.row]?.keys.first
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let completion = menuOption[indexPath.row]?.values.first {
            delegate!.performActionForMenuOption(using: completion)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ServicesMenuCellHeight
    }
}
