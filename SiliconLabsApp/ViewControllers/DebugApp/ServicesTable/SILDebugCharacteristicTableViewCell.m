//
//  SILDebugCharacteristicTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/7/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicTableViewCell.h"
#import "SILDebugCharacteristicPropertyView.h"
#import "SILDebugProperty.h"
#import "UIColor+SILColors.h"
#import "SILCharacteristicTableModel.h"
#import "SILBluetoothCharacteristicModel.h"
#import "UIView+NibInitable.h"
#if ENABLE_HOMEKIT
#import "SILHomeKitCharacteristicTableModel.h"
#endif

@interface SILDebugCharacteristicTableViewCell()
@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *propertiesContainerView;
@property (weak, nonatomic) IBOutlet UILabel *characteristicNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *characteristicUuidLabel;
@property (weak, nonatomic) IBOutlet UIImageView *viewMoreChevron;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iPadBottomDividerLeadingConstraint;
@end

@implementation SILDebugCharacteristicTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor sil_lightGreyColor];
}

- (void)configureWithCharacteristicModel:(SILCharacteristicTableModel *)characteristicModel {
    self.characteristicNameLabel.text = [characteristicModel name];
    self.characteristicUuidLabel.text = [characteristicModel uuidString] ?: @"";
    self.topSeparatorView.hidden = characteristicModel.hideTopSeparator;
    [self configureAsExpandable:[characteristicModel canExpand] || [characteristicModel isUnknown]];
    [SILDebugCharacteristicPropertyView addProperties:[SILDebugProperty getActivePropertiesFrom:characteristicModel.characteristic.properties] toContainerView:self.propertiesContainerView];
    [self layoutIfNeeded];
}

#if ENABLE_HOMEKIT
- (void)configureWithHomeKitCharacteristicModel:(SILHomeKitCharacteristicTableModel *)homeKitCharacteristicModel {
    self.characteristicNameLabel.text = homeKitCharacteristicModel.name ?: @"Unknown Characteristic";
    self.characteristicUuidLabel.text = [homeKitCharacteristicModel uuidString] ?: @"";
    self.topSeparatorView.hidden = homeKitCharacteristicModel.hideTopSeparator;
    [self configureAsExpandable:NO];
}
#endif

- (void)configureAsExpandable:(BOOL)canExpand {
    self.viewMoreChevron.hidden = !canExpand;
}

#pragma mark - SILGenericAttributeTableCell

- (void)expandIfAllowed:(BOOL)isExpanding {
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat angle = isExpanding ? M_PI : 0;
        self.viewMoreChevron.transform = CGAffineTransformMakeRotation(angle);
    }];
}

@end
