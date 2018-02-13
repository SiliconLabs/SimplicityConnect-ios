//
//  SILDebugCharacteristicToggleFieldTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/28/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicToggleFieldTableViewCell.h"
#import "SILBitRowModel.h"
#import "SILCharacteristicTableModel.h"

@interface SILDebugCharacteristicToggleFieldTableViewCell()
@property (weak, nonatomic) SILBitRowModel *model;
@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *toggleFieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *toggleCategoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *nonWritableLabel;
@property (weak, nonatomic) IBOutlet UISwitch *writableSwitch;
@end

@implementation SILDebugCharacteristicToggleFieldTableViewCell

- (void)configureWithBitRowModel:(SILBitRowModel *)bitRowModel {
    self.model = bitRowModel;
    
    self.toggleFieldLabel.text = [bitRowModel primaryTitle] ?: @"Unknown Value";
    self.toggleCategoryLabel.text = [bitRowModel secondaryTitle] ?: @"";
    
    NSString *toggleState = [bitRowModel.toggleState intValue] ? @"ON" : @"OFF";
    UIColor *stateColor = [bitRowModel.toggleState intValue] ? [UIColor colorWithWhite:0 alpha:0.54] : [UIColor colorWithWhite:0 alpha:0.26];
    self.nonWritableLabel.text = toggleState;
    self.nonWritableLabel.textColor = stateColor;
    self.nonWritableLabel.hidden = bitRowModel.parentCharacteristicModel.canWrite;
    
    self.writableSwitch.on = [bitRowModel.toggleState intValue] > 0;
    self.writableSwitch.hidden = !bitRowModel.parentCharacteristicModel.canWrite;
    
    self.topSeparatorView.hidden = bitRowModel.hideTopSeparator;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self layoutIfNeeded];
}

- (IBAction)didChangeValue:(UISwitch *)sender {
    [self.editDelegate didSaveCharacteristic:self.model.parentCharacteristicModel withAction:^{
        self.model.toggleState = @(sender.on);
    }];
}

@end
