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
#import "UIView+SILShadow.h"

@interface SILAppSelectionCollectionViewCell()
@property (weak, nonatomic) IBOutlet UIView *roundedView;

@end

@implementation SILAppSelectionCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupCellAppearence];
}

- (void)setupCellAppearence {
    [self setupIconImageView];
    [self setupCellRoundedAppearance];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.layer.masksToBounds = NO;
    self.backgroundColor = UIColor.clearColor;
    [self addShadowWithOffset:SILCellShadowOffset radius:SILCellShadowRadius];
}

- (void)setupIconImageView {
    self.iconImageView.layer.masksToBounds = YES;
}

- (void)setupCellRoundedAppearance {
    self.roundedView.layer.masksToBounds = YES;
    self.roundedView.layer.cornerRadius = CornerRadiusStandardValue;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _imageView = nil;
    _iconImageView = nil;
    _titleLabel = nil;
    _descriptionLabel = nil;
}

- (void)setFieldsInCell:(SILApp*)appData {
    self.titleLabel.text = appData.title;
    self.descriptionLabel.text = appData.appDescription;
    self.iconImageView.image = [UIImage imageNamed:appData.imageName];
}

@end
