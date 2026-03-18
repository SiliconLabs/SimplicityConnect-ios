//
//  CircularProgressView.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 21/08/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircularProgressView.h"

@interface CircularProgressView ()
@property (nonatomic, strong) CAShapeLayer *trackLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *percentageLabel;
@end

@implementation CircularProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupLayers]; [self setupLabel]; }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) { [self setupLayers]; [self setupLabel]; }
    return self;
}

- (void)setupLayers {
    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2.0 - 10.0;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    UIBezierPath *circularPath = [UIBezierPath bezierPathWithArcCenter:center
                                                               radius:radius
                                                           startAngle:-M_PI_2
                                                             endAngle:1.5 * M_PI
                                                            clockwise:YES];
    self.trackLayer = [CAShapeLayer layer];
    self.trackLayer.path = circularPath.CGPath;
    self.trackLayer.strokeColor = [UIColor lightGrayColor].CGColor;
    self.trackLayer.lineWidth = 10.0;
    self.trackLayer.fillColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:self.trackLayer];

    self.progressLayer = [CAShapeLayer layer];
    self.progressLayer.path = circularPath.CGPath;
    self.progressLayer.strokeColor = [UIColor systemBlueColor].CGColor;
    self.progressLayer.lineWidth = 10.0;
    self.progressLayer.fillColor = [UIColor clearColor].CGColor;
    self.progressLayer.strokeEnd = 0.0;
    self.progressLayer.lineCap = kCALineCapRound;
    [self.layer addSublayer:self.progressLayer];
}

- (void)setupLabel {
    self.percentageLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.percentageLabel.textAlignment = NSTextAlignmentCenter;
    self.percentageLabel.font = [UIFont boldSystemFontOfSize:18];
    self.percentageLabel.textColor = [UIColor whiteColor];
    [self addSubview:self.percentageLabel];
    [self setProgress:self.progress];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.percentageLabel.frame = self.bounds;
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    self.progressLayer.strokeEnd = progress;
    int percent = (int)(progress * 100);
    self.percentageLabel.text = [NSString stringWithFormat:@"%d%%", percent];
}

@end
