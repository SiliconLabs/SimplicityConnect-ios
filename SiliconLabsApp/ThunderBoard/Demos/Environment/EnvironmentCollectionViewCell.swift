//
//  EnvironmentCollectionViewCell.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 07/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit
import RxSwift

class EnvironmentCollectionViewCell: UICollectionViewCell {
    
    static let cellIdentifier = "EnvironmentCollectionViewCell"
    
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    let cornerRadius: CGFloat = 16.0
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellAppearence()
    }
    
    private func setupCellAppearence() {
        canvasView.layer.cornerRadius = cornerRadius
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = false
        backgroundColor = UIColor.clear
        addShadow(withOffset: SILCellShadowOffset, radius: SILCellShadowRadius)
    }
    
    func configureCell(with viewModel: EnvironmentDemoViewModel) {
        viewModel.name.asObservable().distinctUntilChanged().bind(to: titleLabel.rx.text).disposed(by: disposeBag)
        viewModel.value.asObservable().distinctUntilChanged().bind(to: detailsLabel.rx.text).disposed(by: disposeBag)
        viewModel.imageName.asObservable().distinctUntilChanged().map{ UIImage(named: $0) }.bind(to: icon.rx.image).disposed(by: disposeBag)
    }
}
