//
//  SILAppSelectionCollectionViewCell.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 13/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILAppSelectionCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var roundedView: UIView?
    
    @IBOutlet weak var imageView: UIView?
    @IBOutlet weak var iconImageView: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellAppearence()
    }

    private func setupCellAppearence() {
        setupIconImageView()
        setupCellRoundedAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = false
        backgroundColor = UIColor.clear
        addShadow(withOffset: SILCellShadowOffset, radius: SILCellShadowRadius)
    }

    private func setupIconImageView() {
        iconImageView?.layer.masksToBounds = true
        iconImageView?.backgroundColor = .white
        iconImageView?.tintColor = .sil_regularBlue()
    }

    private func setupCellRoundedAppearance() {
        roundedView?.layer.masksToBounds = true
        roundedView?.layer.cornerRadius = CGFloat(CornerRadiusStandardValue)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView = nil
        iconImageView = nil
        titleLabel = nil
        descriptionLabel = nil
    }

    func setFieldsIn(_ appData: SILApp?) {
        titleLabel?.text = appData?.title
        titleLabel?.textColor = .sil_regularBlue()
        descriptionLabel?.text = appData?.appDescription
        iconImageView?.image = UIImage(named: appData?.imageName ?? "")
    }
}
