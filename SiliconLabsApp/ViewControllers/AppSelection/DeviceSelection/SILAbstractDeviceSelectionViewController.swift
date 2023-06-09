//
//  SILAbstractDeviceSelectionViewController.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 21/10/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import SVProgressHUD

class SILAbstractDeviceSelectionViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var deviceCollectionView: UICollectionView!
    @IBOutlet weak var selectDeviceLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var deviceListLabel: UILabel!
    @IBOutlet weak var deviceListSpinner: UIImageView!
    @IBOutlet weak var emptyDeviceListView: UIView!
    
    let SILDeviceSelectionViewControllerReloadThreshold: CGFloat = 1.0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(nibName: "SILDeviceSelectionViewController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.deviceCollectionView.register(UINib(nibName: String(describing: SILDeviceSelectionCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: SILDeviceSelectionCollectionViewCellIdentifier)
        self.setupTextLabels()
        self.setupTextView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adjustUITextViewHeight(textView: infoTextView)
        UIView.addContinuousRotationAnimation(to: deviceListSpinner.layer, withFullRotationDuration: 2, forKey: "testingI")
    }

    @IBAction func didPressCancelButton(_ sender: Any) {}
    
    override var preferredContentSize: CGSize {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return CGSize(width: 540, height: 606)
            } else {
                return CGSize(width: 296, height: 447)
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    // MARK: - Setup Methods
    
    func setupTextLabels() {
        selectDeviceLabel.text = "Select a BLE Device"
    }
    
    func setupTextView() {
        infoTextView.text = ""
    }
    
    func adjustUITextViewHeight(textView : UITextView) {
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.sizeToFit()
        textView.isScrollEnabled = false
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 104.0 : 64.0
        
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            let rowSpacing: CGFloat = flowLayout.minimumInteritemSpacing + flowLayout.sectionInset.left + flowLayout.sectionInset.right
            return CGSize(width: collectionView.frame.size.width - rowSpacing, height: cellHeight)
        } else {
            return CGSize(width: collectionView.frame.size.width, height: cellHeight)
        }
    }
}
