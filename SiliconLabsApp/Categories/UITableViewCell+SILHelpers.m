//
//  UITableViewCell+SILHelpers.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "UITableViewCell+SILHelpers.h"

#define IS_IOS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@implementation UITableViewCell (SILHelpers)

- (CGFloat)autoLayoutHeight {
    if (IS_IOS_8_OR_LATER) {
        return UITableViewAutomaticDimension;
    }
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    CGFloat height = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return height;
}

@end
