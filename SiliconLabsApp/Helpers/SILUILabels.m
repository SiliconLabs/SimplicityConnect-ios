//
//  SILUILabels.m
//  BlueGecko
//
//  Created by Kamil Czajka on 17/12/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import "SILUILabels.h"

@implementation SILUILabels

- (void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets insets = {8, 16, 8, 16};
    
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
