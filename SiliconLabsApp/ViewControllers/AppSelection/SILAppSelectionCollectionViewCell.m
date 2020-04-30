//
//  SILAppSelectionCollectionViewCell.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/13/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILAppSelectionCollectionViewCell.h"
#import "UIColor+SILColors.h"
#import "SILApp.h"
#import "SILBluetoothBrowser+Constants.h"

@implementation SILAppSelectionCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupCellAppearence];
}

- (void)setupCellAppearence {
    [self setupTitleLabel];
    [self setupDescriptionLabel];
    [self setupProfileKeyLabel];
    [self setupProfileValueLabel];
    [self setupIconImageView];
    [self setupImageView];
    [self setupCellRoundedAppearance];
}

- (void)setupTitleLabel {
    self.titleLabel.font = [UIFont robotoBoldWithSize:[UIFont getMiddleFontSize]];
    self.titleLabel.textColor = [UIColor sil_primaryTextColor];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.backgroundColor = [UIColor sil_cardBackgroundColor];
}

- (void)setupDescriptionLabel {
    self.descriptionLabel.font = [UIFont robotoRegularWithSize:[UIFont getMiddleFontSize]];
    self.descriptionLabel.textColor = [UIColor sil_subtleTextColor];
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
    self.descriptionLabel.backgroundColor = [UIColor sil_cardBackgroundColor];
}

- (void)setupProfileKeyLabel {
    self.profileKeyLabel.font = [UIFont robotoRegularWithSize:[UIFont getSmallFontSize]];
    self.profileKeyLabel.textColor = [UIColor sil_subtleTextColor];
    self.profileKeyLabel.adjustsFontSizeToFitWidth = YES;
    self.profileKeyLabel.backgroundColor = [UIColor sil_cardBackgroundColor];
}

- (void)setupProfileValueLabel {
    self.profileValueLabel.font = [UIFont robotoRegularWithSize:[UIFont getSmallFontSize]];
    self.profileValueLabel.textColor = [UIColor sil_subtleTextColor];
    self.profileValueLabel.adjustsFontSizeToFitWidth = YES;
    self.profileValueLabel.backgroundColor = [UIColor sil_cardBackgroundColor];
}

- (void)setupIconImageView {
    self.iconImageView.layer.masksToBounds = YES;
    self.iconImageView.backgroundColor = [UIColor sil_regularBlueColor];
    self.backgroundColor = [UIColor sil_cardBackgroundColor];
}

- (void)setupImageView {
    self.imageView.backgroundColor = [UIColor sil_cardBackgroundColor];
}

- (void)setupCellRoundedAppearance {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = CornerRadiusStandardValue;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _imageView = nil;
    _iconImageView = nil;
    _titleLabel = nil;
    _descriptionLabel = nil;
    _profileKeyLabel = nil;
    _profileValueLabel = nil;
}

- (void)setFieldsInCell:(SILApp*)appData {
    self.titleLabel.text = appData.title;
    self.descriptionLabel.text = appData.appDescription;
    self.profileKeyLabel.text = EmptyText;
    self.profileValueLabel.text = EmptyText;
    self.iconImageView.image = [UIImage imageNamed:appData.imageName];
}

@end
