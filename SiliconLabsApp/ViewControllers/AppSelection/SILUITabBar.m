//
//  SILUITabBar.m
//  BlueGecko
//
//  Created by Kamil Czajka on 16/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILUITabBar.h"
#import "UIView+SILShadow.h"

@interface SILUITabBar()

@property (strong, nonatomic) UIView *indicatorView;
@property (strong, nonatomic) NSLayoutConstraint *indicatorCenter;
@property (nonatomic) CGFloat indicatorConstant;

@end

@implementation SILUITabBar

CGFloat const DefaultHeight = 70.0;

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _height = DefaultHeight;
    [self setupIndicatorView];
    [self addShadow];
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

- (void)setupIndicatorView {
    _indicatorView = [[UIView alloc] initWithFrame:CGRectZero];
    _indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_indicatorView];
    [_indicatorView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [_indicatorView.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.07].active = YES;
    [_indicatorView.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.15].active = YES;
    _indicatorCenter = [NSLayoutConstraint constraintWithItem:_indicatorView
                                                    attribute:NSLayoutAttributeCenterX
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self
                                                    attribute:NSLayoutAttributeCenterX
                                                   multiplier:1
                                                     constant:0];
    _indicatorView.backgroundColor = [UIColor sil_strongBlueColor];
    [self addConstraint:_indicatorCenter];
    [self setMuliplierForSelectedIndex:1];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.indicatorCenter.constant = self.bounds.size.width * self.indicatorConstant;
    [self addRoundedCornersInIndicator];
    self.backgroundColor = UIColor.redColor;
}

- (void)addRoundedCornersInIndicator {
    CGFloat radius = self.indicatorView.bounds.size.height;
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.indicatorView.bounds
                                                     byRoundingCorners: UIRectCornerBottomLeft | UIRectCornerBottomRight
                                                           cornerRadii:CGSizeMake(radius, radius)];
    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.path = bezierPath.CGPath;
    self.indicatorView.layer.mask = mask;
}


- (void)setMuliplierForSelectedIndex:(NSUInteger)index {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (index == 0) {
            self.indicatorConstant = -0.18;
        } else {
            self.indicatorConstant = 0.17;
        }
    } else {
        if (index == 0) {
            self.indicatorConstant = -0.25;
        } else {
            self.indicatorConstant = 0.25;
        }
    }
    
    self.indicatorCenter.constant = self.bounds.size.width * self.indicatorConstant;
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

@end
