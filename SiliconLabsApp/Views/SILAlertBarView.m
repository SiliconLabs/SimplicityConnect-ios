//
//  SILAlertBarView.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/25/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILAlertBarView.h"
#import "UIColor+SILColors.h"

const CGFloat kActivePriority = 999;
const CGFloat kMainPriority = 998;
const CGFloat kInactivePriority = 1;

@interface SILAlertBarView()

@property (weak, nonatomic) UILabel *alertMessageLabel;
@property (weak, nonatomic) NSLayoutConstraint *alertBarHideConstraint;
@property (weak, nonatomic) NSLayoutConstraint *alertBarRevealConstraint;

@end

@implementation SILAlertBarView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor sil_siliconLabsRedColor];
}

- (void)configureLabel:(UILabel *)label revealConstraint:(NSLayoutConstraint *)revealConstraint hideConstraint:(NSLayoutConstraint *)hideConstraint {
    self.alertMessageLabel = label;
    self.alertBarRevealConstraint = revealConstraint;
    self.alertBarHideConstraint = hideConstraint;
    
    self.alertBarHideConstraint.priority = kMainPriority;
    self.alertBarRevealConstraint.priority = kInactivePriority;
}

- (void)revealAlertBarWithMessage:(NSString *)message revealTime:(CGFloat)revealTime displayTime:(CGFloat)displayTime {
    self.alertMessageLabel.text = message;
    [self layoutIfNeeded];
    __weak SILAlertBarView *weakSelf = self;
    if (!self.isAnimating) {
        self.isAnimating = YES;
        [UIView animateWithDuration:revealTime animations:^{
            weakSelf.alertBarRevealConstraint.priority = kActivePriority;
            [weakSelf layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (displayTime > 0) {
                [weakSelf hideBarAnimation:weakSelf duration:revealTime delay:displayTime];
            } else {
                weakSelf.isAnimating = NO;
            }
        }];
    }
}

- (void)hideBarIfRevealed:(CGFloat)hideTime {
    [self.layer removeAllAnimations];
    [self layoutIfNeeded];
    [self hideBarAnimation:self duration:hideTime delay:0];
}

- (void)hideBarAnimation:(SILAlertBarView *)alertBarView duration:(CGFloat)duration delay:(CGFloat)delayTime {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            alertBarView.alertBarRevealConstraint.priority = kInactivePriority;
            [alertBarView layoutIfNeeded];
        } completion:^(BOOL finished){
            alertBarView.isAnimating = NO;
        }];
    });
}

@end
