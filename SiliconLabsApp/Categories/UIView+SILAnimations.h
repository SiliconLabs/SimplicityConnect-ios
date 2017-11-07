//
//  UIView+SILAnimations.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (SILAnimations)

+ (void)addContinuousRotationAnimationToLayer:(CALayer *)layer
                    withFullRotationDuration:(float)duration
                                      forKey:(NSString *)key;

@end
