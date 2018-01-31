//
//  UIView+SILAnimations.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "UIView+SILAnimations.h"

@implementation UIView (SILAnimations)

+ (void)addContinuousRotationAnimationToLayer:(CALayer *)layer
                     withFullRotationDuration:(float)duration
                                       forKey:(NSString *)key {
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = CGFLOAT_MAX;
    [layer addAnimation:rotationAnimation forKey:key];
}

@end
