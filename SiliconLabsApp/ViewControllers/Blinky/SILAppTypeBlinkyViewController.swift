//
//  SILAppTypeBlinkyViewController.swift
//  BlueGecko
//
//  Created by Vasyl Haievyi on 31/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

class SILAppTypeBlinkyViewController: UIViewController {
    
    @IBOutlet var lightBulbButton: UIButton!
    @IBOutlet var virtualButtonImage: UIImageView!
    @IBOutlet var navigationBar: UIView!
    
    @objc public var centralManager: SILCentralManager?;
    @objc public var connectedPeripheral: CBPeripheral?;
    
    private var viewModel: SILBlinkyViewModel?
    
    private var disposeBag = SILObservableTokenBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLightBulbButton()
        setupNavigationBarShadow()
        viewModel = SILBlinkyViewModel(centralManager: centralManager!, connectedPeripheral: connectedPeripheral!)
        subscribeToViewModel()
        viewModel?.viewDidLoad()
    }
    
    private func setupLightBulbButton() -> Void {
        lightBulbButton.setImage(UIImage(named: "lightOff"), for: .normal)
        lightBulbButton.setImage(UIImage(named: "lightOn"), for: .selected)
    }
    
    private func subscribeToViewModel() {
        let blinkyStateSubscription = viewModel?.BlinkyState.observe({ state in
            switch state {
            case .unknown:
                SVProgressHUD.show(withStatus: "Setting up Blinky")
            case .initiated:
                SVProgressHUD.dismiss()
            case .failure(let reason):
                SVProgressHUD.showError(withStatus: "Error: \(reason)")
                self.navigationController?.popViewController(animated: true)
            default:
                return
            }
        })
        disposeBag.add(token: blinkyStateSubscription!)
        
        let lightStateSubscription = viewModel?.LightState.observe({ lightState in
            switch lightState{
            case .On:
                self.setLightBulbOn()
            case .Off:
                self.setLightBulbOff()
            }
        })
        disposeBag.add(token: lightStateSubscription!)
        
        let reportButtonStateSubscription = viewModel?.ReportButtonState.observe({ buttonState in
            switch buttonState{
            case .Pressed:
                self.setVirtualButtonOn()
            case .Released:
                self.setVirtualButtonOff()
            }
        })
        disposeBag.add(token: reportButtonStateSubscription!)
    }

    private func setupNavigationBarShadow() {
        self.navigationBar.superview?.bringSubviewToFront(navigationBar)
        navigationBar.addShadow()
    }
        
    @IBAction func onLightBulbButtonTapped() -> Void {
        viewModel?.changeLightState()
    }
    
    @IBAction func backButtonTapped() -> Void {
        viewModel?.viewWillDisappear()
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setLightBulbOff() {
        lightBulbButton.isSelected = false;
    }
    
    private func setLightBulbOn() {
        lightBulbButton.isSelected = true;
    }
    
    private func setVirtualButtonOff() {
        virtualButtonImage.image = UIImage(named: "graphic - blinky - button -  off")
    }
    
    private func setVirtualButtonOn() {
        virtualButtonImage.image = UIImage(named: "graphic - blinky - button - on")
    }
}
