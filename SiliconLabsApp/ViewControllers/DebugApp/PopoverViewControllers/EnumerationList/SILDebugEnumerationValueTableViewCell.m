//
//  SILDebugEnumerationValueTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugEnumerationValueTableViewCell.h"

@implementation SILDebugEnumerationValueTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.valueLabel.font = [self.valueLabel.font fontWithSize:18.0f];
    }
}

@end
