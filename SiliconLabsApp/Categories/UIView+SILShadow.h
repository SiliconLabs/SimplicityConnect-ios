//
//  UIView+SILShadow.h
//  BlueGecko
//
//  Created by Grzegorz Janosz on 01/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const SILStoryboardShadowRadius;
extern CGFloat const SILStoryboardShadowOpacity;
extern CGSize const SILStoryboardShadowOffset;
extern CGSize const SILCellShadowOffset;
extern CGFloat const SILCellShadowRadius;

@interface UIView (SILShadow)

- (void)addShadow;
- (void)addShadowWithOffset:(CGSize)offset radius:(CGFloat)radius;
- (void)addShadowWithOffset:(CGSize)offset color:(CGColorRef)color radius:(CGFloat)radius opacity:(CGFloat)opacity;

@end
