//
//  SILDebugCharacteristicEnumerationTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/28/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicEnumerationFieldTableViewCell.h"
#import "SILEnumerationFieldRowModel.h"
#import "SILBluetoothEnumerationModel.h"
#import "SILCharacteristicTableModel.h"

@interface SILDebugCharacteristicEnumerationFieldTableViewCell()
@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *enumerationValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *enumerationTypeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *writeChevronImageView;
@end

@implementation SILDebugCharacteristicEnumerationFieldTableViewCell

- (void)configureWithEnumerationModel:(SILEnumerationFieldRowModel *)enumerationModel {
    self.enumerationValueLabel.text = [enumerationModel primaryTitle] ?: @"Unknown Value";
    self.enumerationTypeLabel.text = [enumerationModel secondaryTitle] ?: @"";
    self.topSeparatorView.hidden = enumerationModel.hideTopSeparator;
    self.writeChevronImageView.hidden = !enumerationModel.parentCharacteristicModel.canWrite;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self layoutIfNeeded];
}

@end
