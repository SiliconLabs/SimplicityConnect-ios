//
//  UIView+SILShadow.m
//  BlueGecko
//
//  Created by Grzegorz Janosz on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "UIView+SILShadow.h"

CGFloat const SILStoryboardShadowRadius = 5;
CGFloat const SILStoryboardShadowOpacity = 0.5;
CGSize const SILStoryboardShadowOffset = {0, 0};
CGSize const SILCellShadowOffset = {1, 1};
CGFloat const SILCellShadowRadius = 1;

@implementation UIView (SILShadow)

- (void)addShadow {
    [self addShadowWithOffset:SILStoryboardShadowOffset color:UIColor.blackColor.CGColor radius:SILStoryboardShadowRadius opacity:SILStoryboardShadowOpacity];
}

- (void)addShadowWithOffset:(CGSize)offset radius:(CGFloat)radius {
    [self addShadowWithOffset:offset color:UIColor.blackColor.CGColor radius:radius opacity:SILStoryboardShadowOpacity];
}

- (void)addShadowWithOffset:(CGSize)offset color:(CGColorRef)color radius:(CGFloat)radius opacity:(CGFloat)opacity {
    self.layer.shadowOffset = offset;
    self.layer.shadowColor = color;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = opacity;
}

@end
