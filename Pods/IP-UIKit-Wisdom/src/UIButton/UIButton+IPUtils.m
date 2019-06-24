//
//  UIButton+IPUtils.m
//  Pods
//
//  Created by Ying Quan Tan on 12/24/15.
//
//

#import "UIButton+IPUtils.h"

@implementation UIButton (IPUtils)

- (void)centerButtonAndImageWithSpacing:(CGFloat)spacing {
    CGFloat insetAmount = spacing / 2.0;
    self.imageEdgeInsets = UIEdgeInsetsMake(0, -insetAmount, 0, insetAmount);
    self.titleEdgeInsets = UIEdgeInsetsMake(0, insetAmount, 0, -insetAmount);
    self.contentEdgeInsets = UIEdgeInsetsMake(0, insetAmount, 0, insetAmount);
}

@end
