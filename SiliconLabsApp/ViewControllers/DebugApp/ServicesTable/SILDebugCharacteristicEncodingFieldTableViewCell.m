//
//  SILDebugCharacteristicEncodingFieldTableViewCell.m
//  SiliconLabsApp
//
//  Created by Glenn Martin on 11/10/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicEncodingFieldTableViewCell.h"

@interface SILDebugCharacteristicEncodingFieldTableViewCell()
@property(strong, nonatomic) IBOutletCollection(UILabel) NSArray* headingLabels;
@property(weak, nonatomic) IBOutlet UIView *encodingTableContainer;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *encodingTableLeadingConstraint;
@end

@implementation SILDebugCharacteristicEncodingFieldTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.headingLabels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UILabel* label = ((UILabel *)obj);
            label.font = [label.font fontWithSize:16];
        }];
        
        self.encodingTableLeadingConstraint.constant = 318.0f;
        
        [self.contentView updateConstraints];
    }
}

- (void)clearValues {
    self.hexValueLabel.text = @"";
    self.asciiValueLabel.text = @"";
    self.decimalValueLabel.text = @"";
}

@end
