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
@end

@implementation SILDebugCharacteristicToggleFieldTableViewCell

// FIX HEART RATE ON OR OFF
- (void)configureWithBitRowModel:(SILBitRowModel *)bitRowModel {
    self.model = bitRowModel;
    
    self.toggleFieldLabel.text = [bitRowModel primaryTitle] ?: @"Unknown Value";
    self.toggleCategoryLabel.text = [bitRowModel secondaryTitle] ?: @"";
    
    // MADE CHANGE
    //NSString *toggleState = [bitRowModel.toggleState intValue] ? @"ON" : @"OFF";
    NSString *toggleState = [bitRowModel.toggleState intValue] ? @"OFF" : @"OFF";
    //UIColor *stateColor = [bitRowModel.toggleState intValue] ? [UIColor colorWithWhite:0 alpha:0.54] : [UIColor colorWithWhite:0 alpha:0.26];
    UIColor *stateColor = [UIColor colorWithWhite:0 alpha:0.26];
    self.nonWritableLabel.text = toggleState;
    self.nonWritableLabel.textColor = stateColor;
    self.nonWritableLabel.hidden = NO;
        
    self.topSeparatorView.hidden = bitRowModel.hideTopSeparator;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self layoutIfNeeded];
}

@end
