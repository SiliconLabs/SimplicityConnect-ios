//
//  SILServicesServiceTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugServiceTableViewCell.h"
#import "UIColor+SILColors.h"
#import "SILServiceTableModel.h"
#import "SILBluetoothServiceModel.h"
#if ENABLE_HOMEKIT
#import "SILHomeKitServiceTableModel.h"
#endif

@interface SILDebugServiceTableViewCell()
@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *bottomSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *serviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *serviceUuidLabel;
@property (weak, nonatomic) IBOutlet UIImageView *viewMoreChevron;
@end

@implementation SILDebugServiceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self configureIPadCell];
    }
}

- (void)configureWithServiceModel:(SILServiceTableModel *)serviceTableModel {
    [self updateChevronImageForExpanded:serviceTableModel.isExpanded];
    self.serviceNameLabel.text = [serviceTableModel name];
    self.serviceUuidLabel.text = [serviceTableModel hexUuidString] ?: @"";
    self.topSeparatorView.hidden = serviceTableModel.hideTopSeparator;
    [self configureAsExpandanble:[serviceTableModel canExpand]];
    [self layoutIfNeeded];
}

#if ENABLE_HOMEKIT
- (void)configureWithHomeKitServiceModel:(SILHomeKitServiceTableModel *)homeKitServiceTableModel {
    self.serviceNameLabel.text = homeKitServiceTableModel.name ?: @"Unknown Service";
    self.serviceUuidLabel.text = [homeKitServiceTableModel uuidString] ?: @"";
    self.topSeparatorView.hidden = homeKitServiceTableModel.hideTopSeparator;
    [self configureAsExpandanble:[homeKitServiceTableModel canExpand]];
    [self layoutIfNeeded];
}
#endif

- (void)configureAsExpandanble:(BOOL)canExpand {
    self.viewMoreChevron.hidden = !canExpand;
}

-(void)configureIPadCell {
    self.contentView.layer.borderColor = [UIColor sil_lineGreyColor].CGColor;
    self.contentView.layer.borderWidth = 1.0f;
}

#pragma mark - SILGenericAttributeTableCell

- (void)expandIfAllowed:(BOOL)isExpanding {
    self.bottomSeparatorView.hidden = !isExpanding;
    [self updateChevronImageForExpanded:isExpanding];
}

- (void)updateChevronImageForExpanded:(BOOL)expanded {
    self.viewMoreChevron.image = [UIImage imageNamed: expanded ? @"chevron_expanded" : @"chevron_collapsed"];
}

@end
