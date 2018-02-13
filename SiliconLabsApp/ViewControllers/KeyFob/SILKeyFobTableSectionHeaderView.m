//
//  SILKeyFobTableSectionHeaderView.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/2/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILKeyFobTableSectionHeaderView.h"

@implementation SILKeyFobTableSectionHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];

    // Prevent the cell from inheriting the Table View's margin settings
    if ([self respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [self setPreservesSuperviewLayoutMargins:NO];
    }

    // Explictly set your cell's layout margins
    if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
        [self setLayoutMargins:UIEdgeInsetsZero];
    }
}

@end
