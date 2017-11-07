//
//  SILAppSelectionTableViewCell.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/13/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILAppSelectionTableViewCell.h"
#import "UIColor+SILColors.h"

@implementation SILAppSelectionTableViewCell

- (void)setupLayoutMargins {
    // Prevent the cell from inheriting the Table View's margin settings
    if ([self respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [self setPreservesSuperviewLayoutMargins:NO];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setupLayoutMargins];
}

@end
