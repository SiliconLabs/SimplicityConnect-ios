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
@end

@implementation SILDebugCharacteristicEnumerationFieldTableViewCell

- (void)configureWithEnumerationModel:(SILEnumerationFieldRowModel *)enumerationModel {
    self.enumerationValueLabel.text = [enumerationModel primaryTitle] ?: @"Unknown Value";
    self.enumerationTypeLabel.text = [enumerationModel secondaryTitle] ?: @"";
    self.topSeparatorView.hidden = enumerationModel.hideTopSeparator;
    //Hidden is set to YES in the Bluetooth Browser feature after adding button properties SLMAIN-276. Hidden state was left conditional in HomeKit feature.
    self.writeChevronImageView.hidden = !enumerationModel.parentCharacteristicModel.canWrite;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self layoutIfNeeded];
}

@end
