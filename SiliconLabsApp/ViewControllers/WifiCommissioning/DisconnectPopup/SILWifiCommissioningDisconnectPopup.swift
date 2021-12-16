//
//  SILWifiCommissioningDisconnectPopup.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 03/12/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

protocol SILWifiCommissioningDisconnectPopupDelegate: class {
    func didTappedYesButton()
    func didTappedNoButton()
}

class SILWifiCommissioningDisconnectPopup: UIViewController {
    
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var descriptionText: String!
    var delegate: SILWifiCommissioningDisconnectPopupDelegate?
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 400, height: 180)
            } else {
                return CGSize(width: 300, height: 180)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    //MARK: View Controller LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.descriptionLabel.text = descriptionText
    }
    
    //MARK: ACTION METHOD
    
    @IBAction func didTappedYesBtn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.delegate?.didTappedYesButton()
    }
    
    @IBAction func didTappedNoBtn(_ sender: Any) {
        self.delegate?.didTappedNoButton()
    }
}
