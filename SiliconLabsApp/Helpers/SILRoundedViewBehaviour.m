//
//  SILRoundedViewBehaviour.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 3/9/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILRoundedViewBehaviour.h"

@implementation SILRoundedViewBehaviour

- (void)setRoundedView:(UIView *)roundedView {
    if (_roundedView) {
        [self stopObserveImageView:_roundedView];
    }
    _roundedView = roundedView;
    if (_roundedView) {
        [self updateImageViewCornerRadiusWithFrame:self.roundedView.frame];
        [self startObserveImageView:_roundedView];
    }
}

- (void)startObserveImageView:(UIView *)imageView {
    [self.roundedView addObserver:self forKeyPath:@"bounds" options:0 context:NULL];
}

- (void)stopObserveImageView:(UIView *)imageView {
    [self.roundedView removeObserver:self forKeyPath:@"bounds" context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.roundedView) {
        if ([keyPath isEqual:@"bounds"]) {
            [self updateImageViewCornerRadiusWithFrame:self.roundedView.frame];
        }
    }
}

- (void)updateImageViewCornerRadiusWithFrame:(CGRect)rect {
    self.roundedView.layer.cornerRadius = MIN(rect.size.width, rect.size.height) * 0.5f;
}

@end
