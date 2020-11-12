//
//  SILDebugCharacteristicEncodingFieldTableViewCell.m
//  SiliconLabsApp
//
//  Created by Glenn Martin on 11/10/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicEncodingFieldTableViewCell.h"

NSString * const hexString = @"Hex";
NSString * const asciiString = @"ASCII";
NSString * const decimalString = @"Decimal";

@interface SILDebugCharacteristicEncodingFieldTableViewCell() <SILDebugCharacteristicEncodingFieldViewDelegate>

@property (strong, nonatomic) NSArray * encodingTypes;

@end

@implementation SILDebugCharacteristicEncodingFieldTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _encodingTypes = @[ hexString, asciiString, decimalString ];
    NSUInteger index = 0;
    for (SILDebugCharacteristicEncodingFieldView *encodingView in @[_hexView, _asciiView, _decimalView]) {
        encodingView.titleLabel.text = _encodingTypes[index];
        encodingView.delegate = self;
        index++;
    }
}

- (void)clearValues {
    self.hexView.valueLabel.text = @"";
    self.asciiView.valueLabel.text = @"";
    self.decimalView.valueLabel.text = @"";
}

#pragma mark = SILDebugCharacteristicEncodingFieldViewDelegate

- (void)copyButtonWasClicked {
    [self.delegate copyButtonWasClicked];
}

@end
