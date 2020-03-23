//
//  SILUITabBar.m
//  BlueGecko
//
//  Created by Kamil Czajka on 16/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILUITabBar.h"

@implementation SILUITabBar

CGFloat const DefaultHeight = 87.0;

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _height = DefaultHeight;
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self != nil) {
        _height = DefaultHeight;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        _height = DefaultHeight;
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    UIWindow* window = UIApplication.sharedApplication.windows.firstObject;
    CGFloat bottomNotchHeight = window.safeAreaInsets.bottom;
    CGSize sizeThatFits = [super sizeThatFits:size];
    CGFloat tabBarHeight = _height + bottomNotchHeight;
    if (tabBarHeight > 0.0) {
        sizeThatFits.height = tabBarHeight;
    }
    
    return sizeThatFits;
}

- (void)setHeight:(CGFloat)height {
    if (_height != height) {
        _height = height;
    }
}

@end
