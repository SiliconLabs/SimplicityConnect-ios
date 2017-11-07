//
//  SILDebugCharacteristicValueFieldTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/28/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicValueFieldTableViewCell.h"
#import "SILValueFieldRowModel.h"
#import "SILCharacteristicTableModel.h"
#import "SILDebugPopoverViewController.h"

@interface SILDebugCharacteristicValueFieldTableViewCell()
@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) SILValueFieldRowModel *valueModel;
@end

@implementation SILDebugCharacteristicValueFieldTableViewCell

- (void)configureWithValueModel:(SILValueFieldRowModel *)valueModel {
    self.valueModel = valueModel;
    self.valueLabel.text = [valueModel primaryTitle] ?: @"Unknown Value";
    self.typeLabel.text = [valueModel secondaryTitle] ?: @"";
    self.editButton.hidden = !valueModel.parentCharacteristicModel.canWrite;
    self.topSeparatorView.hidden = valueModel.hideTopSeparator;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self layoutIfNeeded];
}

- (IBAction)didTapEdit:(id)sender {
    [self.editDelegate beginValueEditWithValue:self.valueModel];
}

@end
